@isTest
public class GivingSummaryInUSDControllerTest {
    
    @isTest
    public static void testGivingSummaryInUSDOppsAcctSoftCreds() {
        
        Account householdAcct = new Account(
        RecordTypeId = '0128b000000XLomAAG',
        Name = 'Suzie Q Household',
        Type = 'Household');
        
        Account famFoundation = new Account(
        RecordTypeId = '0128b000000XLomAAG',
        Name = 'Suzie Q Family Foundation',
        Type = 'Family Foundation');
        
		Account friendAcct = new Account(
        RecordTypeId = '0128b000000XLomAAG',
        Name = 'Friend of Suzie',
        Type = 'Household');
        
        List<Account> accts = new List<Account>{householdAcct, famFoundation, friendAcct};
        insert accts;
        
        Contact c = new Contact(
        FirstName = 'Susie',
        LastName = 'Q',
        AccountId = householdAcct.Id);    
        
        Contact friend = new Contact(
        FirstName = 'Friend of',
        LastName = 'Suzie',
        AccountId = friendAcct.Id);
        
        List<Contact> contacts = new List<Contact>{c, friend};
        insert contacts;
        
    	Opportunity donationThisYear = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = householdAcct.Id,
        CurrencyIsoCode = 'AUD',
        Amount = 1000,
        CloseDate = System.today(),
        StageName = 'Closed Won');
        
