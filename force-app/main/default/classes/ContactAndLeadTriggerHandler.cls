public class ContactAndLeadTriggerHandler {
    
    public static List<User> rtrUser = [SELECT Id FROM User WHERE Name = 'Room to Read' LIMIT 1];
    public static Set<String> doNotSolicit = new Set<String>{'Bahrain', 'BH', 'Cyprus', 'CY', 'Egypt', 'EG', 'Iran', 'IR', 'Iraq', 'IQ', 'Israel', 'IL', 'Jordan', 'JO', 'Kuwait', 'KW', 'Lebanon', 'LB', 'Oman', 'OM', 'Palestine', 'PS', 'Qatar', 'QA', 'Saudi Arabia', 'SA', 'Syria', 'SY', 'Turkey', 'TR', 'United Arab Emirates', 'AE', 'Yemen', 'YE', 'Singapore', 'SG'};                
    public static Set<String> GDPRCountries = new Set<String>{'Austria', 'AT', 'Belgium', 'BE', 'Bulgaria', 'BU', 'Cyprus', 'CY', 'Czech Republic', 'CZ', 'Denmark', 'DK', 'Estonia', 'EE', 'Finland', 'FI', 'France', 'FR', 'Germany', 'DE', 'Greece', 'GR', 'Hungary', 'HU', 'Ireland', 'IE', 'Italy', 'IT', 'Latvia', 'LV', 'Lithuania', 'LT', 'Luxembourg', 'LU', 'Malta', 'MT', 'Netherlands', 'NL', 'Poland', 'PL', 'Portugal', 'PT', 'Romania', 'RO', 'Slovakia', 'SK', 'Slovenia', 'SI', 'Spain', 'ES', 'Sweden', 'SE', 'United Kingdom', 'GB', 'UK', 'Switzerland', 'CH', 'Iceland', 'IS', 'Norway', 'NO', 'Liechtenstein', 'LI'};
    
    public static void isBeforeContact(List<Contact> contacts, Map<Id, Contact> oldContactsMap, Boolean isInsert, Boolean isUpdate) {
        Set<Id> acctIds = new Set<Id>();
        for (Contact c : contacts) {
            acctIds.add(c.AccountId);
        }
        Map<Id, Account> acctsMap = new Map<Id, Account>([SELECT Id, RecordType.Name FROM Account WHERE Id IN :acctIds]);
        for (Contact c : contacts) {
            if (!String.isBlank(c.AccountId) && acctsMap.get(c.AccountId).RecordType.Name != 'Household Account') {
                c.addError('You cannot add a contact to an organizational or board account. Each contact must have his or her own household account, which will be created automatically as soon as you save the new contact record.');
            }
        }
        for (Contact c: contacts) {
            if (!String.isBlank(c.Salutation)) {
                if (c.Salutation == 'Mrs' || c.Salutation == 'Ms' || c.Salutation == 'Mr' || c.Salutation == 'Dr') {
                    c.Salutation = c.Salutation + '.';
                }
            }
            if (!String.isBlank(c.Title)) {
                if (c.Title.contains('Mrs') || c.Title.contains('Ms') || c.Title.contains('Mr') || c.Title == 'Dr' || c.Title == 'Dr.' || c.Title == 'Miss') {
                    if (!c.Title.contains('.') && c.Title != 'Miss') {c.Salutation = c.Title + '.';}
                    else {c.Salutation = c.Title;}
                    c.Title = null;
                }
            }
            if (!String.isBlank(c.npe01__HomeEmail__c) && !String.isBlank(c.npe01__WorkEmail__c) && c.npe01__HomeEmail__c  == c.npe01__WorkEmail__c) {
                c.npe01__WorkEmail__c  = null;
                c.npe01__Preferred_Email__c  = 'Personal';
            }
            if (!String.isBlank(c.npe01__HomeEmail__c) && !String.isBlank(c.npe01__AlternateEmail__c) && c.npe01__HomeEmail__c == c.npe01__AlternateEmail__c) {
                c.npe01__AlternateEmail__c = null;
                c.npe01__Preferred_Email__c = 'Personal';
            }                
            else if (!String.isBlank(c.npe01__WorkEmail__c) && !String.isBlank(c.npe01__AlternateEmail__c) && c.npe01__WorkEmail__c == c.npe01__AlternateEmail__c) {
                c.npe01__AlternateEmail__c = null;
                c.npe01__Preferred_Email__c = 'Work';
            }               
            if (Trigger.isInsert) {
                // Contact owner always defaults to generic Room to Read user 
                c.OwnerId = !rtrUser.isEmpty() ? rtrUser[0].Id : UserInfo.getUserId();
                if (c.npsp__Do_Not_Contact__c) {c.HasOptedOutOfEmail = true; c.DoNotCall = true;}
                if (!String.isBlank(c.MailingCountry) && doNotSolicit.contains(c.MailingCountry)) {c.Do_Not_Solicit__c = true;}                 
                capitalizeFirstAndLastNamesContact(c);
                //subscribeToNewsletterContact(c); 
                if (!String.isBlank(c.MobilePhone))
                    c.MobilePhone = DataQualityUtilities.formatPhoneNumber(c.MobilePhone);
                if (!String.isBlank(c.npe01__WorkPhone__c))
                    c.npe01__WorkPhone__c  = DataQualityUtilities.formatPhoneNumber(c.npe01__WorkPhone__c);
                if (!String.isBlank(c.HomePhone))
                    c.HomePhone = DataQualityUtilities.formatPhoneNumber(c.HomePhone);
                if (!String.isBlank(c.OtherPhone))
                    c.OtherPhone = DataQualityUtilities.formatPhoneNumber(c.OtherPhone);
                if (!String.isBlank(c.AssistantPhone))
                    c.AssistantPhone = DataQualityUtilities.formatPhoneNumber(c.AssistantPhone);
            }
            if (isUpdate) {
                if (oldContactsMap.get(c.Id).MailingCountry != c.MailingCountry) {
                    if (doNotSolicit.contains(c.MailingCountry)) {c.Do_Not_Solicit__c = true;}
                    subscribeToNewsletterContact(c);
                }
                if (!String.isBlank(c.Email) && c.Email_Opted_In__c && (oldContactsMap.get(c.Id).Email_Opted_In__c == false || oldContactsMap.get(c.Id).GDPR_Consent_Date__c != c.GDPR_Consent_Date__c)) {
                    c.npsp__Do_Not_Contact__c = false;
                    c.HasOptedOutOfEmail = false;
                    c.GDPR_Decline_Date__c = null;                       
                    c.Newsletter__c = true;
                    if (!String.isBlank(c.MailingCountry) && !doNotSolicit.contains(c.MailingCountry)) {c.Do_Not_Solicit__c = false;}
                }
                if (!oldContactsMap.get(c.Id).HasOptedOutOfEmail && c.HasOptedOutOfEmail) {
                    c.Newsletter__c = false;
                    c.Book_Club__c = false;
                    c.She_Creates_Change__c = false;
                    if (UserInfo.getFirstName() + ' ' + UserInfo.getLastName() == 'Room to Read' && c.EN_Latest_Opt_In_Date__c == null) {c.GDPR_Decline_Date__c = System.today();}
                }
                if (!oldContactsMap.get(c.Id).npsp__Do_Not_Contact__c && c.npsp__Do_Not_Contact__c) {
                    c.Newsletter__c = false;
                    c.Book_Club__c = false;
                    c.She_Creates_Change__c = false;
                    c.HasOptedOutOfEmail = true;
                    c.DoNotCall = true;
                }
            }
        }        
    }
    
    public static void isAfterContact(List<Contact> contacts, Map<Id, Contact> oldContactsMap, Boolean isInsert, Boolean isUpdate) {
        Set<Id> acctIds = new Set<Id>();
        Set<Id> jpAcctIds = new Set<Id>();
        for (Contact c : contacts) {
            if (isInsert || (isUpdate && (oldContactsMap.get(c.Id).Nickname__c != c.Nickname__c || oldContactsMap.get(c.Id).FirstName != c.FirstName))) {
                acctIds.add(c.AccountId);
            }
            if (!String.isBlank(c.Japanese_First_Name__c) && !String.isBlank(c.Japanese_Last_Name__c) && (isInsert || (isUpdate && (oldContactsMap.get(c.Id).Japanese_First_Name__c != c.Japanese_First_Name__c || oldContactsMap.get(c.Id).Japanese_Last_Name__c != c.Japanese_Last_Name__c)))) {
                jpAcctIds.add(c.AccountId);
            }
        }
        List<Account> accts = [SELECT Id, Name, (SELECT Id, FirstName, Nickname__c FROM Contacts WHERE npsp__Exclude_from_Household_Informal_Greeting__c = false) FROM Account WHERE Id IN :acctIds ORDER BY Id];
        Map<Id, List<String>> acctIdToContactNames = new Map<Id, List<String>>();

        for (Account a : accts) {
            for (Contact c : a.Contacts) {
                String informalName;
                if (!String.isBlank(c.Nickname__c)) {informalName = c.Nickname__c;}
                else {informalName = c.FirstName;}
                if (!acctIdToContactNames.containsKey(a.Id)) {
                    acctIdToContactNames.put(a.Id, new List<String>{informalName});
                }
                else {acctIdToContactNames.get(a.Id).add(informalName);}
            }
        }
		List<Account> jpAccts = [SELECT Id, Name, (SELECT Id, Japanese_First_Name__c, Japanese_Last_Name__c FROM Contacts WHERE Japanese_First_Name__c != null AND Japanese_Last_Name__c != null) FROM Account WHERE Id IN :jpAcctIds ORDER BY Id];        
		Map<Id, String> acctIdToJPAcctName = new Map<Id, String>();
		Map<Id, String> acctIdToJPGreeting = new Map<Id, String>();        
        for (Account jpAcct : jpAccts) {
            String acctName = '';
            String greeting = '';
            if (jpAcct.Contacts.size()==2) {
                if (jpAcct.Contacts[0].Japanese_Last_Name__c == jpAcct.Contacts[1].Japanese_Last_Name__c) {
                    acctName = jpAcct.Contacts[0].Japanese_Last_Name__c + ' ' + jpAcct.Contacts[0].Japanese_First_Name__c + '、' + jpAcct.Contacts[1].Japanese_First_Name__c;
                	greeting = acctName + '御中';
                }
                else {
                    acctName = jpAcct.Contacts[0].Japanese_Last_Name__c + ' ' + jpAcct.Contacts[0].Japanese_First_Name__c + '様、' + jpAcct.Contacts[1].Japanese_Last_Name__c + ' ' + jpAcct.Contacts[1].Japanese_First_Name__c + '様';
                	greeting = jpAcct.Contacts[0].Japanese_Last_Name__c + ' ' + jpAcct.Contacts[0].Japanese_First_Name__c + '様、' + jpAcct.Contacts[1].Japanese_Last_Name__c + ' ' + jpAcct.Contacts[1].Japanese_First_Name__c + '様';
                }
            }
            else if (jpAcct.Contacts.size()==1) {
                acctName = jpAcct.Contacts[0].Japanese_Last_Name__c + ' ' + jpAcct.Contacts[0].Japanese_First_Name__c;
                greeting = jpAcct.Contacts[0].Japanese_Last_Name__c + ' ' + jpAcct.Contacts[0].Japanese_First_Name__c + '様';
            }
			acctIdToJPAcctName.put(jpAcct.Id, acctName);
			acctIdToJPGreeting.put(jpAcct.Id, greeting);
        }
        Map<Id, String> acctIdToInformalGreeting = new Map<Id, String>();
        for (Id id : acctIdToContactNames.keySet()) {
            String informalGreeting = '';                
            if (acctIdToContactNames.get(id).size()>2) {
                List<String> allButLastName = new List<String>();
                for (Integer i=0; i<acctIdToContactNames.get(id).size()-1; i++) {
                    allButLastName.add(acctIdToContactNames.get(id)[i]);
                }
                informalGreeting += String.join(allButLastName, ', ') + ' and ' + acctIdToContactNames.get(id)[acctIdToContactNames.get(id).size()-1];
            }
            else if (acctIdToContactNames.get(id).size()==2) {
                informalGreeting += String.join(acctIdToContactNames.get(id), ' and ');
            }
            else if (acctIdToContactNames.get(id).size()==1) {
                informalGreeting += acctIdToContactNames.get(id)[0];
            }
            acctIdToInformalGreeting.put(id, informalGreeting);
        }
        List<Account> acctsToUpdate = new List<Account>();
        for (Account a : accts) {
            if (acctIdToInformalGreeting.containsKey(a.Id)) {
                a.npo02__Informal_Greeting__c = acctIdToInformalGreeting.get(a.Id);
                if (acctIdToJPAcctName.containsKey(a.Id)) {
                    a.Japanese_Account_Name__c = acctIdToJPAcctName.get(a.Id);
                    a.Japanese_Greeting__c = acctIdToJPGreeting.get(a.Id);
                }
                acctsToUpdate.add(a);
            }
        }
        for (Account jpAcct : jpAccts) {
            if (!acctIds.contains(jpAcct.Id)) {
                jpAcct.Japanese_Account_Name__c = acctIdToJPAcctName.get(jpAcct.Id);
                jpAcct.Japanese_Greeting__c = acctIdToJPGreeting.get(jpAcct.Id);
                acctsToUpdate.add(jpAcct);
            }
        }
        Database.update(acctsToUpdate, false);        
    }
    
    public static void isBeforeLead(List<Lead> leads, Map<Id, Lead> leadsOldMap, Boolean isInsert, Boolean isUpdate) {
        for (Lead l : leads) {
            if (l.Country != null && doNotSolicit.contains(l.Country)) {l.Do_Not_Solicit__c = true;}              
            if (isInsert) { 
                // Lead owner always defaults to generic Room to Read user
                l.OwnerId = !rtrUser.isEmpty() ? rtrUser[0].Id : UserInfo.getUserId();                
                capitalizeFirstAndLastNamesLead(l);
                //subscribeToNewsletterLead(l);
                if (!String.isBlank(l.Phone)) {
                    l.Phone = DataQualityUtilities.formatPhoneNumber(l.Phone);
                }
                if (!String.isBlank(l.Street)) {
                    if (l.Street.toLowercase().equals(l.Street) || l.Street.toUppercase().equals(l.Street)) {
                        l.Street = DataQualityUtilities.capitalizeFirstLetter(l.Street);
                    }
                    l.Street = AddressStandardization.streetAbbreviations(l.Street);                
                }
                if (!String.isBlank(l.City)) {
                    if (l.City.toLowercase().equals(l.City) || l.City.toUppercase().equals(l.City)) {
                        l.City = DataQualityUtilities.capitalizeFirstLetter(l.City);
                    }
                    l.City = AddressStandardization.streetAbbreviations(l.City);
                    if (l.Country == 'Australia' || l.Country == 'AU' || l.Country == 'France' || l.Country == 'FR') {
                        l.City = l.City.toUppercase();
                    }                     
                }
                if (!String.isBlank(l.State)) {
                    if (l.State.toLowercase().equals(l.State) || l.State.toUppercase().equals(l.State)) {
                        l.State = DataQualityUtilities.capitalizeFirstLetter(l.State);
                    }
                    if (l.State.length()<=3) {
                        l.State = l.State.toUppercase();
                    }                    
                    if (AddressStandardization.stateNameToAbbrev.containsKey(l.State)) {
                        l.State = AddressStandardization.stateNameToAbbrev.get(l.State);
                    }
                }
                if (!String.isBlank(l.PostalCode)) {                
                    l.PostalCode = AddressStandardization.streetAbbreviations(l.PostalCode);
                    l.PostalCode = l.PostalCode.toUppercase();
                    if (Pattern.matches('^[0-9]{7}$', l.PostalCode) && (l.Country == 'JP' || l.Country == 'Japan')) {l.PostalCode = l.PostalCode.substring(0,3) + '-' + l.PostalCode.substring(3,7);}               
                }
                if (!String.isBlank(l.Country)) {
                    String countryCode = l.Country.toUpperCase();
                    if (AddressStandardization.ISOCodeToCountryName.containsKey(countryCode)) {
                        l.Country = AddressStandardization.ISOCodeToCountryName.get(countryCode);
                    }              
                }
            }
            else if (Trigger.isUpdate) {
                if (leadsOldMap.get(l.Id).Country != l.Country) {
                    subscribeToNewsletterLead(l);
                }
                if (!String.isBlank(l.Email) && l.Email_Opted_In__c && (leadsOldMap.get(l.Id).Email_Opted_In__c == false || leadsOldMap.get(l.Id).GDPR_Consent_Date__c != l.GDPR_Consent_Date__c)) {
                    l.Newsletter__c = true;
                    l.HasOptedOutOfEmail = false;
                    l.GDPR_Decline_Date__c = null;
                    if (!String.isBlank(l.Country) && !doNotSolicit.contains(l.Country)) {l.Do_Not_Solicit__c = false;}
                }
                if (l.HasOptedOutOfEmail && !leadsOldMap.get(l.Id).HasOptedOutOfEmail) {
                    l.Newsletter__c = false;
                    l.Book_Club__c = false;
                    l.She_Creates_Change__c = false;
                    if (UserInfo.getFirstName() + ' ' + UserInfo.getLastName() == 'Room to Read' && l.EN_Latest_Opt_In_Date__c == null) {l.GDPR_Decline_Date__c = System.today();}
                }
            }
        }        
    }
    
    public static void isAfterLead(List<Lead> leads, Map<Id, Lead> oldLeadsMap, Boolean isInsert, Boolean isUpdate) {
        List<Lead> leadsToProcess = new List<Lead>();
        for (Lead l : leads) {
            if (isInsert || (isUpdate && oldLeadsMap.get(l.Id).Email != l.Email)) {
                leadsToProcess.add(l);
            }
        }
        if (!leadsToProcess.isEmpty() && Limits.getQueueableJobs() == 0) {
            System.debug('Enqueueing job to process new leads');
        	System.enqueueJob(new QueueableProcessNewLeads(leadsToProcess));
        }
    }
 
    public static Contact capitalizeFirstAndLastNamesContact(Contact c) {

        String fullName = !String.isBlank(c.FirstName) ? c.FirstName + ' ' + c.LastName : c.LastName;
        if (fullName.toLowerCase().equals(fullName) || fullName.toUpperCase().equals(fullName) || (c.FirstName!=null && c.FirstName.toLowerCase().equals(c.FirstName)) || c.LastName.toLowerCase().equals(c.LastName) || c.LastName.toUpperCase().equals(c.LastName))  {
            if (!String.isBlank(c.FirstName)) {
                c.FirstName = DataQualityUtilities.capitalizeFirstLetter(c.FirstName);    
            }
            if (!String.isBlank(c.FirstName) && c.FirstName.contains('-')) {
                List<String> hyphenatedNameParts = c.FirstName.split('-');
                List<String> capitalizedNameParts = new List<String>();
                for (String s: hyphenatedNameParts) {
                    s = s.substring(0,1).toUpperCase() + s.substring(1).toLowerCase();
                    capitalizedNameParts.add(s);
                }
                c.FirstName = String.join(capitalizedNameParts,'-');
            }            
            if (!String.isBlank(c.LastName) && c.LastName.contains('-')) {
                List<String> hyphenatedNameParts = c.LastName.split('-');
                List<String> capitalizedNameParts = new List<String>();
                for (String s: hyphenatedNameParts) {
                    s = s.substring(0,1).toUpperCase() + s.substring(1).toLowerCase();
                    capitalizedNameParts.add(s);
                }
                c.LastName = String.join(capitalizedNameParts,'-');
            }
            else if (!String.isBlank(c.LastName)) {
                c.LastName = DataQualityUtilities.capitalizeFirstLetter(c.LastName);
            }
        }
        return c;        
    }
   
    
    public static Lead capitalizeFirstAndLastNamesLead(Lead l) {

        String fullName = l.FirstName!=null ? l.FirstName + ' ' + l.LastName : l.LastName;
        if (fullName.toLowerCase().equals(fullName) || fullName.toUpperCase().equals(fullName) || (l.FirstName!=null && l.FirstName.toLowerCase().equals(l.FirstName)) || l.LastName.toLowerCase().equals(l.LastName) || l.LastName.toUpperCase().equals(l.LastName))  {
            if (l.FirstName!=null) {
                l.FirstName = DataQualityUtilities.capitalizeFirstLetter(l.FirstName);    
            }
            if (!String.isBlank(l.FirstName) && l.LastName.contains('-') && l.FirstName!='-') {
                List<String> hyphenatedNameParts = l.FirstName.split('-');
                List<String> capitalizedNameParts = new List<String>();
                for (String s: hyphenatedNameParts) {
                    s = s.substring(0,1).toUpperCase() + s.substring(1).toLowerCase();
                    capitalizedNameParts.add(s);
                }
                l.FirstName = String.join(capitalizedNameParts,'-');
            }            
            if (!String.isBlank(l.LastName)!=null && l.LastName.contains('-') && l.LastName!='-') {
                List<String> hyphenatedNameParts = l.LastName.split('-');
                List<String> capitalizedNameParts = new List<String>();
                for (String s: hyphenatedNameParts) {
                    s = s.substring(0,1).toUpperCase() + s.substring(1).toLowerCase();
                    capitalizedNameParts.add(s);
                }
                l.LastName = String.join(capitalizedNameParts,'-');
            }
            else if (l.LastName!=null) {
                l.LastName = DataQualityUtilities.capitalizeFirstLetter(l.LastName);
            }
        }
        return l;        
    }
    
    public static Contact subscribeToNewsletterContact(Contact c) {
        if (!String.isBlank(c.Email)) {
            if (!c.npsp__Do_Not_Contact__c && !c.HasOptedOutOfEmail) {
                if (String.isBlank(c.MailingCountry)) {
                    c.Newsletter__c = true;
                }
                else if (!String.isBlank(c.MailingCountry)) {
                    if (GDPRCountries.contains(c.MailingCountry) && c.Email_Opted_In__c) {
                        c.Newsletter__c = true;
                    }
                    else if (!GDPRCountries.contains(c.MailingCountry)) {c.Newsletter__c = true;}
                }   
            }
        }
        else {c.Newsletter__c = false;}
        return c;        
    }

    public static Lead subscribeToNewsletterLead(Lead l) {
        if (!String.isBlank(l.Email)) {
            if (!l.HasOptedOutOfEmail) {
                if (String.isBlank(l.Country)) {
                    l.Newsletter__c = true;
                }
                else if (!String.isBlank(l.Country)) {
                    if (GDPRCountries.contains(l.Country) && l.Email_Opted_In__c) {
                        l.Newsletter__c = true;
                    }
                    else if (!GDPRCountries.contains(l.Country)) {l.Newsletter__c = true;}
                }   
            }
        }
        else {l.Newsletter__c = false;}
        return l;        
    }    
}