public class ScheduleBatchDetermineBestGivingYear implements Schedulable {

    public void execute(SchedulableContext sc) {
        
        Datetime now = System.now();        

        Datetime thirtyMinutesAfterHour = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), 30, 0);
        Datetime oneDayAgo = thirtyMinutesAfterHour.addHours(-24);
        
        Set<Id> acctIds = new Set<Id>();
        List<Opportunity> modifiedOpps = [SELECT Id, AccountId 
                                          FROM Opportunity
                                          WHERE LastModifiedDate >= :oneDayAgo];
        for (Opportunity o : modifiedOpps) {
            acctIds.add(o.AccountId);
        }
        List<npsp__Partial_Soft_Credit__c> modifiedPartialSoftCredits = [SELECT Id, npsp__Contact__r.AccountId
                                                                 FROM npsp__Partial_Soft_Credit__c
                                                                 WHERE LastModifiedDate >= :oneDayAgo];
        for (npsp__Partial_Soft_Credit__c softCred : modifiedPartialSoftCredits) {
            acctIds.add(softCred.npsp__Contact__r.AccountId);
        }
        List<npsp__Account_Soft_Credit__c> modifiedAcctSoftCredits = [SELECT Id, npsp__Account__c
                                                              FROM npsp__Account_Soft_Credit__c
                                                              WHERE LastModifiedDate >= :oneDayAgo];
        for (npsp__Account_Soft_Credit__c softCred : modifiedAcctSoftCredits) {
            acctIds.add(softCred.npsp__Account__c);
        }
        List<Account> accts = [SELECT Id FROM Account WHERE Id IN :acctIds];
        if (!accts.isEmpty()) {Id batchJobId = Database.executeBatch(new BatchDetermineBestGivingYearTotal(accts), 1);}
    }
}