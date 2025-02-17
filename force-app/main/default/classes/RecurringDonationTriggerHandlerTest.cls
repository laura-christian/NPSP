@isTest
public class RecurringDonationTriggerHandlerTest {

    @isTest
    public static void testRecurringDonationTriggerHandlerPartOne() {
        
        Account a = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household');
        insert a;

        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = a.Id);
        insert c; 
        
        npe03__Recurring_Donation__c monthly = new npe03__Recurring_Donation__c(
        npe03__Contact__c = c.Id,
        CurrencyIsoCode = 'JPY',
        npe03__Amount__c = 6000,
        npe03__Date_Established__c = System.today(),
		npsp__InstallmentFrequency__c = 1,          
        npe03__Installment_Period__c = 'Monthly');
        
        npe03__Recurring_Donation__c annually = new npe03__Recurring_Donation__c(
        npe03__Organization__c = a.Id,          
        CurrencyIsoCode = 'JPY',
        npe03__Amount__c = 100000,
        npe03__Date_Established__c = System.today(),
		npsp__InstallmentFrequency__c = 1,          
        npe03__Installment_Period__c = 'Yearly');
        
        npe03__Recurring_Donation__c semiMonthly = new npe03__Recurring_Donation__c(
        npe03__Organization__c = a.Id,          
        CurrencyIsoCode = 'JPY',
        npe03__Amount__c = 6000,
        npe03__Date_Established__c = System.today(),        
        npe03__Installment_Period__c = '1st and 15th');        
        
        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>{monthly, annually, semiMonthly};
        insert recurringDonations;
        
        System.assert([SELECT Id, Name FROM npe03__Recurring_Donation__c WHERE Id = :annually.Id][0].Name.contains('Annually'));
    }    
    
    @isTest
    public static void testRecurringDonationTriggerHandlerPartTwo() {
        
        Account a = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household');
        insert a;

        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = a.Id);
        insert c; 
        
        
        npe03__Recurring_Donation__c semiAnnually = new npe03__Recurring_Donation__c(
        npe03__Organization__c = a.Id,          
        CurrencyIsoCode = 'JPY',
        npe03__Amount__c = 100000,
        npe03__Date_Established__c = System.today(),
		npsp__InstallmentFrequency__c = 6,          
        npe03__Installment_Period__c = 'Monthly');
        
        npe03__Recurring_Donation__c biWeekly = new npe03__Recurring_Donation__c(
        npe03__Organization__c = a.Id,          
        CurrencyIsoCode = 'JPY',
        npe03__Amount__c = 6000,
        npe03__Date_Established__c = System.today(),
		npsp__InstallmentFrequency__c = 2,          
        npe03__Installment_Period__c = 'Weekly');

        npe03__Recurring_Donation__c quarterly = new npe03__Recurring_Donation__c(
        npe03__Organization__c = a.Id,          
        CurrencyIsoCode = 'JPY',
        npe03__Amount__c = 12000,
        npe03__Date_Established__c = System.today(),
		npsp__InstallmentFrequency__c = 3,          
        npe03__Installment_Period__c = 'Monthly');
        
        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>{semiAnnually, biWeekly, quarterly};
        insert recurringDonations;        
                
        System.assert([SELECT Id, Name FROM npe03__Recurring_Donation__c WHERE Id = :semiAnnually.Id][0].Name.contains('Semi-Annually'));
    }        
    
}