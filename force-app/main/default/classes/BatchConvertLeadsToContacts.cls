public class BatchConvertLeadsToContacts implements Database.Batchable<DuplicateRecordSet> {
	
	public List<DuplicateRecordSet> dupeRecSets = new List<DuplicateRecordSet>();
	
	public BatchConvertLeadsToContacts(List<DuplicateRecordSet> dupeRecSets) {
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
		List<Id> dupeContactIds = new List<Id>();
		// Use getDescribe() method to identify sObject type of each duplicate
		// record item, which may be a contact or a lead
		for (DuplicateRecordItem dri : dupeRecItems) {
			if (dri.RecordId.getSObjectType().getDescribe().getName()=='Contact') {
				System.debug('Duplicate record item is a contact');
				dupeContactIds.add(dri.RecordId);
			}
			else if (dri.RecordId.getSObjectType().getDescribe().getName()=='Lead') {
				System.debug('Duplicate record item is a lead');
				dupeLeadIds.add(dri.RecordId);
			}
		}
		// Get the duplicate contact record whose insertion or update triggered the creation of
		// the duplicate record set
		List<Contact> dupeContacts = [SELECT Id, AccountId, FirstName, LastName, Description, Description_Last_Updated__c, 
                                      Hobbies__c, Dietary_Restrictions__c, Email, npe01__HomeEmail__c,
									  npe01__WorkEmail__c, npe01__AlternateEmail__c, npe01__Preferred_Email__c, 
                                      MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
									  Email_Opted_In__c, GDPR_Consent_Date__c, HasOptedOutOfEmail, GDPR_Decline_Date__c,
                                      Do_Not_Solicit__c, Newsletter__c, Book_Club__c, She_Creates_Change__c, Forms_Filled_Out__c, 
                                      SMS_Opt_In__c, SMS_Consent_Date__c, SMS_Decline_Date__c, Volunteer__c, CreatedDate
									  FROM Contact
									  WHERE Id IN :dupeContactIds
									  AND isDeleted=false
									  ORDER BY CreatedDate];
		System.debug('Number of duplicate contacts: ' + dupeContacts.size());
		// Get the duplicate lead records in the set (there should be at least one,
		// based on the duplicate rules that are in effect)
		List<Lead> dupeLeads = [SELECT Id, FirstName, LastName, Description, Description_Last_Updated__c,
                                Hobbies__c, Dietary_Restrictions__c, Street, City, State, PostalCode,
                                Country, Email, Forms_Filled_Out__c, 
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
        String street;
        String city;
        String state;
        String postalCode;
        String country;
        String description = '';
        String hobbies = '';
        String dietaryRestrictions = '';
        // Loop over all leads returned in queries in order to identify latest GDPR consent date
        // and to collate all web-to-lead forms filled out by the individual with this email address
        for (Lead lead : dupeLeads) {
            if (!String.isBlank(lead.Forms_Filled_Out__c)) {
                List<String> formList = lead.Forms_Filled_Out__c.split(';');
                uniqueForms.addAll(formList);
            }
			if (lead.GDPR_Consent_Date__c!=null && lead.GDPR_Consent_Date__c>maxGDPRConsentDate) {
				maxGDPRConsentDate = lead.GDPR_Consent_Date__c;
                optedInToEmail = true;
			}
            if (lead.Email_Opted_In__c == true) {
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
        // Do the same thing for the contact that triggered creation of the duplicate record set
        for (Contact con : dupeContacts) {
            if (con.Forms_Filled_Out__c!=null) {
                List<String> formList = con.Forms_Filled_Out__c.split(';');
                uniqueForms.addAll(formList);
            }
            if (con.GDPR_Consent_Date__c!=null && con.GDPR_Consent_Date__c>maxGDPRConsentDate) {
                maxGDPRConsentDate = con.GDPR_Consent_Date__c;
                optedInToEmail = true;
            }            
            if (con.Email_Opted_In__c == true) {
                optedInToEmail = true;
            }
            if (con.Do_Not_Solicit__c == true) {
                doNotSolicit = true;
            }
            if (con.Newsletter__c == true) {
                signedUpForNewsletter = true;
            }
            if (con.Book_Club__c == true) {
                signedUpForBookClub = true;
            }
            if (con.She_Creates_Change__c == true) {
                signedUpForSheCreatesChange = true;
            }
            if (con.SMS_Opt_In__c == true) {
                signedUpForSMS = true;
            }
            if (con.SMS_Consent_Date__c!=null && con.SMS_Consent_Date__c>maxSMSConsentDate) {
                maxSMSConsentDate = con.SMS_Consent_Date__c;
            }
            if (con.SMS_Decline_Date__c!=null && con.SMS_Decline_Date__c>maxSMSDeclineDate) {
                maxSMSDeclineDate = con.SMS_Decline_Date__c;
            } 
            if (con.Volunteer__c == true) {
                volunteer = true;
            }
            if (con.Description_Last_Updated__c!=null && con.Description_Last_Updated__c>maxDescriptionLastUpdated) {
                maxDescriptionLastUpdated = con.Description_Last_Updated__c;
                description = con.Description;
            }
            else if (con.Description_Last_Updated__c==null && maxDescriptionLastUpdated==Date.newInstance(1900, 1, 1) && !String.isBlank(con.Description)) {
                description = con.Description; 
            }
            if (!String.isBlank(con.Hobbies__c)) {hobbies = con.Hobbies__c;}
            if (!String.isBlank(con.Dietary_Restrictions__c)) {dietaryRestrictions = con.Dietary_Restrictions__c;}            
        }
        // Collate all forms filled out; listify in order to assign colon-separated string value
        // to multi-select picklist field
        List<String> allFormsFilledOut = new List<String>();
        allFormsFilledOut.addAll(uniqueForms);
        String formsMultiSelectString = String.join(allFormsFilledOut, ';');
        System.debug('All forms: ' + formsMultiSelectString);
		if (maxGDPRConsentDate > Date.newInstance(1900, 1, 1) || optedInToEmail) {
            dupeContacts[0].GDPR_Consent_Date__c = maxGDPRConsentDate > Date.newInstance(1900, 1, 1) ? maxGDPRConsentDate : null;
            dupeContacts[0].Email_Opted_In__c = true;
            dupeContacts[0].HasOptedOutOfEmail = false;
            dupeContacts[0].GDPR_Decline_Date__c = null;
        }
        if (formsMultiSelectString!='') {
            dupeContacts[0].Forms_Filled_Out__c = formsMultiSelectString;
        }
        dupeContacts[0].Do_Not_Solicit__c = doNotSolicit;
        dupeContacts[0].Newsletter__c = signedUpForNewsletter;
        dupeContacts[0].Book_Club__c = signedUpForBookClub;
        dupeContacts[0].She_Creates_Change__c = signedUpForSheCreatesChange;
        if (maxSMSConsentDate > maxSMSDeclineDate) {
            dupeContacts[0].SMS_Opt_In__c = true;
            dupeContacts[0].SMS_Consent_Date__c = maxSMSConsentDate;
            dupeContacts[0].SMS_Decline_Date__c = null;
        }
        else if (maxSMSDeclineDate>maxSMSConsentDate) {
            dupeContacts[0].SMS_Opt_In__c = false;
            dupeContacts[0].SMS_Consent_Date__c = maxSMSConsentDate > Date.newInstance(1900, 1, 1) ? maxSMSConsentDate : null;
            dupeContacts[0].SMS_Decline_Date__c = maxSMSDeclineDate;
        } 
        else {dupeContacts[0].SMS_Opt_In__c = signedUpForSMS;} 
        dupeContacts[0].Volunteer__c = volunteer;
        if (!String.isBlank(street) && !String.isBlank(country) && String.isBlank(dupeContacts[0].MailingStreet)) {
			dupeContacts[0].MailingStreet = street;
            dupeContacts[0].MailingCity = city;
            dupeContacts[0].MailingState = state;
            dupeContacts[0].MailingPostalCode = postalCode;
            dupeContacts[0].MailingCountry = country;
        }
        dupeContacts[0].Description_Last_Updated__c = maxDescriptionLastUpdated > Date.newInstance(1900, 1, 1) ? maxDescriptionLastUpdated : null;
        dupeContacts[0].Description = description;
        dupeContacts[0].Hobbies__c = hobbies;
        dupeContacts[0].Dietary_Restrictions__c = dietaryRestrictions;
		update dupeContacts[0];

        // Check to see which was created first: the lead record or the contact record. If
        // the lead record was created first, and the insertion of a matching contact record upon receipt of the 
        // individual's first gift to RtR triggered the creation of this duplicate record set,
        // then we will convert/merge the lead to the new contact record.
        System.debug('Lead should be converted to contact?: ' + String.valueOf(dupeContacts[0].CreatedDate>dupeLeads[0].CreatedDate));
        if (dupeContacts[0].CreatedDate>dupeLeads[0].CreatedDate) {
            LeadStatus convertStatus = [SELECT Id, MasterLabel
										FROM LeadStatus WHERE IsConverted=true LIMIT 1];
			Database.LeadConvert lc = new database.LeadConvert();
			lc.setLeadId(dupeLeads[0].Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
			lc.setAccountId(dupeContacts[0].AccountId);
			lc.setContactId(dupeContacts[0].Id);
			lc.setDoNotCreateOpportunity(true);
			Database.LeadConvertResult result = Database.convertLead(lc, false);
			System.debug('Conversion of lead to existing contact/account was a success?: ' + result.isSuccess());
        }
        else {
            // If contact was created *before* the first lead record for this individual,
            // simply delete duplicate leads (relevant details have already been transcribed
            // onto the original contact record)
            Database.delete(dupeLeads, false);
		}
	}

	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job: ' + job.Status);
	}
	
}