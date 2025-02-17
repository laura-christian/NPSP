@isTest
public class ContactAndLeadTriggerHandlerTest {

   	@isTest
    public static void testBeforeTriggerContact() {
        
        Contact c = new Contact(
        Salutation = 'Ms',
        FirstName = 'SUSANNA',
        LastName = 'QUINCY',
        Title = 'Ms.',
        npe01__HomeEmail__c = 'suzie.q@test.com',
        npe01__WorkEmail__c = 'suzie.q@test.com',
        npe01__Preferred_Email__c = 'Work',
        Email = 'suzie.q@test.com',
        MailingCountry = 'US',
        MobilePhone = '9999999999',
        npe01__WorkPhone__c = '9999999999',
        HomePhone = '9999999999',
        OtherPhone = '9999999999',
        AssistantPhone = '9999999999');
        insert c;
        
        c.npe01__AlternateEmail__c = 'suzie.q@test.com';
        c.MailingCountry = 'United Kingdom';
        update c;
        
        c.npe01__WorkEmail__c = 'suzie.q@acme.com';
        c.npe01__AlternateEmail__c = 'suzie.q@acme.com';
        c.Email_Opted_In__c = true;
        c.GDPR_Consent_Date__c = System.today()-7;
        update c;
        
        c.npsp__Do_Not_Contact__c = true;
        update c;
        
        c.GDPR_Consent_Date__c = System.today();
        update c;
        
    }
    
