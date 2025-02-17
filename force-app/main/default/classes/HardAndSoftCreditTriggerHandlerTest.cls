@isTest
public class HardAndSoftCreditTriggerHandlerTest {
    
    @isTest(SeeAllData=true)
    public static void testDirectOppOwnerChangeErrorHandling() {
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];        
        
		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertToHex(b);
		String uid = h.SubString(0,8);        
		User runningUser = new User(
            Alias = uid,
            Email = uid + '@roomtoread.org', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Running', 
            LastName='User', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = prof.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName = uid + '@roomtoread.org'            
        );
		insert runningUser;        
        
        Opportunity o = [SELECT Id FROM Opportunity WHERE Owner.Name = 'Room to Read' LIMIT 1];
        o.OwnerId = runningUser.Id;
        try {
            update o;
        }
        catch (Exception e) {
            e.getMessage();
        }
    }
    
    @isTest(SeeAllData=true)
    public static void testBeforePartialSoftCreditInsertOrUpdate() {

		Opportunity o = [SELECT Id, Name, AccountId, npsp__Primary_Contact__c, CurrencyIsoCode, Amount FROM Opportunity WHERE Id = '0068b00001NNfJ5AAL' LIMIT 1];

		npsp__Partial_Soft_Credit__c softCreditSameAcct = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = o.Id,
        npsp__Contact__c = o.npsp__Primary_Contact__c,
        npsp__Amount__c = o.Amount,
        CurrencyIsoCode = o.CurrencyIsoCode);
	
        try {
            insert softCreditSameAcct;
        }
        catch (Exception e) {
            e.getMessage();
        }        
        
        Opportunity o1 = [SELECT Id, Name, AccountId, CurrencyIsoCode, Amount FROM Opportunity WHERE Id = '0068b00001MxLYNAA3' LIMIT 1];
        
		npsp__Partial_Soft_Credit__c duplicateSoftCredit = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = o1.Id,
        npsp__Contact__c = o.npsp__Primary_Contact__c,
        npsp__Amount__c = o1.Amount,
        CurrencyIsoCode = o1.CurrencyIsoCode);
        
        try {
			insert duplicateSoftCredit;
        }
        catch (Exception e) {
            e.getMessage();
        }
    }
    
    @isTest
    public static void testBeforeAcctSoftCreditInsertOrUpdate() {

        Account household = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household');
        insert household;
        
        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = household.Id);
        insert c;
        
        Account famFoundation = new Account(
        Name = 'Suzie Q Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United Kingdom');
        insert famFoundation;
        
        Opportunity o = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = famFoundation.Id,
        Amount = 10000,
        CurrencyIsoCode = 'GBP',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert o;

		npsp__Account_Soft_Credit__c selfCred = new npsp__Account_Soft_Credit__c(
        npsp__Account__c = famFoundation.Id,
        npsp__Opportunity__c = o.Id,
        npsp__Amount__c = 10000,
        CurrencyIsoCode = 'GBP',
        npsp__Role__c = 'Soft Credit');
        
        try {
			insert selfCred; 
        }
        catch (Exception e) {
            e.getMessage();
        }
        
		npsp__Partial_Soft_Credit__c contactSoftCredit = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = o.Id,
        npsp__Contact__c = c.Id,
        npsp__Amount__c = 10000,
        CurrencyIsoCode = 'GBP');
		insert contactSoftCredit;
        
        contactSoftCredit.Amount_in_USD_Dated__c = null;
        update contactSoftCredit;

		npsp__Account_Soft_Credit__c donorHouseholdCred = new npsp__Account_Soft_Credit__c(
        npsp__Account__c = household.Id,
        npsp__Opportunity__c = o.Id,
        npsp__Amount__c = 10000,
        CurrencyIsoCode = 'GBP',
        npsp__Role__c = 'Soft Credit');       
        
        try {
            insert donorHouseholdCred;
        }
        catch (Exception e) {
            e.getMessage();
        }
        
        delete contactSoftCredit;
        
		npsp__Account_Soft_Credit__c acctSoftCred = new npsp__Account_Soft_Credit__c(
        npsp__Account__c = household.Id,
        npsp__Opportunity__c = o.Id,
        Percent__c = 100,
        npsp__Amount__c = 10000,
        CurrencyIsoCode = 'GBP',
        npsp__Role__c = 'Soft Credit');
        insert acctSoftCred;
        
        acctSoftCred.Amount_in_USD_Dated__c = null;
        update acctSoftCred;
        
		npsp__Account_Soft_Credit__c dupeAcctSoftCred = new npsp__Account_Soft_Credit__c(
        npsp__Account__c = household.Id,
        npsp__Opportunity__c = o.Id,
        npsp__Amount__c = 10000,
        CurrencyIsoCode = 'GBP',
        npsp__Role__c = 'Soft Credit');       

        try {
            insert dupeAcctSoftCred;
        }
        catch (Exception e) {
            e.getMessage();
        }
        
    }
    
    @isTest(SeeAllData=true)
    public static void testRecalcOfHardAndSoftCreditAmts() {
        List<Opportunity> opps = [SELECT Id, CurrencyIsoCode, Amount, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c,
                                  AccountId, Account.CurrencyIsoCode
                                  FROM Opportunity
                                  WHERE Id = '0068b00001Mxb1eAAB'];
        Test.startTest();
        HardAndSoftCreditTriggerHandler.recalculateSoftCreditAmtsInUSDAndAcctCurrencies(opps);
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    public static void testCopyAllocInfoToPmts() {
        Opportunity o = [SELECT Id FROM Opportunity WHERE Id = '0068b00001MwxaFAAR'];
        o.Link_to_Supporting_Docs_for_GAU__c = null;
        update o;
        delete [SELECT Id FROM npsp__Allocation__c WHERE npsp__Payment__r.npe01__Opportunity__c = '0068b00001MwxaFAAR'];
        o.Link_to_Supporting_Docs_for_GAU__c = 'https://roomtoread.sharepoint.com/:b:/s/AllRTR/GO/FIN/EW7dsHOKAqxDvBXYYSpVRisBbH-aEKKXYE_wN6L2aKN_HQ?e=IKcKcK';
    	update o;        
    } 
    
    @isTest(SeeAllData=true) 
    public static void testSetAcctCurrency() {
        List<Account> accts = [SELECT Id, Name, CurrencyIsoCode FROM Account WHERE CurrencyIsoCode != 'USD' AND RecordType.Name = 'Household Account' AND npo02__TotalOppAmount__c > 0 AND Total_Partial_Soft_Credits__c > 0 AND Total_Account_Soft_Credits__c > 0 LIMIT 5];
        List<Contact> partialCredsOnly = [SELECT Id, AccountId, Name, CurrencyIsoCode FROM Contact WHERE AccountId NOT IN (SELECT AccountId FROM Opportunity) AND Id IN (SELECT npsp__Contact__c FROM npsp__Partial_Soft_Credit__c) LIMIT 2];
        List<Account> acctCredsOnly = [SELECT Id, Name, CurrencyIsoCode FROM Account WHERE CurrencyIsoCode != 'USD' AND RecordType.Name = 'Organization' AND Id NOT IN (SELECT AccountId FROM Opportunity) AND Total_Account_Soft_Credits__c > 0 LIMIT 2];
        if (!accts.isEmpty()) {
            accts[0].CurrencyIsoCode = 'USD';
            update accts[0];
        }
        Set<Id> acctIds = new Set<Id>();
		Set<Id> contactIds = new Set<Id>();
        for (Account a : accts) {
            acctIds.add(a.Id);
        }
        for (Contact c : partialCredsOnly) {
            contactIds.add(c.Id);
            acctIds.add(c.AccountId);
        }
        for (Account a : acctCredsOnly) {
            acctIds.add(a.Id);
        }        
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id IN :acctIds];
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }
  
        Test.startTest();
        HardAndSoftCreditTriggerHandler.setAcctCurrency(contactIds, acctIds);
        Test.stopTest();
    }
    
    @isTest
    public static void testAfterHardOrSoftCreditInsert() {
        
        Account a = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household');
                
        Account a2 = new Account(
        Name = 'Suzie Q Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United Kingdom');
        
        List<Account> accts = new List<Account>{a, a2};
        insert accts;
        
        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = a.Id);        
        insert c;
        
        Opportunity o = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = a.Id,
        Amount = 100,
        CurrencyIsoCode = 'GBP',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert o;        

        Opportunity o1 = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = a2.Id,
        Amount = 1000,
        CurrencyIsoCode = 'HKD',
        StageName = 'Closed Won',
        CloseDate = System.today()-7);
        
        Opportunity o2 = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = a2.Id,
        Amount = 1000,
        CurrencyIsoCode = 'HKD',
        StageName = 'Closed Won',
        CloseDate = System.today()-14);
        
        List<Opportunity> opps = new List<Opportunity>{o1, o2};
        insert opps;

        npsp__Partial_Soft_Credit__c partialSoftCredit = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = o1.Id,
        npsp__Contact__c = c.Id,
        CurrencyIsoCode = 'HKD',
        npsp__Amount__c = 1000);
        insert partialSoftCredit;
        
        npsp__Account_Soft_Credit__c acctSoftCred = new npsp__Account_Soft_Credit__c(
        npsp__Opportunity__c = o2.Id,
        npsp__Account__c = a.Id,
        npsp__Role__c = 'Soft Credit',
        npsp__Amount__c = 1500,
        CurrencyIsoCode = 'GBP');
        insert acctSoftCred;
        
        System.assertEquals('HKD', [SELECT Id, CurrencyIsoCode FROM Contact WHERE Id = :c.Id][0].CurrencyIsoCode);
    }
    
    @isTest
    public static void testGivingArmDonationsHandler() {
        
        Account famFoundation = new Account(
        Name = 'Q Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United States');
        insert famFoundation;
        
        Account household = new Account(
        Name = 'Suzy and John Q Household',
        RecordTypeId = '0128b000000XLomAAG',    
        Type = 'Household');
        insert household;
        
        Contact c1 = new Contact(
        FirstName = 'Suzy',
        LastName = 'Q',
        AccountId = household.Id);
        
        Contact c2 = new Contact(
        FirstName = 'John',
        LastName = 'Q',
        AccountId = household.Id);
        
        List<Contact> contacts = new List<Contact>{c1, c2};
        insert contacts;
        
        Opportunity openMajorGift = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        AccountId = household.Id,
        CurrencyIsoCode = 'USD',
        Amount = 10000,
        StageName = 'Verbal Commitment',
        CloseDate = System.today()+30);
        insert openMajorGift;
        
        Account a = [SELECT Id, Count_of_Open_Grants_Major_Gifts__c FROM Account WHERE Id = :household.Id];
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
		User rm = new User(
			Alias = 'rm', 
            Email='relationship.manager@roomtoread.org', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Relationship', 
            LastName='Manager', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = prof.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='npsp.relationship.manager@roomtoread.org'       
        );        
               
		User pp = new User(
            Alias = 'primPlay',
            Email = 'primary.player@roomtoread.org', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Running', 
            LastName='User', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = prof.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName = 'npsp.primary.player@roomtoread.org'            
        );
        
		User tm = new User(
            Alias = 'tm',
            Email = 'team.member@roomtoread.org', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Team', 
            LastName='Member', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = prof.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName = 'npsp.team.member@roomtoread.org'            
        );

        List<User> users = new List<User>{rm, pp, tm};
        insert users;
        
        AccountTeamMember relationshipMgr = new AccountTeamMember(
        AccountId = household.Id,
        UserId = rm.Id,
        TeamMemberRole = 'Relationship Manager',
        Start_Date__c = System.today()-30,
        End_Date__c = null);
        
        AccountTeamMember primaryPlayer = new AccountTeamMember(
        AccountId = household.Id,
        UserId = pp.Id,
        TeamMemberRole = 'Primary Player',
        Start_Date__c = System.today()-30,
        End_Date__c = null); 
        
        AccountTeamMember teamMember = new AccountTeamMember(
        AccountId = household.Id,
        UserId = tm.Id,
        TeamMemberRole = 'Team Member',
        Start_Date__c = System.today()-30,
        End_Date__c = null);         
        
        List<AccountTeamMember> ATMs = new List<AccountTeamMember>{relationshipMgr, primaryPlayer, teamMember};
        insert ATMs;
        
		household.Updated_Via_Apex_Trigger__c = true;
		household.Current_Relationship_Manager__c = rm.Id;
		update household;        
        
        npe5__Affiliation__c affiliation1 = new npe5__Affiliation__c(
        RecordTypeId = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByName().get('Affiliation').getRecordTypeId(),
        npe5__Contact__c = c1.Id,
        npe5__Organization__c = famFoundation.Id,
        Type__c = 'Giving Arm');
        
        npe5__Affiliation__c affiliation2 = new npe5__Affiliation__c(
        RecordTypeId = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByName().get('Affiliation').getRecordTypeId(),
        npe5__Contact__c = c2.Id,
        npe5__Organization__c = famFoundation.Id,
        Type__c = 'Giving Arm');        
        
        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c>{affiliation1, affiliation2};
       	insert affiliations;
        
        Opportunity o1 = new Opportunity(
        Name = 'Donation',
		RecordTypeId = '0128b000000XLooAAG',            
        AccountId = famFoundation.Id,
        Amount = 10000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today()-7,
        StageName = 'Closed Won',
        Count_of_Gift_Solicitors__c = 0);
        
        Opportunity o2 = new Opportunity(
        Name = 'Donation',
		RecordTypeId = '0128b000000XLooAAG',            
        AccountId = famFoundation.Id,
        Amount = 1000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today()-7,
        StageName = 'Closed Won',
        Count_of_Gift_Solicitors__c = 0);

        List<Opportunity> opps = new List<Opportunity>{o1, o2};
        insert opps;
        
        o1.RecordTypeId = '0128b000000XLokAAG';
        update o1;
        
    }
    
    @isTest
    public static void testAlertGBOToGivingArmCreditNoRM() {
        
        Account famFoundation = new Account(
        Name = 'Smith Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United States');
        insert famFoundation;
        
        Account household = new Account(
        Name = 'John Smith Household',
        RecordTypeId = '0128b000000XLomAAG',    
        Type = 'Household');
        insert household;
        
        Contact c = new Contact(
        FirstName = 'John',
        LastName = 'Smith',
        AccountId = household.Id);
        insert c;         
        
        npe5__Affiliation__c affiliation = new npe5__Affiliation__c(
        RecordTypeId = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByName().get('Affiliation').getRecordTypeId(),
        npe5__Contact__c = c.Id,
        npe5__Organization__c = famFoundation.Id,
        Type__c = 'Giving Arm');
        insert affiliation;
        
        Opportunity majorGift = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        AccountId = household.Id,
        Amount = 10000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today()+30,
        StageName = 'Verbal Commitment');
        insert majorGift;
        
        Account a = [SELECT Id, Count_of_Open_Grants_Major_Gifts__c FROM Account WHERE Id = :household.Id];        
        
        Opportunity donation = new Opportunity(
        Name = 'Donation',
		RecordTypeId = '0128b000000XLooAAG',            
        AccountId = famFoundation.Id,
        Amount = 10000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today(),
        StageName = 'Closed Won');
        insert donation;       
        
    }
    
    @isTest
    public static void testGivingArmCreditMoreThanOneHousehold() {

        Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
		User rm = new User(
			Alias = 'rm', 
            Email='relationship.manager@roomtoread.org', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Relationship', 
            LastName='Manager', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = prof.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='npsp.relationship.manager@roomtoread.org'       
        );
        insert rm;
        
        Account famFoundation = new Account(
        Name = 'Smith Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United States',
		Updated_Via_Apex_Trigger__c = true,
        Current_Relationship_Manager__c = rm.Id);        
        
        Account household = new Account(
        Name = 'John Smith Household',
        RecordTypeId = '0128b000000XLomAAG',    
        Type = 'Household');
        
        Account household2 = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',    
        Type = 'Household');
        
        List<Account> accts = new List<Account>{household, household2, famFoundation};
        insert accts;
        
        Contact c = new Contact(
        FirstName = 'John',
        LastName = 'Smith',
        AccountId = household.Id);        
        
        Contact c2 = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = household2.Id);
        
        List<Contact> contacts = new List<Contact>{c, c2};
        insert contacts;
       
        npe5__Affiliation__c affiliation = new npe5__Affiliation__c(
        RecordTypeId = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByName().get('Affiliation').getRecordTypeId(),
        npe5__Contact__c = c.Id,
        npe5__Organization__c = famFoundation.Id,
        Type__c = 'Giving Arm');        

        npe5__Affiliation__c affiliation2 = new npe5__Affiliation__c(
        RecordTypeId = Schema.SObjectType.npe5__Affiliation__c.getRecordTypeInfosByName().get('Affiliation').getRecordTypeId(),
        npe5__Contact__c = c2.Id,
        npe5__Organization__c = famFoundation.Id,
        Type__c = 'Giving Arm');
        
        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c>{affiliation, affiliation2};
        insert affiliations;
        
        Opportunity majorGift = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        AccountId = household2.Id,
        Amount = 20000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today()+30,
        StageName = 'Verbal Commitment');
        insert majorGift;
        
        Test.startTest();
 
        majorGift.npsp__Primary_Contact__c = null;
        majorGift.npe01__Contact_Id_for_Role__c = c2.Id;
        majorGift.AccountId = famFoundation.Id;
        majorGift.StageName = 'Closed Won';
        update majorGift;
        
        Opportunity donation = new Opportunity(
        Name = 'Donation',
		RecordTypeId = '0128b000000XLooAAG',            
        AccountId = famFoundation.Id,
        Amount = 10000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today(),
        StageName = 'Closed Won');
        insert donation;          
        
        famFoundation.Updated_Via_Apex_Trigger__c = true;
        famFoundation.Current_Relationship_Manager__c = null;
        update famFoundation;
        
        Opportunity donation2 = new Opportunity(
        Name = 'Donation',
		RecordTypeId = '0128b000000XLooAAG',            
        AccountId = famFoundation.Id,
        Amount = 10000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today(),
        StageName = 'Closed Won');
        insert donation2;        
        
		Test.stopTest();        
    }    
    
}