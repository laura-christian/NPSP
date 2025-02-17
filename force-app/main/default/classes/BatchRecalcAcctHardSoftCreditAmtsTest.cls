@isTest
public class BatchRecalcAcctHardSoftCreditAmtsTest {
    
    @isTest(SeeAllData=true)
    public static void testBatchClass() {
        List<Account> accts = [SELECT Id, Name, CurrencyIsoCode FROM Account WHERE CurrencyIsoCode != 'USD' AND RecordType.Name = 'Household Account' AND npo02__TotalOppAmount__c > 0 AND Total_Partial_Soft_Credits__c > 0 AND Total_Account_Soft_Credits__c > 0 LIMIT 5];
        Set<Id> acctIds = new Set<Id>();
        for (Account a : accts) {
            acctIds.add(a.Id);
        }
        Test.startTest();
        Database.executeBatch(new BatchRecalcAcctHardSoftCreditAmts(acctIds, ''), 5);
        Test.stopTest();
    }

}