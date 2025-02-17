trigger CampaignTrigger on Campaign (after insert, after update) {
    
    List<Campaign_Member_Status_Default__mdt> cmStatusDefaults = [SELECT Id, Campaign_Record_Type__c, Campaign_Member_Status__c,
                                                                  Default__c, Has_Responded__c
                                                                  FROM Campaign_Member_Status_Default__mdt
                                                                  ORDER BY Campaign_Record_Type__c];
    Map<String, List<Campaign_Member_Status_Default__mdt>> mapRecordTypeToCMStatusDefaults = new Map<String, List<Campaign_Member_Status_Default__mdt>>();
    for (Campaign_Member_Status_Default__mdt cmStatusDefault : cmStatusDefaults) {
        Id recordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get(cmStatusDefault.Campaign_Record_Type__c).getRecordTypeId();
        if (!mapRecordTypeToCMStatusDefaults.containsKey(recordTypeId)) {
            mapRecordTypeToCMStatusDefaults.put(recordTypeId, new List<Campaign_Member_Status_Default__mdt>{cmStatusDefault});
        }
        else {mapRecordTypeToCMStatusDefaults.get(recordTypeId).add(cmStatusDefault);}
    }
    
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            List<CampaignMemberStatus> statusesToInsert = new List<CampaignMemberStatus>();
            for (Campaign c : Trigger.new) {
                if (mapRecordTypeToCMStatusDefaults.containsKey(c.RecordTypeId)) {
                    for (Campaign_Member_Status_Default__mdt cmStatusDefault : mapRecordTypeToCMStatusDefaults.get(c.RecordTypeId)) {
                        CampaignMemberStatus cmStatus = new CampaignMemberStatus(
                        CampaignId = c.Id,
                        Label = cmStatusDefault.Campaign_Member_Status__c,
                        HasResponded = cmStatusDefault.Has_Responded__c,
                        IsDefault = cmStatusDefault.Default__c); 
                        statusesToInsert.add(cmStatus);
                    }
                }
            }
            Database.insert(statusesToInsert, false);
        }
        if (Trigger.isUpdate) {
            Set<Id> campaignIds = new Set<Id>();
            for (Campaign c : Trigger.oldMap.values()) {
                if (c.RecordTypeId == Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Event').getRecordTypeId() && Trigger.oldMap.get(c.Id).Lead_Sub_Source__c != Trigger.newMap.get(c.Id).Lead_Sub_Source__c) {
                    System.debug('The lead sub-source on this campaign has changed');
                    campaignIds.add(c.Id);
                }
            }
            if (!campaignIds.isEmpty()) {
                List<CampaignMember> leadCampMembers = [SELECT LeadId, CampaignId FROM CampaignMember WHERE LeadId != null AND CampaignId IN :campaignIds];
                System.debug('Number of campaign members who are leads: ' + leadCampMembers.size());
                Set<Id> leadIds = new Set<Id>();
                for (CampaignMember cm : leadCampMembers) {
                    leadIds.add(cm.LeadId);
                }
                List<CampaignMember> allCampaignMemberships = [SELECT LeadId, Lead.LeadSource, Lead.Lead_Sub_Source__c, CampaignId, 
                                                               Campaign.Type, Campaign.Lead_Sub_Source__c,
                                                               Campaign.StartDate 
                                                               FROM CampaignMember
                                                               WHERE LeadId IN :leadIds
                                                               ORDER BY Campaign.StartDate];
                Map<Id, CampaignMember> mapAllCampMemberships = new Map<Id, CampaignMember>();
                for (CampaignMember cm : allCampaignMemberships) {
                    if (!mapAllCampMemberships.keySet().contains(cm.LeadId)) {
                        if ((String.isBlank(cm.Lead.LeadSource) || String.isBlank(cm.Lead.Lead_Sub_Source__c) || cm.Lead.LeadSource.contains('Event')) && ((!String.isBlank(cm.Campaign.Type) && cm.Campaign.Type.contains('Event')) || !String.isBlank(cm.Campaign.Lead_Sub_Source__c))) {
                            mapAllCampMemberships.put(cm.LeadId, cm);
                        }
                    }
                }
                List<Lead> leads = [SELECT Id, Name, LeadSource, Lead_Sub_Source__c
                                    FROM Lead
                                    WHERE Id IN :leadIds];
                List<Lead> leadsToUpdate = new List<Lead>();
                for (Lead l : leads) {
                    if (mapAllCampMemberships.keySet().contains(l.Id)) {
                        l.LeadSource = mapAllCampMemberships.get(l.Id).Campaign.Type;
                        System.debug('Lead source for this lead, based on event type of first campaign of which lead was a member: ' + mapAllCampMemberships.get(l.Id).Campaign.Type);
                        l.Lead_Sub_Source__c = mapAllCampMemberships.get(l.Id).Campaign.Lead_Sub_Source__c;
                        System.debug('Lead sub-source for this lead, based on lead sub-source associated with first campaign of which lead was a member: ' + mapAllCampMemberships.get(l.Id).Campaign.Lead_Sub_Source__c);
                        leadsToUpdate.add(l);            
                    }
                }
                if (!leadsToUpdate.isEmpty()) {Database.update(leadsToUpdate, false);}
            }
        }
    }
}