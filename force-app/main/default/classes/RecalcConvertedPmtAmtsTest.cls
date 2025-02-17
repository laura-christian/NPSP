@isTest
public class RecalcConvertedPmtAmtsTest {
    
    @isTest(SeeAllData=true)
    public static void testSchedulableClass() {
		String jobId = System.schedule('Recalculated Converted Payment Amounts', '0 45 * * * ?', new ScheduleRecalcOfConvertedPmtAmts());        
    }
    
    @isTest
    public static void testBatchRecalcPmts() {
        
        Account a = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',
		CurrencyIsoCode = 'GBP',            
        Type = 'Household');
        insert a;
        
        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = a.Id);
        insert c;         
        
        Opportunity donation = new Opportunity(
        AccountId = a.Id,
        RecordTypeId = '0128b000000XLooAAG',
        Name = 'Donation',
        CurrencyIsoCode = 'GBP',
        Amount = 20,
        CloseDate = System.today()+7,
        StageName = 'Open');
        insert donation;
        
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
        npe01__Opportunity__c = donation.Id,
        CurrencyIsoCode = 'GBP',
        npe01__Payment_Amount__c = 20,
        npe01__Scheduled_Date__c = System.today()+7,
        npe01__Paid__c = false);
        insert pmt;
        
        Opportunity pledge = new Opportunity(
        AccountId = a.Id,
        RecordTypeId = '0128b0000012G2tAAE',
        Name = 'Pledge',
        CurrencyIsoCode = 'GBP',
        Amount = 20000,
        CloseDate = System.today()-365,
        StageName = 'Closed Won');
        insert pledge;
        
        npe01__OppPayment__c pmt2 = new npe01__OppPayment__c(
        npe01__Opportunity__c = pledge.Id,
        CurrencyIsoCode = 'GBP',
        npe01__Payment_Amount__c = 10000,
        npe01__Payment_Date__c = System.today()-365,
        npe01__Paid__c = true);
        insert pmt2;
        
        npe01__OppPayment__c pmt3 = new npe01__OppPayment__c(
        npe01__Opportunity__c = pledge.Id,
        CurrencyIsoCode = 'GBP',
        npe01__Payment_Amount__c = 10000,
        npe01__Scheduled_Date__c = System.today(),
        npe01__Paid__c = false);
        insert pmt3;         

		List<DatedConversionRate> DCRs = [SELECT Id, IsoCode, StartDate, NextStartDate 
                                          FROM DatedConversionRate
                                          WHERE IsoCode = 'GBP'];
        
        Test.startTest();
        Database.executeBatch(new BatchRecalcConvertedPmtAmts(DCRs));
        Test.stopTest();
        
    }
    
    @isTest
    public static void testBatchRecalcOpps() {

        Account famFoundation = new Account(
        Name = 'Suzie Q Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United Kingdom',
        CurrencyIsoCode = 'GBP');
        insert famFoundation;       
        
        Opportunity majorGift = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        AccountId = famFoundation.Id,
        Amount = 50000,
        CurrencyIsoCode = 'GBP',
        CloseDate = System.today()+100,
        StageName = 'Verbal Commitment');
        insert majorGift;
        
        Opportunity majorGiftUSD = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        AccountId = famFoundation.Id,
        Amount = 50000,
        CurrencyIsoCode = 'USD',
        CloseDate = System.today()+100,
        StageName = 'Verbal Commitment');
        insert majorGiftUSD;  
        
        Opportunity majorGiftHKD = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        AccountId = famFoundation.Id,
        Amount = 100000,
        CurrencyIsoCode = 'HKD',
        CloseDate = System.today()+100,
        StageName = 'Verbal Commitment');
        insert majorGiftHKD; 

		famFoundation.CurrencyIsoCode = 'GBP';
        update famFoundation;

		List<DatedConversionRate> DCRs = [SELECT Id, IsoCode, StartDate, NextStartDate 
                                          FROM DatedConversionRate
                                          WHERE NextStartDate > TODAY];
        
        Test.startTest();
        List<Opportunity> opps = [SELECT Id, CurrencyIsoCode, Account.CurrencyIsoCode, Amount, CloseDate, npe01__Number_of_Payments__c FROM Opportunity];
        Database.executeBatch(new BatchRecalcConvertedOppAmts(DCRs));
		Test.stopTest();        
        
    }
    
    

}