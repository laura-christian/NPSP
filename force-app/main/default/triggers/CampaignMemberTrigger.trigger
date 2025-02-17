trigger CampaignMemberTrigger on CampaignMember (after insert) {
    
	Set<Id> leadIds = new Set<Id>();
    Set<Id> campaignIds = new Set<Id>();
    // Gather IDs of all campaign members who are leads and the campaigns in which they
    // are participating
    for (CampaignMember cm : Trigger.new) {
        if (!String.isBlank(cm.LeadId)) {
            leadIds.add(cm.LeadId);
            campaignIds.add(cm.CampaignId);
        }
    }
    // Generate maps of campaigns with a record type of Event and of leads missing
    // source/sub-source 
    Map<Id, Campaign> eventCampaignsMap = new Map<Id, Campaign>([SELECT Id, Name, Type, Lead_Sub_Source__c FROM Campaign WHERE RecordType.Name = 'Event' AND Id IN :campaignIds AND Type != null AND Lead_Sub_Source__c != null ORDER BY CreatedDate]);
    Map<Id, Lead> leadsMap = new Map<Id, Lead>([SELECT Id, LeadSource, Lead_Sub_Source__c FROM Lead WHERE Id IN :leadIds AND (LeadSource = null OR Lead_Sub_Source__c = null)]);
    
    List<Lead> leadsToUpdate = new List<Lead>();
    // Track leads that have already been assigned a lead source and sub-source, in case they've been added to multiple campaigns
    // in the same insert operation (to avoid adding duplicates to list of leads to be updated)
    Set<Id> leadsAlreadyAddedForUpdate = new Set<Id>();
    for (CampaignMember cm : Trigger.new) {
        if (!String.isBlank(cm.LeadId) && !leadsAlreadyAddedForUpdate.contains(cm.LeadId) && eventCampaignsMap.containsKey(cm.CampaignId) && leadsMap.containsKey(cm.LeadId)) {
            leadsAlreadyAddedForUpdate.add(cm.LeadId);
            Lead l = leadsMap.get(cm.LeadId);
            l.LeadSource = eventCampaignsMap.get(cm.CampaignId).Type;
            l.Lead_Sub_Source__c = eventCampaignsMap.get(cm.CampaignId).Lead_Sub_Source__c;
            leadsToUpdate.add(l);
        }
    }
    if (!leadsToUpdate.isEmpty()) {
        Database.update(leadsToUpdate, false);
    }

}