    	Opportunity donationLastYear = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = householdAcct.Id,
        CurrencyIsoCode = 'AUD',
        Amount = 1000,
        CloseDate = Date.newInstance(System.today().year()-1, System.today().month(), System.today().day()),
        StageName = 'Closed Won');

    	Opportunity donationTwoYearsAgo = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = householdAcct.Id,
        CurrencyIsoCode = 'AUD',
        Amount = 1000,
        CloseDate = Date.newInstance(System.today().year()-2, System.today().month(), System.today().day()),
        StageName = 'Closed Won'); 
        
        Opportunity majorGiftThisYear = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        CurrencyIsoCode = 'USD',
        Amount = 5000,
        CloseDate = System.today(),
        StageName = 'Closed Won');
        
        Opportunity majorGiftLastYear = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        CurrencyIsoCode = 'AUD',
        Amount = 7500,
        CloseDate = Date.newInstance(System.today().year()-1, System.today().month(), System.today().day()),
        StageName = 'Closed Won');  
        
        Opportunity majorGiftTwoYearsAgo = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        CurrencyIsoCode = 'AUD',
        Amount = 7500,
        CloseDate = Date.newInstance(System.today().year()-2, System.today().month(), System.today().day()),
        StageName = 'Closed Won');                

        List<Opportunity> opps = new List<Opportunity>{donationThisYear, donationLastYear, donationTwoYearsAgo, majorGiftThisYear, majorGiftLastYear, majorGiftTwoYearsAgo};
        insert opps;
        
        npsp__Account_Soft_Credit__c acctSoftCredit1 = new npsp__Account_Soft_Credit__c(
        npsp__Opportunity__c = majorGiftThisYear.Id,
        npsp__Account__c = householdAcct.Id,
        CurrencyIsoCode = 'USD',
        npsp__Amount__c = 5000,
        npsp__Role__c = 'Donation Source');
        
        npsp__Account_Soft_Credit__c acctSoftCredit2 = new npsp__Account_Soft_Credit__c(
        npsp__Opportunity__c = majorGiftLastYear.Id,
        npsp__Account__c = householdAcct.Id,
        CurrencyIsoCode = 'AUD',
        npsp__Amount__c = 7500,
        npsp__Role__c = 'Donation Source'); 
        
        npsp__Account_Soft_Credit__c acctSoftCredit3 = new npsp__Account_Soft_Credit__c(
        npsp__Opportunity__c = majorGiftTwoYearsAgo.Id,
        npsp__Account__c = householdAcct.Id,
        CurrencyIsoCode = 'AUD',
        npsp__Amount__c = 7500,
        npsp__Role__c = 'Donation Source');
        
        List<npsp__Account_Soft_Credit__c> acctSoftCredits = new List<npsp__Account_Soft_Credit__c>{acctSoftCredit1, acctSoftCredit2, acctSoftCredit3};
		insert acctSoftCredits;

		Test.startTest();
        GivingSummary summary = GivingSummaryInUSDController.getGivingSummary(householdAcct.Id);
        Test.stopTest();
        
	}
    
    @isTest
    public static void testGivingSummaryConversionController() {

        Account householdAcct = new Account(
        RecordTypeId = '0128b000000XLomAAG',
        Name = 'Suzie Q Household',
        Type = 'Household');
        
        Account famFoundation = new Account(
        RecordTypeId = '0128b000000XLomAAG',
        Name = 'Suzie Q Family Foundation',
        Type = 'Family Foundation');        
        
		Account friendAcct = new Account(
        RecordTypeId = '0128b000000XLomAAG',
        Name = 'Friend of Suzie',
        Type = 'Household');
        
        List<Account> accts = new List<Account>{householdAcct, friendAcct};
        insert accts;
        
        Contact c = new Contact(
        FirstName = 'Susie',
        LastName = 'Q',
        AccountId = householdAcct.Id);    
        
        Contact friend = new Contact(
        FirstName = 'Friend of',
        LastName = 'Suzie',
        AccountId = friendAcct.Id); 
        
        List<Contact> contacts = new List<Contact>{c, friend};
        insert contacts;        
        
		Campaign p2p = new Campaign(
        Name = 'Suzie Q\'s Fundraising Page',
        RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Peer to Peer').getRecordTypeId(),
		Status = 'In Progress');
        insert p2p;
        
        Opportunity donationToSuziePage = new Opportunity(
        Name = 'Donation',
        AccountId = friendAcct.Id,
        npsp__Primary_Contact__c = friend.Id,
        CampaignId = p2p.Id,
        CurrencyIsoCode = 'AUD',
        Amount = 100,
        CloseDate = System.today(),
        StageName = 'Closed Won');
        insert donationToSuziePage;
        
        npsp__Partial_Soft_Credit__c psc = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = donationToSuziePage.Id,
        npsp__Contact__c = c.Id,
        CurrencyIsoCode = 'AUD',
        npsp__Amount__c = 100);
        insert psc;
        
        Opportunity donationToSuziePageLastYr = new Opportunity(
        Name = 'Donation',            
        AccountId = friendAcct.Id,
        npsp__Primary_Contact__c = friend.Id,
        CampaignId = p2p.Id,
        CurrencyIsoCode = 'AUD',
        Amount = 100,
        CloseDate = Date.newInstance(System.today().year()-1, System.today().month(), System.today().day()),
        StageName = 'Closed Won');
        insert donationToSuziePageLastYr;
        
        npsp__Partial_Soft_Credit__c psc2 = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = donationToSuziePageLastYr.Id,
        npsp__Contact__c = c.Id,
        CurrencyIsoCode = 'AUD',
        npsp__Amount__c = 100);
        insert psc2;
        
        Opportunity majorGiftThisYear = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        CurrencyIsoCode = 'AUD',
        Amount = 5000,
        CloseDate = System.today(),
        StageName = 'Closed Won');
        
        Opportunity majorGiftLastYear = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        CurrencyIsoCode = 'AUD',
        Amount = 7500,
        CloseDate = Date.newInstance(System.today().year()-1, System.today().month(), System.today().day()),
        StageName = 'Closed Won');  
        
        Opportunity majorGiftTwoYearsAgo = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        CurrencyIsoCode = 'AUD',
        Amount = 7500,
        CloseDate = Date.newInstance(System.today().year()-2, System.today().month(), System.today().day()),
        StageName = 'Closed Won');
        
        List<Opportunity> opps = new List<Opportunity>{majorGiftThisYear, majorGiftLastYear, majorGiftTwoYearsAgo};
        insert opps;
        
        npsp__Partial_Soft_Credit__c psc3 = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = majorGiftThisYear.Id,
        npsp__Contact__c = c.Id,
        CurrencyIsoCode = 'AUD',
        npsp__Amount__c = 5000);

        npsp__Partial_Soft_Credit__c psc4 = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = majorGiftLastYear.Id,
        npsp__Contact__c = c.Id,
        CurrencyIsoCode = 'AUD',
        npsp__Amount__c = 7500); 
        
        npsp__Partial_Soft_Credit__c psc5 = new npsp__Partial_Soft_Credit__c(
        npsp__Opportunity__c = majorGiftTwoYearsAgo.Id,
        npsp__Contact__c = c.Id,
        CurrencyIsoCode = 'AUD',
        npsp__Amount__c = 7500);        
        
        List<npsp__Partial_Soft_Credit__c> contactSoftCredsFamFdn = new List<npsp__Partial_Soft_Credit__c>{psc3, psc4, psc5};
		insert contactSoftCredsFamFdn;
        
        Test.startTest();
        GivingSummary summary = GivingSummaryInUSDController.getGivingSummary(householdAcct.Id);
        Test.stopTest();
        
    }
    

}