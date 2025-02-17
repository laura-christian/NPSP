@isTest
public class GAUAllocationTriggerTest {

    @isTest
    public static void testGAUAllocationTrigger() {
        
        Account a = new Account(
        Name = 'Test Account Household',
        RecordTypeId = '0128b000000XLom',
        Type = 'Household',
        CurrencyIsoCode = 'GBP');
        insert a;
        
        Contact c = new Contact(
        FirstName = 'Test',
        LastName = 'Account',
        AccountId = a.Id);
        
        Opportunity donation = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLoo',
        AccountId = a.Id,
        npsp__Primary_Contact__c = c.Id,
        Amount = 100,
        CurrencyIsoCode = 'GBP',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert donation;
        
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
        npe01__Opportunity__c = donation.Id,
        npe01__Payment_Date__c = System.today(),
        npe01__Payment_Amount__c = 100,
        CurrencyIsoCode = 'GBP',
        npe01__Paid__c = true);
        insert pmt;          
        
        npsp__General_Accounting_Unit__c GAU = new npsp__General_Accounting_Unit__c(
        Name = 'Custom - Jordan');
        insert GAU;
        
        npsp__General_Accounting_Unit__c GAU2 = new npsp__General_Accounting_Unit__c(
        Name = 'Literacy - General');
        insert GAU2;        
        
        Test.startTest();
        
        npsp__Allocation__c oppAlloc = new npsp__Allocation__c(
        npsp__Opportunity__c = donation.Id,
        npsp__General_Accounting_Unit__c = GAU.Id,
        Link_to_Supporting_Docs_for_GAU__c = 'https://roomtoread.sharepoint.com/:x:/r/sites/AllRTR/GO/FIN/Public/Accounting/RemoteGOOffices/Switzerland/Bank%20Statements%20and%20Gift%20Documentation/2022/Benevity/Benevity%20USD%20329.92%20June%2029.csv?d=w16ac755f55f2477fbb83a35664a6ac47&csf=1&web=1&e=XBZB0F',
        npsp__Amount__c = 50);
        insert oppAlloc;  
        
        npsp__Allocation__c oppAlloc2 = new npsp__Allocation__c(
        npsp__Opportunity__c = donation.Id,
        npsp__General_Accounting_Unit__c = GAU2.Id,
        Link_to_Supporting_Docs_for_GAU__c = 'https://roomtoread.sharepoint.com/:x:/r/sites/AllRTR/GO/FIN/Public/Accounting/RemoteGOOffices/Switzerland/Bank%20Statements%20and%20Gift%20Documentation/2022/Benevity/Benevity%20USD%20329.92%20June%2029.csv?d=w16ac755f55f2477fbb83a35664a6ac47&csf=1&web=1&e=XBZB0F',
        npsp__Amount__c = 50);
        insert oppAlloc2;        
                
        Test.stopTest();
        
        System.assert([SELECT Id, GAU_s__c FROM npe01__OppPayment__c WHERE npe01__Opportunity__c = :donation.Id][0].GAU_s__c.contains(';'));
        
    }
    
}