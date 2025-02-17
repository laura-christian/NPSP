public class ConvertLeadController {

    @AuraEnabled
    public static Id convertLead(String leadId, String contactId, String householdId, String affiliateOrgId, String affiliationType, Boolean primaryAffiliation) {
        System.debug(leadId + '<----->' + contactId + '<----->' + householdId + '<----->' + affiliateOrgId + '<----->' + affiliationType);
        Id convertedLeadContactId;
        LeadStatus convertStatus = [SELECT Id, MasterLabel
                                    FROM LeadStatus WHERE IsConverted=true LIMIT 1];        
        if (String.isBlank(contactId)) {
        	Lead l = [SELECT Id, FirstName, LastName, Japanese_Expat__c, Japanese_Local__c, Email, Description, Description_Last_Updated__c, Hobbies__c,
                     Dietary_Restrictions__c, Street, City, State, PostalCode, Country, 
                     Newsletter__c, Book_Club__c, She_Creates_Change__c, Email_Opted_In__c, GDPR_Consent_Date__c, 
                     HasOptedOutOfEmail, GDPR_Decline_Date__c, Do_Not_Solicit__c, Forms_Filled_Out__c,
                     LeadSource, Lead_Sub_Source__c, Validated_Email__c, Rejected_Email__c, Email_ZeroBounce_Status__c,
                     Email_ZeroBounce_Substatus__c, SMS_Opt_In__c, SMS_Consent_Date__c, SMS_Decline_Date__c, Volunteer__c
                     FROM Lead WHERE Id = :leadId LIMIT 1];            
            if (String.isBlank(householdId)) {
                Account a = new Account(
                Name = 'Household',
                Type = 'Household',
                RecordTypeId = '0128b000000XLomAAG');
                insert a;
                householdId = a.Id;
            }
            Contact c = new Contact(
            AccountId = householdId,
            FirstName = l.FirstName,
            LastName = l.LastName,
            Japanese_Local__c = l.Japanese_Local__c,
            Japanese_Expat__c = l.Japanese_Expat__c,
            Email = l.Email,
            Description = l.Description,
            Description_Last_Updated__c = l.Description_Last_Updated__c,
            Hobbies__c = l.Hobbies__c,
            Dietary_Restrictions__c = l.Dietary_Restrictions__c,
            MailingStreet = l.Street,
            MailingCity = l.City,
            MailingState = l.State,
            MailingPostalCode = l.PostalCode,
            MailingCountry = l.Country,
            Newsletter__c = l.Newsletter__c,
            Book_Club__c = l.Book_Club__c,
            She_Creates_Change__c = l.She_Creates_Change__c, 
            Email_Opted_In__c = l.Email_Opted_In__c, 
            GDPR_Consent_Date__c = l.GDPR_Consent_Date__c,
			HasOptedOutOfEmail = l.HasOptedOutOfEmail,
            GDPR_Decline_Date__c = l.GDPR_Decline_Date__c,
            Do_Not_Solicit__c = l.Do_Not_Solicit__c, 
            Forms_Filled_Out__c = l.Forms_Filled_Out__c,
			Validated_Email__c = l.Validated_Email__c,
            Rejected_Email__c = l.Rejected_Email__c, 
            Email_ZeroBounce_Status__c = l.Email_ZeroBounce_Status__c,
			Email_ZeroBounce_Substatus__c = l.Email_ZeroBounce_Substatus__c,
			SMS_Opt_In__c = l.SMS_Opt_In__c,
            SMS_Consent_Date__c = l.SMS_Consent_Date__c, 
            SMS_Decline_Date__c = l.SMS_Decline_Date__c,
            Volunteer__c = l.Volunteer__c);
            insert c;
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(leadId);
            lc.setContactId(c.Id);
            System.debug(householdId);
            lc.setAccountId(householdId);
			lc.setConvertedStatus(convertStatus.MasterLabel);
			lc.setDoNotCreateOpportunity(true);
			Database.LeadConvertResult result = Database.convertLead(lc, false);
         	if (result.isSuccess()) {
            	System.debug('Lead converted successfully');
            	System.debug('Account Id: ' + result.getAccountId());
            	System.debug('Contact ID: ' + result.getContactId());
                convertedLeadContactId = result.getContactId();
         	} 
           	else {
            	System.debug('Error converting new Lead: ' + result.getErrors()[0].getMessage());
         	}            
        }
        else if (!String.isBlank(contactId)) {
        	Lead l = [SELECT Id, FirstName, LastName, Email, Description, Description_Last_Updated__c, Hobbies__c,
                     Dietary_Restrictions__c, Street, City, State, PostalCode, Country, 
                     Newsletter__c, Book_Club__c, She_Creates_Change__c, Email_Opted_In__c, GDPR_Consent_Date__c, 
                     HasOptedOutOfEmail, GDPR_Decline_Date__c, Do_Not_Solicit__c, Forms_Filled_Out__c,
                     LeadSource, Lead_Sub_Source__c, Validated_Email__c, Rejected_Email__c, Email_ZeroBounce_Status__c,
                     Email_ZeroBounce_Substatus__c, SMS_Opt_In__c, SMS_Consent_Date__c, SMS_Decline_Date__c, Volunteer__c
                     FROM Lead WHERE Id = :leadId LIMIT 1]; 
            Contact c = [SELECT Id, AccountId, FirstName, LastName, Description, Description_Last_Updated__c, Hobbies__c,
                         Dietary_Restrictions__c, Email, npe01__HomeEmail__c,
						 npe01__WorkEmail__c, npe01__AlternateEmail__c, npe01__Preferred_Email__c, 
                         MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
						 Email_Opted_In__c, GDPR_Consent_Date__c, HasOptedOutOfEmail, GDPR_Decline_Date__c,
                         Do_Not_Solicit__c, Newsletter__c, Book_Club__c, She_Creates_Change__c, Forms_Filled_Out__c,
                         SMS_Opt_In__c, SMS_Consent_Date__c, SMS_Decline_Date__c, Volunteer__c
					     FROM Contact
						 WHERE Id = :contactId LIMIT 1];           
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
            if (!String.isBlank(l.Forms_Filled_Out__c)) {
                List<String> formList = l.Forms_Filled_Out__c.split(';');
                uniqueForms.addAll(formList);
            }
			if (l.GDPR_Consent_Date__c!=null && l.GDPR_Consent_Date__c>maxGDPRConsentDate) {
				maxGDPRConsentDate = l.GDPR_Consent_Date__c;
                optedInToEmail = true;
			}
            if (l.Email_Opted_In__c == true) {optedInToEmail = true;}
            if (l.Do_Not_Solicit__c == true) {doNotSolicit = true;}
            if (l.Newsletter__c == true) {signedUpForNewsletter = true;}
            if (l.Book_Club__c == true) {signedUpForBookClub = true;}
            if (l.She_Creates_Change__c == true) {signedUpForSheCreatesChange = true;}
            if (l.SMS_Opt_In__c == true) {signedUpForSMS = true;}
            if (l.SMS_Consent_Date__c!=null && l.SMS_Consent_Date__c > maxSMSConsentDate) {
                maxSMSConsentDate = l.SMS_Consent_Date__c;
            }
            if (l.SMS_Decline_Date__c!=null && l.SMS_Decline_Date__c > maxSMSDeclineDate) {
                maxSMSDeclineDate = l.SMS_Decline_Date__c;
            }
            if (l.Volunteer__c == true) {volunteer = true;}
            if (!String.isBlank(l.Street)) {
                street = l.Street;
            }
            if (!String.isBlank(l.City)) {
                city = l.City;
            }
            if (!String.isBlank(l.State)) {
                state = l.State;
            }
            if (!String.isBlank(l.PostalCode)) {
                postalCode = l.PostalCode;
            }
            if (!String.isBlank(l.Country)) {
                country = l.Country;
            }
            if (l.Description_Last_Updated__c!=null && l.Description_Last_Updated__c>maxDescriptionLastUpdated) {
                maxDescriptionLastUpdated = l.Description_Last_Updated__c;
                description = l.Description;
            }
            else if (l.Description_Last_Updated__c==null && maxDescriptionLastUpdated==Date.newInstance(1900, 1, 1) && !String.isBlank(l.Description)) {
                description = l.Description;
            }
            if (!String.isBlank(l.Hobbies__c)) {hobbies = l.Hobbies__c;}
            if (!String.isBlank(l.Dietary_Restrictions__c)) {dietaryRestrictions = l.Dietary_Restrictions__c;}
            if (c.Forms_Filled_Out__c!=null) {
                List<String> formList = c.Forms_Filled_Out__c.split(';');
                uniqueForms.addAll(formList);
            }      
            if (c.Email_Opted_In__c == true) {
                optedInToEmail = true;
            }
            if (c.GDPR_Consent_Date__c!=null && c.GDPR_Consent_Date__c>maxGDPRConsentDate) {
                maxGDPRConsentDate = c.GDPR_Consent_Date__c;
                optedInToEmail = true;
            }            
            if (c.Do_Not_Solicit__c == true) {doNotSolicit = true;}
            if (c.Newsletter__c == true) {
                signedUpForNewsletter = true;
            }
            if (c.Book_Club__c == true) {signedUpForBookClub = true;}
            if (c.She_Creates_Change__c == true) {signedUpForSheCreatesChange = true;}
            if (c.SMS_Opt_In__c == true) {signedUpForSMS = true;}
            if (c.SMS_Consent_Date__c!=null && c.SMS_Consent_Date__c>maxSMSConsentDate) {maxSMSConsentDate = c.SMS_Consent_Date__c;}
            if (c.SMS_Decline_Date__c!=null && c.SMS_Decline_Date__c>maxSMSDeclineDate) {maxSMSDeclineDate = c.SMS_Decline_Date__c;}
            if (c.Volunteer__c == true) {
                volunteer = true;
            }
            if (c.Description_Last_Updated__c!=null && c.Description_Last_Updated__c>maxDescriptionLastUpdated) {
                maxDescriptionLastUpdated = c.Description_Last_Updated__c;
                description = c.Description;
            }
            else if (c.Description_Last_Updated__c==null && maxDescriptionLastUpdated==Date.newInstance(1900, 1, 1) && !String.isBlank(c.Description)) {description = c.Description;}
            if (!String.isBlank(c.Hobbies__c)) {hobbies = c.Hobbies__c;}
            if (!String.isBlank(c.Dietary_Restrictions__c)) {dietaryRestrictions = c.Dietary_Restrictions__c;} 
            
            // Collate all forms filled out; listify in order to assign colon-separated string value
            // to multi-select picklist field
            List<String> allFormsFilledOut = new List<String>();
            allFormsFilledOut.addAll(uniqueForms);
            String formsMultiSelectString = String.join(allFormsFilledOut, ';');
            System.debug('All forms: ' + formsMultiSelectString);
            if (maxGDPRConsentDate > Date.newInstance(1900, 1, 1) || optedInToEmail) {
                c.GDPR_Consent_Date__c = maxGDPRConsentDate > Date.newInstance(1900, 1, 1) ? maxGDPRConsentDate : null;
                c.Email_Opted_In__c = true;
                c.HasOptedOutOfEmail = false;
                c.GDPR_Decline_Date__c = null;
            }
            if (formsMultiSelectString!='') {
                c.Forms_Filled_Out__c = formsMultiSelectString;
            }
            c.Do_Not_Solicit__c = doNotSolicit;
            c.Newsletter__c = signedUpForNewsletter;
            c.Book_Club__c = signedUpForBookClub;
            c.She_Creates_Change__c = signedUpForSheCreatesChange;
            if (maxSMSConsentDate > maxSMSDeclineDate) {
                c.SMS_Opt_In__c = true;
                c.SMS_Consent_Date__c = maxSMSConsentDate;
                c.SMS_Decline_Date__c = null;
            }
            else if (maxSMSDeclineDate>maxSMSConsentDate) {
                c.SMS_Opt_In__c = false;
                c.SMS_Consent_Date__c = maxSMSConsentDate > Date.newInstance(1900, 1, 1) ? maxSMSConsentDate : null;
                c.SMS_Decline_Date__c = maxSMSDeclineDate;
            } 
            else {c.SMS_Opt_In__c = signedUpForSMS;}
            c.Volunteer__c = volunteer;
            if (!String.isBlank(street) && !String.isBlank(country) && String.isBlank(c.MailingStreet)) {
                c.MailingStreet = street;
                c.MailingCity = city;
                c.MailingState = state;
                c.MailingPostalCode = postalCode;
                c.MailingCountry = country;
            }
            c.Description = description;
            c.Description_Last_Updated__c = maxDescriptionLastUpdated > Date.newInstance(1900, 1, 1) ? maxDescriptionLastUpdated : null;
            c.Hobbies__c = hobbies;
            c.Dietary_Restrictions__c = dietaryRestrictions;
            update c;
            
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(leadId);
            lc.setContactId(c.Id);
            lc.setAccountId(c.AccountId);
			lc.setConvertedStatus(convertStatus.MasterLabel);
			lc.setDoNotCreateOpportunity(true);
			Database.LeadConvertResult result = Database.convertLead(lc, false);
         	if (result.isSuccess()) {
            	System.debug('Lead converted successfully');
            	System.debug('Account Id: ' + result.getAccountId());
            	System.debug('Contact ID: ' + result.getContactId());
                convertedLeadContactId = result.getContactId();
         	} 
           	else {
            	System.debug('Error converting new Lead: ' + result.getErrors()[0].getMessage());
         	}            
        }
        if (!String.isBlank(convertedLeadContactId) && !String.isBlank(affiliateOrgId) && !String.isBlank(affiliationType)) {
            npe5__Affiliation__c affil = new npe5__Affiliation__c(
            npe5__Contact__c = convertedLeadContactId,
            npe5__Organization__c = affiliateOrgId,
            Type__c = affiliationType,
            npe5__Primary__c = primaryAffiliation);
            insert affil;
        }
        return convertedLeadContactId;
    }
}