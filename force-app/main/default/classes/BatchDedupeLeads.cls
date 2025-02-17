public class BatchDedupeLeads implements Database.Batchable<DuplicateRecordSet>, Database.Stateful {
	
	public List<DuplicateRecordSet> dupeRecSets = new List<DuplicateRecordSet>();
	
	public BatchDedupeLeads(List<DuplicateRecordSet> dupeRecSets) {
		this.dupeRecSets = dupeRecSets;
	}
	
	public List<DuplicateRecordSet> start(Database.BatchableContext BC) {
		System.debug('Initiating batch dedupe of leads');
		return dupeRecSets;
	}
	
	public void execute(Database.BatchableContext BC, List<DuplicateRecordSet> scopeDRS) {
		// Only one duplicate record set will be processed at a time; so
		// select first record in scope and perform work on it
		DuplicateRecordSet drs = scopeDRS[0];
		// Get all duplicate record items in the set
		List<DuplicateRecordItem> dupeRecItems = [SELECT Id, Name, RecordId
												  FROM DuplicateRecordItem
												  WHERE DuplicateRecordSetId=:drs.Id];
		Set<Id> dupeLeadIds = new Set<Id>();
		for (DuplicateRecordItem dri : dupeRecItems) {
			dupeLeadIds.add(dri.RecordId);
		}
		// Get all duplicate lead records in the set (there should be at least one,
		// based on the duplicate rules that are in effect)
		List<Lead> dupeLeads = [SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, Description, Description_Last_Updated__c,
                                Hobbies__c, Dietary_Restrictions__c,
                                Street, City, State, PostalCode, Country, Forms_Filled_Out__c, 
								Email_Opted_In__c, GDPR_Consent_Date__c, HasOptedOutOfEmail, GDPR_Decline_Date__c,
                                Do_Not_Solicit__c, Newsletter__c, Book_Club__c, She_Creates_Change__c, 
                                SMS_Opt_In__c, SMS_Consent_Date__c, SMS_Decline_Date__c, Volunteer__c, CreatedDate
								FROM Lead
								WHERE Id IN :dupeLeadIds
								AND isDeleted=false AND isConverted=false
								ORDER BY CreatedDate];
		System.debug('Number of duplicate leads: ' + dupeLeads.size());
		Set<String> uniqueForms = new Set<String>();
		Date maxGDPRConsentDate = Date.newInstance(1900, 1, 1);
        Date maxDescriptionLastUpdated = Date.newInstance(1900, 1, 1);
        Boolean optedInToEmail = false;
        Boolean doNotSolicit = false;
        Boolean signedUpForNewsletter = false;
        Boolean signedUpForBookClub = false;
        Boolean signedUpForSheCreatesChange = false;
        Boolean signedUpForSMS = false;
        Date maxSMSConsentDate = Date.newInstance(1900, 1, 1);
        Date maxSMSDeclineDate = Date.newInstance(1900, 1, 1);
        Boolean volunteer = false;        
        String firstName;
        String lastName;        
        String street;
        String city;
        String state;
        String postalCode;
        String country;
        String mobilePhone;
        String description = '';
        String hobbies = '';
        String dietaryRestrictions = '';
		// Loop over all leads returned in query to identify latest GDPR consent/decline dates
		// and to collate all web-to-lead forms filled out by the individual(s) with this email address
		for (Lead lead : dupeLeads) {
			if (!String.isBlank(lead.Forms_Filled_Out__c)) {
				List<String> formList = lead.Forms_Filled_Out__c.split(';');
				uniqueForms.addAll(formList);
			}
			if (lead.GDPR_Consent_Date__c!=null && lead.GDPR_Consent_Date__c>maxGDPRConsentDate) {
				maxGDPRConsentDate = lead.GDPR_Consent_Date__c;
                optedInToEmail = true;
			}
            else if (lead.Email_Opted_In__c == true) {
                optedInToEmail = true;
            }
            if (lead.Do_Not_Solicit__c == true) {
                doNotSolicit = true;
            }
            if (lead.Newsletter__c == true) {
                signedUpForNewsletter = true;
            }
            if (lead.Book_Club__c == true) {
                signedUpForBookClub = true;
            }
            if (lead.She_Creates_Change__c == true) {
                signedUpForSheCreatesChange = true;
            }
            if (!String.isBlank(lead.MobilePhone)) {
                mobilePhone = lead.MobilePhone;
            }
            if (lead.SMS_Opt_In__c == true) {
                signedUpForSMS = true;
            }
            if (lead.SMS_Consent_Date__c!=null && lead.SMS_Consent_Date__c > maxSMSConsentDate) {
                maxSMSConsentDate = lead.SMS_Consent_Date__c;
            }
            if (lead.SMS_Decline_Date__c!=null && lead.SMS_Decline_Date__c > maxSMSDeclineDate) {
                maxSMSDeclineDate = lead.SMS_Decline_Date__c;
            }  
            if (lead.Volunteer__c == true) {
                volunteer = true;
            }            
            if (!String.isBlank(lead.Street)) {
                street = lead.Street;
            }
            if (!String.isBlank(lead.City)) {
                city = lead.City;
            }
            if (!String.isBlank(lead.State)) {
                state = lead.State;
            }
            if (!String.isBlank(lead.PostalCode)) {
                postalCode = lead.PostalCode;
            }
            if (!String.isBlank(lead.Country)) {
                country = lead.Country;
            }
            if (lead.Description_Last_Updated__c!=null && lead.Description_Last_Updated__c>maxDescriptionLastUpdated) {
                maxDescriptionLastUpdated = lead.Description_Last_Updated__c;
                description = lead.Description;
            }
            else if (lead.Description_Last_Updated__c==null && maxDescriptionLastUpdated==Date.newInstance(1900, 1, 1) && !String.isBlank(lead.Description)) {
                description = lead.Description;
            }
            if (!String.isBlank(lead.Hobbies__c)) {hobbies = lead.Hobbies__c;}
            if (!String.isBlank(lead.Dietary_Restrictions__c)) {dietaryRestrictions = lead.Dietary_Restrictions__c;}			            
		}
        firstName = dupeLeads[dupeLeads.size()-1].FirstName;
        lastName = dupeLeads[dupeLeads.size()-1].LastName;
        
        // Collate all forms filled out; listify in order to assign colon-separated string value
        // to multi-select picklist field
		List<String> allFormsFilledOut = new List<String>();
		allFormsFilledOut.addAll(uniqueForms);
        String formsMultiSelectString = String.join(allFormsFilledOut, ';');
        System.debug('All forms: ' + formsMultiSelectString);
        List<CampaignMember> campaignMemberships = [SELECT Id, LeadId, CampaignId
                                                    FROM CampaignMember
                                                    WHERE LeadId IN :dupeLeadIds];
        List<CampaignMember> campaignMembershipsToDelete = new List<CampaignMember>();
        List<CampaignMember> campaignMembershipsToInsert = new List<CampaignMember>();        
		// Update the original lead with a refreshed GDPR consent date and list of
		// forms filled out, as well as any other details collated from duplicate leads.
		dupeLeads[0].FirstName = firstName;
        dupeLeads[0].LastName = lastName;
        if (maxGDPRConsentDate > Date.newInstance(1900, 1, 1) || optedInToEmail == true) {
            dupeLeads[0].GDPR_Consent_Date__c = maxGDPRConsentDate > Date.newInstance(1900, 1, 1) ? maxGDPRConsentDate : null;
            dupeLeads[0].Email_Opted_In__c = true;
            dupeLeads[0].HasOptedOutOfEmail = false;
            dupeLeads[0].GDPR_Decline_Date__c = null;
        }
        if (!String.isBlank(formsMultiSelectString)) {
            dupeLeads[0].Forms_Filled_Out__c = formsMultiSelectString;
        }
        if (!String.isBlank(country)) {
            dupeLeads[0].Street = street;
            dupeLeads[0].City = city;
            dupeLeads[0].State = state;
            dupeLeads[0].PostalCode = postalCode;
            dupeLeads[0].Country = country;
        }
        dupeLeads[0].Do_Not_Solicit__c = doNotSolicit;
        dupeLeads[0].Newsletter__c = signedUpForNewsletter;
        dupeLeads[0].Book_Club__c = signedUpForBookClub;
        dupeLeads[0].She_Creates_Change__c = signedUpForSheCreatesChange;
        if (maxSMSConsentDate > maxSMSDeclineDate) {
            dupeLeads[0].SMS_Opt_In__c = true;
            dupeLeads[0].SMS_Consent_Date__c = maxSMSConsentDate;
            dupeLeads[0].SMS_Decline_Date__c = null;
        }
        else if (maxSMSDeclineDate>maxSMSConsentDate) {
            dupeLeads[0].SMS_Opt_In__c = false;
            dupeLeads[0].SMS_Consent_Date__c = maxSMSConsentDate > Date.newInstance(1900, 1, 1) ? maxSMSConsentDate : null;
            dupeLeads[0].SMS_Decline_Date__c = maxSMSDeclineDate;
        }
        else {dupeLeads[0].SMS_Opt_In__c = signedUpForSMS;}
        dupeLeads[0].Volunteer__c = volunteer;
        dupeLeads[0].MobilePhone = mobilePhone;
        dupeLeads[0].Description = description;
        dupeLeads[0].Description_Last_Updated__c = maxDescriptionLastUpdated > Date.newInstance(1900, 1, 1) ? maxDescriptionLastUpdated : null;
        dupeLeads[0].Hobbies__c = hobbies;
        dupeLeads[0].Dietary_Restrictions__c = dietaryRestrictions;
        if (!campaignMemberships.isEmpty()) {
            for (CampaignMember cm : campaignMemberships) {
                if (cm.LeadId != dupeLeads[0].Id) {
                    campaignMembershipsToDelete.add(cm);
                    CampaignMember newCM = new CampaignMember(
                        CampaignId = cm.CampaignId,
                        LeadId = dupeLeads[0].Id,
                        Status = 'Responded');
                    campaignMembershipsToInsert.add(newCM);
                }
            }
            if (!campaignMembershipsToDelete.isEmpty()) {Database.delete(campaignMembershipsToDelete, false);}
            if (!campaignMembershipsToInsert.isEmpty()) {Database.insert(campaignMembershipsToInsert, false);}				
        }
        Database.saveResult saveResult = Database.update(dupeLeads[0], false);
        if (saveResult.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully updated lead record. Lead Id: ' + saveResult.getId());
        }
        else {
            System.debug('The following error has occurred:');                    
            Database.Error error = saveResult.getErrors().get(0);
            System.debug(error.getMessage());
            System.debug('Id of record that failed to update: ' + dupeLeads[0].Id);
        }
        // Now delete all duplicate leads in the record set
        List<Lead> dupeLeadsToDelete = new List<Lead>();
        for (Integer i=1; i<dupeLeads.size(); i++) {
            dupeLeadsToDelete.add(dupeLeads[i]);
        }
        Database.delete(dupeLeadsToDelete, false);
	}

	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job: ' + job.Status);
	}
	
}