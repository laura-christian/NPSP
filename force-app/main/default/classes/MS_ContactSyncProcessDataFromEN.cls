/**
 * Process Contact Data for our Contact Sync Staging Records.
 * Update Engaging Networks Staging Records with the resulting Contact matchings.
 * 
 * Authored by Jake Martin White
 * jake@mustardseednonprofit.ca
 *
 */

public class MS_ContactSyncProcessDataFromEN implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    public Date trxnDate;
    public List<String> supporterIds;    
    public EN_Dataservice_Settings__mdt settings;


    public MS_ContactSyncProcessDataFromEN(Date trxnDate, List<String> supporterIds) {
        this.trxnDate = trxnDate;
        this.supporterIds = supporterIds;
        this.settings = [SELECT Contact_Sync_Household_Record_Type__c,
                Contact_Sync_Organization_Record_Type__c,
                Contact_Transaction_Codes__c,
                Lead_Transaction_Codes__c,
                Notification_Emails__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
    }
    
    public List<String> start(Database.BatchableContext bc) {  
		System.debug('>>>> Init batch processing of contact sync staging records');
		return supporterIds;
    }
    
    public void execute(Database.BatchableContext bc, List<String> scope) {        
        processContacts(scope);
        processOrgs(scope);
        processLeads(scope);
    }
    
    private void processContacts(List<String> supporterIds) {

        // Query all Contact Sync Staging Records for the day with supporter IDs in this batch
        //
        // Note that in this method we query all transaction types, but only process those involving giving
        // transactions into contacts. This is so that if a supporter had multiple actions in a day, including, for instance,
        // DCF actions that would normally result in their creation as a lead, we still put a Contact Id on those DCF records.

        List<String> trxnTypes = settings.Contact_Transaction_Codes__c.split(',');
        List<Contact_Sync_Staging_Record__c> cssrs = [
            SELECT Id, Supporter_Id__c, Supporter_Email__c, Title__c, First_Name__c, Last_Name__c,
                Japanese_First_Name__c, Japanese_Last_Name__c, Address_1__c, City__c, State__c, 
                Zip_Code__c, Country__c, Phone_Number__c, Mobile_Phone_Number__c, Transaction_Type__c, Transaction_Date_Time__c, 
                Transaction_Data_21__c, Is_Organization__c, Processed__c,
                Matched_Account__c, Matched_Contact__c, Matched_Lead__c, Match_Method__c
            FROM Contact_Sync_Staging_Record__c
            WHERE Transaction_Date__c = :trxnDate
                AND Processed__c = false
                AND Supporter_Id__c IN :supporterIds
            	AND First_Name__c != null AND Last_Name__c != null
            ORDER BY Supporter_Id__c, Transaction_Type__c
        ];
        
        // Put the Contact Sync Staging Records in a map. Note that query results are ordered first by
        // supporter Id and then by transaction type so that if there is any P2P (ACS) transaction for
        // a supporter in the batch, it will be the first to be mapped (some ACS staging records require
        // special handling)
        Map<String, Contact_Sync_Staging_Record__c> cssrMap = new Map<String, Contact_Sync_Staging_Record__c>();
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if (trxnTypes.contains(cssr.Transaction_Type__c) && !cssrMap.containsKey(cssr.Supporter_Id__c)) {
				cssrMap.put(cssr.Supporter_Id__c, cssr);
            }
        }
        
        //
        // Build map of contacts with email addresses matching CSSRs
        //
        List<String> supporterEmails = new List<String>();
        for (Contact_Sync_Staging_Record__c cssr : cssrMap.values()) {
            if (!String.isBlank(cssr.Supporter_Email__c)) {
                supporterEmails.add(cssr.Supporter_Email__c);
            }
        }
        
        List<Contact> emailMatches = [
            SELECT Id, AccountId, Email, npe01__Preferred_Email__c,
                npe01__HomeEmail__c, npe01__WorkEmail__c, 
                npe01__AlternateEmail__c
            FROM Contact
            WHERE npe01__HomeEmail__c IN :supporterEmails
                OR npe01__WorkEmail__c IN :supporterEmails
                OR npe01__AlternateEmail__c IN :supporterEmails
            	OR Email IN :supporterEmails
        ];

        // map email keys to lists of contacts who share that email
        Map<String,List<Contact>> emailToContacts = new Map<String,List<Contact>>();        
        for (Contact c : emailMatches) {
            if (!String.isBlank(c.npe01__HomeEmail__c)) {
                if (!emailToContacts.containsKey(c.npe01__HomeEmail__c)) {
                    emailToContacts.put(c.npe01__HomeEmail__c, new List<Contact>{c});
                }
                else {
                    emailToContacts.get(c.npe01__HomeEmail__c).add(c);
                }
            }
            if (!String.isBlank(c.npe01__WorkEmail__c)) {
                if (!emailToContacts.containsKey(c.npe01__WorkEmail__c)) {
                    emailToContacts.put(c.npe01__WorkEmail__c, new List<Contact>{c});
                }
                else {
                    emailToContacts.get(c.npe01__WorkEmail__c).add(c);
                }
            }
            if (!String.isBlank(c.npe01__AlternateEmail__c)) { 
                if (!emailToContacts.containsKey(c.npe01__AlternateEmail__c)) {
                    emailToContacts.put(c.npe01__AlternateEmail__c, new List<Contact>{c});
                }
                else {
                    emailToContacts.get(c.npe01__AlternateEmail__c).add(c);
                }
            }
        }
        
        //
        // run each CSSR through dupe filters
        //
        List<Contact> contactsToDedupe = new List<Contact>();
        for (Contact_Sync_Staging_Record__c cssr : cssrMap.values()) {
            Contact c = new Contact(
                FirstName = cssr.First_Name__c,
                LastName = cssr.Last_Name__c,
                MailingStreet = cssr.Address_1__c,
                MailingCity = cssr.City__c,
                MailingState = cssr.State__c,
                MailingPostalCode = cssr.Zip_Code__c,
                MailingCountry = cssr.Country__c,
                Email = cssr.Supporter_Email__c,
                npe01__HomeEmail__c = cssr.Supporter_Email__c,
                npe01__WorkEmail__c = cssr.Supporter_Email__c,
                npe01__AlternateEmail__c = cssr.Supporter_Email__c,
                Phone = !String.isBlank(cssr.Mobile_Phone_Number__c) ? cssr.Mobile_Phone_Number__c : cssr.Phone_Number__c,
                engaging__EN_Supporter_Id__c = cssr.Supporter_Id__c
            );
            contactsToDedupe.add(c);
        }
        
        Datacloud.FindDuplicatesResult[] results;
        if (contactsToDedupe.size() > 0) {
            results = Datacloud.FindDuplicates.findDuplicates(contactsToDedupe);
        }

		Map<String,Contact> supporterToDupeContact = new Map<String,Contact>();
        for (Integer i = 0; i < contactsToDedupe.size(); i++) {
            for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {
                if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
                    if (dr.getMatchResults()[0].getMatchRecords()[0].getRecord().Id.getSObjectType().getDescribe().getName() == 'Contact') {
                    // Take first match we find, but only if it is a contact - the last matching rule against which 
                    // new contacts are checked looks for duplicate leads, but we want to create a contact record even
                    // if there is a duplicate lead so that conversion of the latter will be reflected in the 
                    // system
                        supporterToDupeContact.put(
                            contactsToDedupe[i].engaging__EN_Supporter_Id__c,
                            (Contact)dr.getMatchResults()[0].getMatchRecords()[0].getRecord()
                        );
                        break;
                    }
                }
            }
        }
            
        // where there were dupe matches, load the entire contact record
        // so we can update email fields later
        Set<Id> dupeIds = new Set<Id>();
        for (Contact dupe : supporterToDupeContact.values()) {
            dupeIds.add(dupe.Id);
        }
        Map<Id,Contact> fullDupes = new Map<Id,Contact>([
            SELECT Id, AccountId, Email, npe01__Preferred_Email__c,
                npe01__HomeEmail__c, npe01__WorkEmail__c, 
                npe01__AlternateEmail__c, npe01__PreferredPhone__c
            FROM Contact
            WHERE Id in :dupeIds]);
        for (String supporterId : supporterToDupeContact.keySet()) {
            Contact dupe = supporterToDupeContact.get(supporterId);
            Contact full = fullDupes.get(dupe.Id);
            supporterToDupeContact.put(supporterId, full);
        }
     
        //
        // Run through CSSR map; figure out match for each unique supporter Id
        // and build contacts for supporters that don't match
        //
        Map<String, Contact> supporterIdToContact= new Map<String, Contact>();
        List<String> supporterIdsForContactsToInsert = new List<String>();
        List<Contact> contactsToInsert = new List<Contact>();      
        List<String> supporterIdsForContactsToUpdate = new List<String>();
        Set<Id> contactIdsToUpdate = new Set<Id>(); // avoid "duplicate Id in list"
        List<Contact> contactsToUpdate = new List<Contact>();
        Set<Id> contactIdsDeleteEmail = new Set<Id>(); // avoid "duplicate Id in list"        
        List<Contact> contactsDeleteEmail = new List<Contact>();
        
        for (String supporterId : cssrMap.keySet()) {

            Contact_Sync_Staging_Record__c cssr = cssrMap.get(supporterId);
            Contact matched = null;
            Contact emailMatch = null;
            
            if (supporterToDupeContact.containsKey(supporterId)) {
                // use the Contact we got from dupe rules
                matched = (Contact)supporterToDupeContact.get(supporterId);
                cssr.Matched_Account__c = matched.AccountId;
                cssr.Matched_Contact__c = matched.Id;
                cssr.Match_Method__c = 'Duplicate rule match';
            }

            // If an email match is found on a contact that is not a dupe, we can infer that the new supporter 
            // is a different person using the same email as someone else in their household and will assign 
            // that contact to the same account. 
            // 
            // The exception is if it's a peer-to-peer transaction, in which case
            // we do not add the donor to the existing account (since it is more likely that a contribution to a fundraising
            // page, say, from a grandparent has been mistakenly processed under the fundraiser's email address)
            else if (emailToContacts.containsKey(cssr.Supporter_Email__c) && cssr.Transaction_Type__c != 'ACS') {
                emailMatch = emailToContacts.get(cssr.Supporter_Email__c)[0];
                cssr.Matched_Account__c = emailMatch.AccountId;
                cssr.Match_Method__c = 'Email address match';
            }

            // Remove email address from standard Email field of any other contacts for whom a match has been
            // found on the supporter email, and that email address has been marked as preferred.
            // 
            // The exception, again, is peer-to-peer transactions, where folks have a habit of misusing
            // their own email addresses for other donors.
            if (emailToContacts.containsKey(cssr.Supporter_Email__c) && cssr.Transaction_Type__c != 'ACS') {
                for (Contact c : emailToContacts.get(cssr.Supporter_Email__c)) {
                    if (((matched != null && c.Id != matched.Id) || emailMatch != null) && c.Email == cssr.Supporter_Email__c && !contactIdsDeleteEmail.contains(c.Id)) {
                        c.Email = '';
                        contactsDeleteEmail.add(c);
                        contactIdsDeleteEmail.add(c.Id);
                    }
                }
            }
            
            // Finally, if this is a P2P transaction, re-sync contact details originally associated with the email address into EN,
            // to ensure a user submitting a contribution to their own fundraising page on behalf of grandma, 
            // uncle, etc. under their own email address does not have their supporter record
            // overwritten
            else if (emailToContacts.containsKey(cssr.Supporter_Email__c) && cssr.Transaction_Type__c == 'ACS') {
                for (Contact c : emailToContacts.get(cssr.Supporter_Email__c)) {
                    if (c.Email == cssr.Supporter_Email__c && !contactIdsToUpdate.contains(c.Id)) {
                        Datetime now = System.now();
                        Datetime localNow = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());                        
                        c.engaging__EN_Last_Modified_Date__c = localNow;
                        supporterIdsForContactsToUpdate.add(supporterId);
                        contactsToUpdate.add(c);
                        contactIdsToUpdate.add(c.Id);
                    }
                }
            }

            if (!String.isBlank(cssr.Matched_Contact__c) && !String.isBlank(cssr.Supporter_Email__c)) {
                // Mark email used by supporter in latest transaction as preferred:
                // 1. check to see whether email already resides in one of the available NGOC email fields;
                // 2. if email not found in any NGOC fields, map new email to fields in this order: Home, Other, Work
                if (matched.npe01__HomeEmail__c == cssr.Supporter_Email__c) {
                    matched.npe01__Preferred_Email__c = 'Personal';
                    // just in case matching email was already marked as preferred, but was later evacuated from standard 
                    // Email field, repopulate standard Email field with it
                    matched.Email = cssr.Supporter_Email__c;
                }
                else if (matched.npe01__WorkEmail__c == cssr.Supporter_Email__c) {
                    matched.npe01__Preferred_Email__c = 'Work';
                    matched.Email = cssr.Supporter_Email__c;
                }
                else if (matched.npe01__AlternateEmail__c == cssr.Supporter_Email__c) {
                    matched.npe01__Preferred_Email__c = 'Alternate';
                    matched.Email = cssr.Supporter_Email__c;                    
                }                                
                else if (String.isBlank(matched.npe01__HomeEmail__c)) {
                    matched.npe01__HomeEmail__c = cssr.Supporter_Email__c;
                    matched.npe01__Preferred_Email__c = 'Personal';
                }                
                else if (String.isBlank(matched.npe01__AlternateEmail__c)) {
                    matched.npe01__AlternateEmail__c = cssr.Supporter_Email__c;
                    matched.npe01__Preferred_Email__c = 'Alternate';
                }
                else if (String.isBlank(matched.npe01__WorkEmail__c)) {
                    matched.npe01__WorkEmail__c = cssr.Supporter_Email__c;
                    matched.npe01__Preferred_Email__c = 'Work';
                }
                else {
                    // overwrite 'Alternate' if all NPSP email fields are populated
                    matched.npe01__AlternateEmail__c = cssr.Supporter_Email__c;
                    matched.npe01__Preferred_Email__c = 'Alternate';
                }
                if (!String.isBlank(cssr.Title__c)) {
                    matched.Salutation = cssr.Title__c;
                }
                if (!String.isBlank(cssr.Japanese_First_Name__c)) {
                    matched.Japanese_First_Name__c = cssr.Japanese_First_Name__c;
                }
                if (!String.isBlank(cssr.Japanese_Last_Name__c)) {
                    matched.Japanese_Last_Name__c = cssr.Japanese_Last_Name__c;
                }
                if (!String.isBlank(cssr.Mobile_Phone_Number__c)) {
                    matched.MobilePhone = cssr.Mobile_Phone_Number__c;
                    matched.npe01__PreferredPhone__c = 'Mobile';
                }
                if (!cssr.Is_Organization__c && !String.isBlank(cssr.Phone_Number__c)) {
                    matched.HomePhone = cssr.Phone_Number__c;
                }
                else if (cssr.Is_Organization__c && !String.isBlank(cssr.Phone_Number__c)) {
                    matched.npe01__WorkPhone__c = cssr.Phone_Number__c;
                }
                matched.npe01__PreferredPhone__c = !String.isBlank(cssr.Mobile_Phone_Number__c) ? 'Mobile' : cssr.Is_Organization__c && !String.isBlank(cssr.Phone_Number__c) ? 'Work' : !cssr.Is_Organization__c && !String.isBlank(cssr.Phone_Number__c) ? 'Home' : matched.npe01__PreferredPhone__c; 
                if (!String.isBlank(cssr.Address_1__c) && !String.isBlank(cssr.Country__c)) {
                    matched.MailingStreet = cssr.Address_1__c;
                    matched.MailingCity = cssr.City__c;
                    matched.MailingState = cssr.State__c;
                    matched.MailingPostalCode = cssr.Zip_Code__c;
                    matched.MailingCountry = cssr.Country__c;
                }
                if (!contactIdsToUpdate.contains(matched.Id)) {
                    supporterIdsForContactsToUpdate.add(supporterId);
                    contactsToUpdate.add(matched);
                    contactIdsToUpdate.add(matched.Id);
                }
            }
            
            else if (String.isBlank(cssr.Matched_Contact__c)) {
                Contact c = new Contact(
                    Salutation = !String.isBlank(cssr.Title__c) ? cssr.Title__c : '',
                    FirstName = cssr.First_Name__c,
                    LastName = cssr.Last_Name__c,
                    Japanese_First_Name__c = cssr.Japanese_First_Name__c,
                    Japanese_Last_Name__c = cssr.Japanese_Last_Name__c,
                    AccountId = cssr.Matched_Account__c, // might be null
                    npe01__HomeEmail__c = !cssr.Is_Organization__c ? cssr.Supporter_Email__c : '',
                    npe01__WorkEmail__c = cssr.Is_Organization__c ? cssr.Supporter_Email__c : '',
                    npe01__Preferred_Email__c = cssr.Is_Organization__c ? 'Work' : 'Personal',            
                    MobilePhone = cssr.Mobile_Phone_Number__c,
                    HomePhone = !cssr.Is_Organization__c ? cssr.Phone_Number__c : '',
                    npe01__WorkPhone__c = cssr.Is_Organization__c ? cssr.Phone_Number__c : '',
                    engaging__EN_Supporter_Id__c = cssr.Supporter_Id__c,
                    MailingStreet = cssr.Address_1__c,
                    MailingCity = cssr.City__c,
                    MailingState = cssr.State__c,
                    MailingPostalCode = cssr.Zip_Code__c,
                    MailingCountry = cssr.Country__c
                );
                if (cssr.Transaction_Type__c == 'ACS' && emailToContacts.containsKey(cssr.Supporter_Email__c)) {
                    // don't claim email address if it's a peer-to-peer transaction with a pre-existing email
                    c.npe01__HomeEmail__c = '';
                    c.npe01__WorkEmail__c = '';
                    c.npe01__Preferred_Email__c = '';
                }
                if (!String.isBlank(cssr.Mobile_Phone_Number__c)) {c.npe01__PreferredPhone__c = 'Mobile';}
                else if (!String.isBlank(cssr.Phone_Number__c)) {c.npe01__PreferredPhone__c = cssr.Is_Organization__c ? 'Work' : 'Home';}

                supporterIdToContact.put(supporterId, c);
            }
        }
        
        System.debug('Deleting email address from standard Email field on ' + contactsDeleteEmail.size() + ' contacts');
        Database.update(contactsDeleteEmail, false);        
        //
        // create the new accounts, and update cssrs with either account Ids or error messages, depending on whether
        // operation was successful
        //       

        for (String supporterId : supporterIdToContact.keySet()) {
            Contact newContact = supporterIdToContact.get(supporterId);
            supporterIdsForContactsToInsert.add(supporterId);
            contactsToInsert.add(newContact);
        }
        
        //
        // create the new contacts
        //
        if (Test.isRunningTest() && contactsToInsert.size() > 0 && contactsToInsert[0].LastName.contains('Contact')) {contactsToInsert[0].LastName = '';}        
        System.debug('Inserting ' + contactsToInsert.size() + ' contacts');        
        Database.SaveResult[] saveResultsInsCons = Database.insert(contactsToInsert, false);
        for (Integer i=0;i<saveResultsInsCons.size();i++) {
            Contact_Sync_Staging_Record__c cssr = cssrMap.get(supporterIdsForContactsToInsert[i]);         
            if (saveResultsInsCons.get(i).isSuccess()) {               
                System.debug('Successfully inserted contact. Contact Id: ' + saveResultsInsCons.get(i).getId());
                cssr.Matched_Contact__c = saveResultsInsCons.get(i).getId();
                cssr.Match_Method__c = 'New contact';
                // for gifts made on behalf of org, will only mark contact staging record as processed once org 
                // account has been created/updated
                if (!cssr.Is_Organization__c) {cssr.Processed__c = true;}
            }
            else {
                List<String> errorMsgs = new List<String>{'Contact did not insert:'};
                for (Database.Error err : saveResultsInsCons.get(i).getErrors()) {
                    String msg = err.getStatusCode() + ': ' + err.getMessage();
                    System.debug('ERROR: ' + msg);
                    errorMsgs.add(msg);
                }
                String concatErrorMsgs = String.join(errorMsgs, '\n');
                cssr.Error_Details__c = concatErrorMsgs;
            }
        }
        
        if (Test.isRunningTest() && contactsToUpdate.size() > 0 && contactsToUpdate[0].npe01__AlternateEmail__c == 'alt_email@test.net') {contactsToUpdate[0].LastName = '';}
        System.debug('Updating ' + contactsToUpdate.size() + ' contacts');
        Database.SaveResult[] saveResultsUpdtCons = Database.update(contactsToUpdate, false);
        for (Integer i=0;i<saveResultsUpdtCons.size();i++) {
            Contact_Sync_Staging_Record__c cssr = cssrMap.get(supporterIdsForContactsToUpdate[i]);         
            if (saveResultsUpdtCons.get(i).isSuccess() && !cssr.Is_Organization__c) {cssr.Processed__c = true;}
            else {
                List<String> errorMsgs = new List<String>{'Contact did not update:'};
                for (Database.Error err : saveResultsUpdtCons.get(i).getErrors()) {
                    String msg = err.getStatusCode() + ': ' + err.getMessage();
                    System.debug('ERROR: ' + msg);
                    errorMsgs.add(msg);
                }
                String concatErrorMsgs = String.join(errorMsgs, '\n');
                cssr.Error_Details__c = concatErrorMsgs;
            }
        }
        //
        // update all the CSSRs - not just the unique ones, but everything
        // we queried from the very start
        //
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if (cssrMap.containsKey(cssr.Supporter_Id__c)) {
                Contact_Sync_Staging_Record__c masterCSSR = (Contact_Sync_Staging_Record__c)cssrMap.get(cssr.Supporter_Id__c);
                cssr.Matched_Contact__c = masterCSSR.Matched_Contact__c;
                cssr.Match_Method__c = masterCSSR.Match_Method__c;
                cssr.Processed__c = masterCSSR.Processed__c;
                
                // if the match entry processed as an org entry but this entry is the same supporter, non-org, then
                // set processed = true. Really this shouldn't happen but setting it here just in case
                if (masterCSSR.Is_Organization__c && masterCSSR.Matched_Account__c != null && cssr.Is_Organization__c == false) {
                    cssr.Processed__c = true;
                }
            }
        }
        Database.update(cssrs, false);

        //
        // and now update the Engaging Networks Staging Records
        //
        List<engaging__Engaging_Networks_Staging_Record__c> ensrs = [
            SELECT Id, engaging__Supporter_Id__c,
                engaging__SFDC_Contact_Id__c
            FROM engaging__Engaging_Networks_Staging_Record__c
            WHERE engaging__Processed__c = false
                AND engaging__Transaction_Date__c = :trxnDate
                AND engaging__Supporter_Id__c IN :cssrMap.keySet()
        ];
        
        List<engaging__Engaging_Networks_Staging_Record__c> ensrsToUpdate = new List<engaging__Engaging_Networks_Staging_Record__c>();
        for (engaging__Engaging_Networks_Staging_Record__c ensr : ensrs) {
            Contact_Sync_Staging_Record__c masterCSSR = (Contact_Sync_Staging_Record__c)cssrMap.get(ensr.engaging__Supporter_Id__c);
            ensr.engaging__SFDC_Contact_Id__c = masterCSSR.Matched_Contact__c;
            ensrsToUpdate.add(ensr);
        }
        Database.update(ensrsToUpdate, false);
    }

    private void processOrgs(List<String> supporterIds) {
    
        // query all Contact Sync Staging Records for the day, for Organizations
        List<String> trxnTypes = settings.Contact_Transaction_Codes__c.split(',');
        List<Contact_Sync_Staging_Record__c> cssrs = [
            SELECT Id, Supporter_Id__c, Transaction_Data_21__c,
                Address_1__c, City__c, State__c, Zip_Code__c, Country__c, 
                Matched_Contact__c, Matched_Organization__c, Error_Details__c
            FROM Contact_Sync_Staging_Record__c
            WHERE Transaction_Date__c = :trxnDate
                AND Transaction_Type__c IN :trxnTypes
                AND Supporter_Id__c IN :supporterIds
                AND Is_Organization__c = true
                AND Matched_Organization__c = null
            ORDER BY Transaction_Date_Time__c ASC
        ];
        
        // get the distinct org names and query existing Accounts
        Set<String> orgNames = new Set<String>();
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if(!String.isBlank(cssr.Transaction_Data_21__c)) {
                System.debug('Organization name: ' + cssr.Transaction_Data_21__c);
                orgNames.add(cssr.Transaction_Data_21__c);
            }
        }
        List<Account> accts = [SELECT Id, Name, BillingCity
            FROM Account
            WHERE Name in :orgNames AND BillingCity != null
        ];
        
        Map<String,Account> acctMap = new Map<String,Account>();
        for (Account acct : accts) {
            acctMap.put(acct.Name + '|' + acct.BillingCity, acct);
        }
        
        // sweep for any missing accounts
        List<String> acctBillingCityKeys = new List<String>();
        List<Account> acctsToInsert = new List<Account>();
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if (!acctMap.containsKey(cssr.Transaction_Data_21__c + '|' + cssr.City__c)) {
                Account acct = new Account(
                    Name = cssr.Transaction_Data_21__c,
                    npe01__One2OneContact__c = cssr.Matched_Contact__c,
                    Type = 'Organization',
                    BillingStreet = cssr.Address_1__c,
                    BillingCity = cssr.City__c,
                    BillingState = cssr.State__c,
                    BillingPostalCode = cssr.Zip_Code__c,
                    BillingCountry = cssr.Country__c,
                    RecordTypeId = settings.Contact_Sync_Organization_Record_Type__c
                );
                acctBillingCityKeys.add(cssr.Transaction_Data_21__c + '|' + cssr.City__c);
                acctsToInsert.add(acct);
            }
        }
        
        if (Test.isRunningTest() && acctsToInsert.size()>0 && acctsToInsert[0].Name == 'Acme Co.') {acctsToInsert[0].Name = '';}
        Database.SaveResult[] saveResults = Database.insert(acctsToInsert, false);
        Map<String,String> acctBillingCityToErrorMsg = new Map<String,String>();
        for (Integer i=0;i<saveResults.size();i++) {        
            if (saveResults.get(i).isSuccess()) {               
                System.debug('Successfully inserted account. Account Id: ' + saveResults.get(i).getId());
                acctMap.put(acctsToInsert[i].Name + '|' + acctsToInsert[i].BillingCity, acctsToInsert[i]);
            }
            else {
                List<String> errorMsgs = new List<String>{'Account did not insert:'};
                for (Database.Error err : saveResults.get(i).getErrors()) {
                    String msg = err.getStatusCode() + ': ' + err.getMessage();
                    System.debug('ERROR: ' + msg);
                    errorMsgs.add(msg);
                }
                String concatErrorMsgs = String.join(errorMsgs, '\n');
                acctBillingCityToErrorMsg.put(acctsToInsert[i].Name + '|' + acctsToInsert[i].BillingCity, concatErrorMsgs);
            }
        }        
              

        // update Matched_Organization__c on all CSSRs
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if (acctMap.containsKey(cssr.Transaction_Data_21__c + '|' + cssr.City__c)) {
                cssr.Matched_Organization__c = acctMap.get(cssr.Transaction_Data_21__c + '|' + cssr.City__c).Id;
                cssr.Processed__c = true;
            }
            else cssr.Error_Details__c += acctBillingCityToErrorMsg.get(cssr.Transaction_Data_21__c + '|' + cssr.City__c);
        }
        Database.update(cssrs, false);
        
        // insert org affiliations
        List<npe5__Affiliation__c> relsToInsert = new List<npe5__Affiliation__c>();
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if (cssr.Matched_Organization__c != null && cssr.Matched_Contact__c != null) {
                npe5__Affiliation__c rel = new npe5__Affiliation__c(
                    Type__c = 'Employee',
                    npe5__Status__c  = 'Current',
                    npe5__Contact__c = cssr.Matched_Contact__c,
                    npe5__Organization__c = cssr.Matched_Organization__c
                );
                relsToInsert.add(rel);
            }
        }
        Database.insert(relsToInsert, false);
        
        //
        // finally, update the Engaging Networks Staging Records
        // ENSR doesn't have city - need to use supporter id + acct name and hope for the best
        //
        Map<String,Contact_Sync_Staging_Record__c> cssrMap = new Map<String,Contact_Sync_Staging_Record__c>();
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            cssrMap.put(cssr.Supporter_Id__c + '|' + cssr.Transaction_Data_21__c, cssr);
        }

        List<engaging__Engaging_Networks_Staging_Record__c> ensrs = [
            SELECT Id, engaging__Supporter_Id__c, SFDC_Account_Id__c,
                engaging__Transaction_Data_21__c
            FROM engaging__Engaging_Networks_Staging_Record__c
            WHERE engaging__Processed__c = false
                AND engaging__Transaction_Date__c = :trxnDate
                AND engaging__Supporter_Id__c IN :supporterIds
                AND Is_Organization__c = true
        ];

        List<engaging__Engaging_Networks_Staging_Record__c> ensrsToUpdate = new List<engaging__Engaging_Networks_Staging_Record__c>();
        for (engaging__Engaging_Networks_Staging_Record__c ensr : ensrs) {
            if (cssrMap.containsKey(ensr.engaging__Supporter_Id__c + '|' + ensr.engaging__Transaction_Data_21__c)) {
                Contact_Sync_Staging_Record__c match = cssrMap.get(ensr.engaging__Supporter_Id__c + '|' + ensr.engaging__Transaction_Data_21__c);
                ensr.SFDC_Account_Id__c = match.Matched_Organization__c;
                ensrsToUpdate.add(ensr);
            }
        }
        Database.update(ensrsToUpdate, false);
    }

    
    private void processLeads(List<String> supporterIds) {

        // query Contact Sync Staging Records for the day with the supporter IDs in this batch 
        // for transactions relevant to Lead creation - e.g., DCF
        List<String> trxnTypes = settings.Lead_Transaction_Codes__c.split(',');
        List<Contact_Sync_Staging_Record__c> cssrs = [
            SELECT Id, Supporter_Id__c, Supporter_Email__c, First_Name__c, Last_Name__c,
                Japanese_First_Name__c, Japanese_Last_Name__c, Address_1__c, City__c, State__c, 
                Zip_Code__c, Country__c, Phone_Number__c, Mobile_Phone_Number__c, Transaction_Type__c, Transaction_Date_Time__c, 
                Processed__c, EN_Tracking_Value__c, EN_Campaign_Name__c, Campaign_Reference_8__c, Campaign_Reference_9__c, 
                Campaign_Reference_10__c, Matched_Account__c, Matched_Contact__c, Matched_Lead__c, Match_Method__c
            FROM Contact_Sync_Staging_Record__c
            WHERE Transaction_Date__c = :trxnDate
                AND Processed__c = false
                AND Supporter_Id__c IN :supporterIds
                AND Transaction_Type__c IN :trxnTypes
				AND First_Name__c != null AND Last_Name__c != null            
            ORDER BY Supporter_Id__c, Transaction_Type__c
        ];

        // Put the Contact Sync Staging Records in a map. Skip over QCB records unless they are related to
        // an SMS opt-in so that only transaction types that may pertain specifically to leads (DCF or UNS or the
        // occasional SMS opt-in for a lead whose mobile phone we've captured) will be included
        Map<String, Contact_Sync_Staging_Record__c> cssrMap = new Map<String, Contact_Sync_Staging_Record__c>();
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if (cssr.Transaction_Type__c=='QCB' && !cssr.EN_Campaign_Name__c.contains('SMS')) {continue;}
            else if (!cssrMap.containsKey(cssr.Supporter_Id__c)) {
                cssrMap.put(cssr.Supporter_Id__c, cssr);
			}
        }

        //
        // run each CSSR through dupe filters
        //
        List<Lead> leadsToDedupe = new List<Lead>();
        for (Contact_Sync_Staging_Record__c cssr : cssrMap.values()) {
            if (String.isBlank(cssr.Matched_Contact__c)) {
                Lead l = new Lead(
                    FirstName = cssr.First_Name__c,
                    LastName = cssr.Last_Name__c,
                    Company = 'Household',
                    Email = cssr.Supporter_Email__c,
                    Phone = !String.isBlank(cssr.Mobile_Phone_Number__c) ? cssr.Mobile_Phone_Number__c : cssr.Phone_Number__c,
                    EN_Supporter_Id__c = cssr.Supporter_Id__c
                );
                leadsToDedupe.add(l);
            }
        }
        
        Datacloud.FindDuplicatesResult[] results;
        if (leadsToDedupe.size() > 0) {
            results = Datacloud.FindDuplicates.findDuplicates(leadsToDedupe);
        }
    
        Map<String,Lead> supporterToDupeLead = new Map<String,Lead>();
        Map<String,Contact> supporterToDupeContact = new Map<String,Contact>();
        
        for (Integer i = 0; i < leadsToDedupe.size(); i++) {
            for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {
                if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
                    if (dr.getMatchResults()[0].getMatchRecords()[0].getRecord().Id.getSObjectType().getDescribe().getName() == 'Contact') {
                        supporterToDupeContact.put(
                            leadsToDedupe[i].EN_Supporter_Id__c,
                            (Contact)dr.getMatchResults()[0].getMatchRecords()[0].getRecord()
                        );
                        break;
                    }
                    else if (dr.getMatchResults()[0].getMatchRecords()[0].getRecord().Id.getSObjectType().getDescribe().getName() == 'Lead') {
                        supporterToDupeLead.put(
                            leadsToDedupe[i].EN_Supporter_Id__c,
                            (Lead)dr.getMatchResults()[0].getMatchRecords()[0].getRecord()
                        );
                        break;
                    }
                }
            }
        }
        
        // create leads where no dupe was found
        List<String> supporterIdsForLeadsToInsert = new List<String>();
        List<Lead> leadsToInsert = new List<Lead>();        
        for (String supporterId : cssrMap.keySet()) {
            Contact_Sync_Staging_Record__c cssr = cssrMap.get(supporterId);
            if (supporterToDupeContact.containsKey(supporterId) && String.isBlank(cssr.Matched_Contact__c)) {
                cssr.Matched_Contact__c = supporterToDupeContact.get(supporterId).Id;
                cssr.Match_Method__c = 'Duplicate rule match';
                cssr.Processed__c = true;
            }
            else if (supporterToDupeLead.containsKey(supporterId)) {
                cssr.Matched_Lead__c = supporterToDupeLead.get(supporterId).Id;
                cssr.Match_Method__c = 'Duplicate rule match';
                cssr.Processed__c = true;
            }
            // New leads should only be created from supporters who have filled out DCFs on the website.
            // If only a QCB or UNS transaction record has come through for a supporter, a match should have
            // been found in the system for them. "Orphaned" QCB records not associated with a donation- or
            // subscription-related transaction indicate a transaction that failed, and no new lead record should
            // be created in connection with them.
            else if (cssr.Transaction_Type__c!='DCF') {continue;}
            else {
                Lead l = new Lead(
                    FirstName = cssr.First_Name__c,
                    LastName = cssr.Last_Name__c,
                    Company = 'Household',
                    Japanese_First_Name__c = cssr.Japanese_First_Name__c,
                    Japanese_Last_Name__c = cssr.Japanese_Last_Name__c,                    
                    Email = cssr.Supporter_Email__c,
                    MobilePhone = cssr.Mobile_Phone_Number__c,
                    Phone = cssr.Phone_Number__c,
                    EN_Supporter_Id__c = cssr.Supporter_Id__c,
                    Street = cssr.Address_1__c,
                    City = cssr.City__c,
                    State = cssr.State__c,
                    PostalCode = cssr.Zip_Code__c,
                    Country = cssr.Country__c,
                    LeadSource = String.isBlank(cssr.EN_Tracking_Value__c) ? cssr.Campaign_Reference_8__c : cssr.EN_Tracking_Value__c,
                    Lead_Sub_Source__c = cssr.Campaign_Reference_9__c
                );
                supporterIdsForLeadsToInsert.add(supporterId);
                leadsToInsert.add(l);
            }
        }
        
        if (Test.isRunningTest() && leadsToInsert.size() > 0 && leadsToInsert[0].LastName == 'Contact II') {leadsToInsert[0].Company = '';}
        Database.SaveResult[] saveResults = Database.insert(leadsToInsert, false);
        for (Integer i=0; i<saveResults.size(); i++) {
            Contact_Sync_Staging_Record__c cssr = cssrMap.get(supporterIdsForLeadsToInsert[i]);         
            if (saveResults.get(i).isSuccess()) {               
                System.debug('Successfully inserted lead. Lead Id: ' + saveResults.get(i).getId());
                cssr.Matched_Lead__c = saveResults.get(i).getId();
                cssr.Match_Method__c = 'New lead';
                cssr.Processed__c = true;
            }
            else {
                List<String> errorMsgs = new List<String>{'Lead did not insert:'};
                for (Database.Error err : saveResults.get(i).getErrors()) {
                    String msg = err.getStatusCode() + ': ' + err.getMessage();
                    System.debug('ERROR: ' + msg);
                    errorMsgs.add(msg);
                }
                String concatErrorMsgs = String.join(errorMsgs, '\n');
                cssr.Error_Details__c = concatErrorMsgs;
            }
        }
           
        // process through the CSSRs 
        // (1) if there's a dupe contact, set Matched_Contact__c
        // (2) if there's a dupe lead, set Matched_Lead__c
        // (3) otherwise pull from leadsToInsert list
        
        List<Contact_Sync_Staging_Record__c> cssrsToUpdate = new List<Contact_Sync_Staging_Record__c>();
        for (Contact_Sync_Staging_Record__c cssr : cssrs) {
            if (cssrMap.containsKey(cssr.Supporter_Id__c)) {
                Contact_Sync_Staging_Record__c masterCSSR = (Contact_Sync_Staging_Record__c)cssrMap.get(cssr.Supporter_Id__c);
                cssr.Matched_Contact__c = masterCSSR.Matched_Contact__c;
                cssr.Matched_Lead__c = masterCSSR.Matched_Lead__c;
                cssr.Match_Method__c = masterCSSR.Match_Method__c;
                cssr.Processed__c = masterCSSR.Processed__c;
                cssrsToUpdate.add(cssr);
            }
        }
        Database.update(cssrsToUpdate, false);        

        //
        // and now update the Engaging Networks Staging Records
        //
        List<engaging__Engaging_Networks_Staging_Record__c> ensrs = [
            SELECT Id, engaging__Supporter_Id__c,
                engaging__SFDC_Contact_Id__c
            FROM engaging__Engaging_Networks_Staging_Record__c
            WHERE engaging__Processed__c = false
                AND engaging__Transaction_Date__c = :trxnDate
                AND engaging__Transaction_Type__c IN :trxnTypes
                AND engaging__Supporter_Id__c IN :supporterIds
                AND engaging__SFDC_Contact_Id__c = null
        ];

        List<engaging__Engaging_Networks_Staging_Record__c> ensrsToUpdate = new List<engaging__Engaging_Networks_Staging_Record__c>();        
        for (engaging__Engaging_Networks_Staging_Record__c ensr : ensrs) {
            if (cssrMap.containsKey(ensr.engaging__Supporter_Id__c)) {
                ensr.engaging__SFDC_Contact_Id__c = cssrMap.get(ensr.engaging__Supporter_Id__c).Matched_Contact__c;
                ensr.SFDC_Lead_Id__c = cssrMap.get(ensr.engaging__Supporter_Id__c).Matched_Lead__c;
                ensrsToUpdate.add(ensr);
            }
        }
        Database.update(ensrsToUpdate, false); 
    }
 
 
    public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job processing EN CSSRs: ' + job.Status);
    }
}