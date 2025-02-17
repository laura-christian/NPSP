@isTest
public class BatchLinkMatchingGiftsTest {

    @isTest
    public static void testMatchingGiftLinking() {
        
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

        Account employer = new Account(
        Name = 'Acme Corp.',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Corporation',
        BillingCountry = 'United States');
        insert employer;
        
        Opportunity employeeGift = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = household.Id,
        Amount = 25,
        CurrencyIsoCode = 'USD',
        StageName = 'Closed Won',
        CloseDate = System.today(),
        Benevity_Transaction_Id__c = '57AQAWC8NV');
        
        Opportunity employerMatch = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = employer.Id,
        Amount = 25,
        CurrencyIsoCode = 'USD',
        StageName = 'Closed Won',
        CloseDate = System.today(),
        Benevity_Transaction_Id__c = '57AQAWC8NV'); 
        
        Opportunity employerMatch2 = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = employer.Id,
        Amount = 100,
        CurrencyIsoCode = 'USD',
        StageName = 'Closed Won',
        CloseDate = System.today(),
        Benevity_Transaction_Id__c = '59FE9AUPAR');
        
        List<Opportunity> opps = new List<Opportunity>{employeeGift, employerMatch, employerMatch2};
        insert opps;
        
        Test.startTest();
        BatchLinkMatchingGifts.linkMatchingGifts();
        Test.stopTest();
        
        System.assertEquals([SELECT Id, npsp__Matching_Gift_Account__c FROM Opportunity WHERE AccountId = :household.Id][0].npsp__Matching_Gift_Account__c, employer.Id);
        
        
    }
    
}