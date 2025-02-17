@isTest
public class PaymentTriggerTest {
    
    @isTest
    public static void testPaymentTrigger() {
        
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
        
        Opportunity opp = new Opportunity(
        AccountId = a.Id,
        RecordTypeId = '0128b000000XLooAAG',
        Name = 'Donation',
        CurrencyIsoCode = 'GBP',
        Amount = 20,
        CloseDate = System.today()+7,
        StageName = 'Open');
        insert opp;
        
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
        npe01__Opportunity__c = opp.Id,
        CurrencyIsoCode = 'GBP',
        npe01__Payment_Amount__c = 20,
        npe01__Scheduled_Date__c = System.today()+7,
        npe01__Paid__c = false);
        insert pmt;
        
        opp.StageName = 'Closed Won';
        update opp;
        pmt.npe01__Paid__c = true;
        pmt.npe01__Payment_Date__c = System.today();
        update pmt;
        
        Opportunity opp2 = new Opportunity(
        AccountId = a.Id,
        RecordTypeId = '0128b000000XLooAAG',
        Name = 'Donation',
        CurrencyIsoCode = 'EUR',
        Amount = 20,
        CloseDate = System.today(),
        StageName = 'Open');
        insert opp2;
        
        npe01__OppPayment__c pmt2 = new npe01__OppPayment__c(
        npe01__Opportunity__c = opp2.Id,
        CurrencyIsoCode = 'EUR',
        npe01__Payment_Amount__c = 20,
        npe01__Scheduled_Date__c = System.today(),
        npe01__Paid__c = false);
        insert pmt2;
        
        opp2.StageName = 'Closed Won';
        update opp2;
        pmt2.npe01__Paid__c = true;
        pmt2.npe01__Payment_Date__c = System.today();
        update pmt2;        

		System.assert([SELECT Id, Converted_Amount_Dated__c FROM npe01__OppPayment__c WHERE Id = :pmt.Id][0].Converted_Amount_Dated__c != null);        
    }

    @isTest
    public static void testPaymentTrigger2() {
        
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
        
        Opportunity opp = new Opportunity(
        AccountId = a.Id,
        RecordTypeId = '0128b000000XLooAAG',
        Name = 'Donation',
        CurrencyIsoCode = 'USD',
        Amount = 20,
        CloseDate = System.today(),
        StageName = 'Closed Won');
        insert opp;
        
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
        npe01__Opportunity__c = opp.Id,
        CurrencyIsoCode = 'USD',
        npe01__Payment_Amount__c = 20,
        npe01__Payment_Date__c = System.today(),
        npe01__Paid__c = true);
        insert pmt;

		System.assert([SELECT Id, Amount_in_Acct_Currency__c FROM npe01__OppPayment__c WHERE Id = :pmt.Id][0].Amount_in_Acct_Currency__c != null);        
    }

    @isTest
    public static void testPaymentTrigger3() {
        
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
        
        Opportunity opp = new Opportunity(
        AccountId = a.Id,
        RecordTypeId = '0128b0000012G2tAAE',
        Name = 'Pledge',
        CurrencyIsoCode = 'GBP',
        Amount = 20000,
        CloseDate = System.today()-365,
        StageName = 'Closed Won');
        insert opp;
        
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
        npe01__Opportunity__c = opp.Id,
        CurrencyIsoCode = 'GBP',
        npe01__Payment_Amount__c = 10000,
        npe01__Payment_Date__c = System.today()-365,
        npe01__Paid__c = true);
        insert pmt;
        
        npe01__OppPayment__c pmt2 = new npe01__OppPayment__c(
        npe01__Opportunity__c = opp.Id,
        CurrencyIsoCode = 'GBP',
        npe01__Payment_Amount__c = 10000,
        npe01__Scheduled_Date__c = System.today(),
        npe01__Paid__c = false);
        insert pmt2;        

		System.assert([SELECT Id, Amount_in_Acct_Currency__c FROM npe01__OppPayment__c WHERE Id = :pmt.Id][0].Amount_in_Acct_Currency__c != null);        
    }      
    
}