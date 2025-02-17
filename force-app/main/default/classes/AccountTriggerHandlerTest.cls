@isTest
public class AccountTriggerHandlerTest {
    
    @isTest
    public static void testBeforeInsertCountryRequired() {
        Account organization = new Account(
        Name = 'Atlassian Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Foundation',
        CurrencyIsoCode = 'AUD');
        
        try {
        	insert organization;
        }
        catch (Exception e) {
            e.getMessage();
        }
    }

    @isTest
    public static void testBeforeUpdateLargestGiftAmount() {
    
        Test.startTest();
        
        Account organization = new Account(
        Name = 'Atlassian Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        BillingCountry = 'Australia',
        Type = 'Foundation',
        CurrencyIsoCode = 'AUD');
        insert organization;
    
        Opportunity majorGift = new Opportunity(
        Name = 'Donation',
        AccountId = organization.Id,
        RecordTypeId = '0128b000000XLooAAG',
        Amount = 10000,
        CurrencyIsoCode = 'AUD',
        StageName = 'Closed Won',
        CloseDate = System.today()-7);
        insert majorGift;
        
        Opportunity majorGift2 = new Opportunity(
        Name = 'Donation',
        AccountId = organization.Id,
        RecordTypeId = '0128b000000XLooAAG',
        Amount = 20000,
        CurrencyIsoCode = 'AUD',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert majorGift2;
        
        Test.stopTest();
        
        System.assertEquals(20000,[SELECT Id, HPC_Value__c FROM Account WHERE Id = :organization.Id][0].HPC_Value__c);        
    }
    
    @isTest
    public static void testAfterTriggerHandler() {
        
        Test.startTest();
        
        Account a = new Account(
        Name = 'Household',
		RecordTypeId = '0128b000000XLomAAG',             
        Type = 'Household',
        BillingCountry = 'United Kingdom');
        insert a;
        
        Contact c = new Contact(
        AccountId = a.Id,
        Salutation = 'Ms.',
        FirstName = 'Suzie',
        LastName = 'Q',
        Email = 'suzie.q@myemail.com');
        insert c;
        
        c.engaging__EN_Last_Modified_Date__c = null;
        update c;
        
        a.EN_Push__c = false;
        update a;
        a.EN_Push__c = true;
        update a;
        
        Opportunity donation = new Opportunity(
        Name = 'Donation',
        AccountId = a.Id,
        RecordTypeId = '0128b000000XLooAAG',
        Amount = 100,
        CurrencyIsoCode = 'GBP',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert donation;
        
        Test.stopTest();
        
        System.assertEquals('GBP', [SELECT Id, CurrencyIsoCode FROM Contact WHERE Id = :c.Id][0].CurrencyIsoCode);
    }
    
    @isTest
    public static void testOrgAddressMissingCountry() {

        Test.startTest();
        
        Account organization = new Account(
        Name = 'Atlassian Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        BillingStreet = 'level 6 / 341 george street',
        BillingCity = 'sydney',
        BillingState = 'NSW',
        BillingPostalCode = '2000',
        Type = 'Foundation',
        CurrencyIsoCode = 'AUD');
        
        try {
        	insert organization;
        }
        catch (Exception e) {
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
        
    }
    
}