    @isTest
    public static void testErrorContactAddedToOrgAcct() {
        
        Account org = new Account(
        RecordTypeId = '0128b000000XLonAAG',
        Name = 'Halcyon Communications',
        Type = 'Corporation',
        BillingCountry = 'United States');
        insert org;
        
        Contact c = new Contact(
        FirstName = 'Mary Ann',
        LastName = 'Singleton',
        AccountId = org.Id,
        npe01__Preferred_Email__c = 'Work',
        npe01__WorkEmail__c = 'mary.ann@halcyoncommunications.com');
        try {
        	insert c;
        }
        catch (Exception e) {
            e.getMessage();
        }
        
    }
    
    
    @isTest
    public static void testAfterTriggerContact() {

        Account a = new Account(
        Name = 'Household',
		RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household');
        insert a;
        
        Contact c1 = new Contact(
        AccountId = a.Id,
        Salutation = 'Ms',
        FirstName = 'marie-eve',
        LastName = 'dubois-picard',
        Email = 'marie-eve@test.com',
        MailingCountry = 'CA');
        insert c1;

		Contact c2 = new Contact(
        AccountId = a.Id,
        FirstName = 'JEAN-LUC',
        LastName = 'PICARD',
        Nickname__c = 'JP');
        insert c2;
        
        Contact c3 = new Contact(
        AccountId = a.Id,
        FirstName = 'Jean-Luc',
        LastName = 'Picard',
        Suffix = 'Jr.',
        Nickname__c = 'JP Jr.');
        insert c3;

        System.debug([SELECT Id, npo02__Informal_Greeting__c FROM Account WHERE Id = :a.Id][0].npo02__Informal_Greeting__c);
        
    }
    
    @isTest
    public static void testJapaneseAcctNameAndGreeting() {

        Account a = new Account(
        Name = 'Household',
		RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household');
        insert a;
        
        Contact c1 = new Contact(
        AccountId = a.Id,
        FirstName = 'Yu',
        LastName = 'Sato',
        Japanese_First_Name__c = '悠',
        Japanese_Last_Name__c = '佐藤',
        MailingCountry = 'JP');
        insert c1;

		Contact c2 = new Contact(
        AccountId = a.Id,
        FirstName = 'Aoi',
        LastName = 'Sato',
        Japanese_First_Name__c = '碧海',
        Japanese_Last_Name__c = '佐藤');
        insert c2;

        System.assertEquals('佐藤 悠、碧海', [SELECT Id, Japanese_Account_Name__c FROM Account WHERE Id = :a.Id][0].Japanese_Account_Name__c);
        
    }    
    
    @isTest
    public static void testBeforeTriggerLead() {
        
        Lead l = new Lead(
        FirstName = 'jean-jacques',
        LastName = 'LEVI-STRAUSS',
        Company = 'Household',
        Email = 'jj@email.com',
        Street = '28 rue de trévise',
        City = 'PARIS',
        PostalCode = '75009',
        Country = 'FR');
		insert l;
        
        l.Email_Opted_In__c = true;
        l.GDPR_Consent_Date__c = System.today()-7;
        update l;
        
        l.HasOptedOutOfEmail = true;
        update l;
        
        Lead l2 = new Lead(
        FirstName = 'SUZIE',
        LastName = 'Q',
        Company = 'Household',
        Phone = '9999999999',
		Street = '605 Bourbon Street',
        City = 'New Orleans',
        State = 'la',
        PostalCode = '70130',
        Country = 'United States');
        insert l2;
        
        l2.Country = null;
        try {
        	update l2;
        }
        catch (Exception e) {
            e.getMessage();
        }

        System.assertEquals(false, [SELECT Id, Newsletter__c FROM Lead WHERE Id = :l.Id][0].Newsletter__c);
        
    }
    
    @isTest
    public static void testLeadAddressMissingCountry() {
        
        Lead l = new Lead(
        FirstName = 'Susanna',
        LastName = 'Queue',
        Company = 'Susanna Queue Household',
        Street = '123 Main Street',
        City = 'Anytown',
        State = 'CA');
        
        try {
            insert l;
        }
        catch (Exception e) {
            e.getMessage();
        }
        
    }    
    
    @isTest
    public static void testQueueableMatchOnPersonalEmail() {

        Contact c1 = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        npe01__HomeEmail__c = 'suzie.q@email.com',
        npe01__WorkEmail__c = 'suzie@acmecorp.com',
        npe01__AlternateEmail__c = 'suziecutie@altemail.com',
        npe01__Preferred_Email__c = 'Work');
        insert c1;
        
        Test.startTest();
        
        Lead l1 = new Lead(
        FirstName = 'Susanne',
        LastName = 'Q',
        Company = 'Susanne Q Household',
        Email = 'suzie.q@email.com');
        insert l1;
        
        Test.stopTest();

        System.assertEquals('suzie.q@email.com', [SELECT Id, Email FROM Contact WHERE FirstName = 'Suzie'][0].Email);
    }
    
    @isTest
    public static void testQueueableMatchOnWorkEmail() {

        Contact c1 = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        npe01__HomeEmail__c = 'suzie.q@email.com',
        npe01__WorkEmail__c = 'suzie@acmecorp.com',
        npe01__AlternateEmail__c = 'suziecutie@altemail.com',
        npe01__Preferred_Email__c = 'Personal');
        insert c1;
        
        Test.startTest();
        
        Lead l2 = new Lead(
        FirstName = 'Sue',
        LastName = 'Q',
        Company = 'Sue Q Household',
        Email = 'suzie@acmecorp.com');
        insert l2;
        
        Test.stopTest();

        System.assertEquals('suzie@acmecorp.com', [SELECT Id, Email FROM Contact WHERE FirstName = 'Suzie'][0].Email);
    }

    @isTest
    public static void testQueueableMatchOnAltEmail() {

        Contact c1 = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        npe01__HomeEmail__c = 'suzie.q@email.com',
        npe01__WorkEmail__c = 'suzie@acmecorp.com',
        npe01__AlternateEmail__c = 'suziecutie@altemail.com',
        npe01__Preferred_Email__c = 'Work');
        insert c1;
        
        Test.startTest();
        
        Lead l3 = new Lead(
        FirstName = 'Suzie',
        LastName = 'Q',
        Company = 'Suzie Q Household',
        Email = 'suziecutie@altemail.com');
        insert l3;
        
        Test.stopTest();

        System.assertEquals('suziecutie@altemail.com', [SELECT Id, Email FROM Contact WHERE FirstName = 'Suzie'][0].Email);
    }    
    
}