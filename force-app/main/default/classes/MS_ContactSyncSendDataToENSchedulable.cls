/**
 * See MS_ContactSyncSendDataToEN for comments
 *
 * Authored by Jake Martin White
 * jake@mustardseednonprofit.ca
 */
global class MS_ContactSyncSendDataToENSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        EN_Dataservice_Settings__mdt settings = [SELECT Batch_Size__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
        Integer batchSize = 2000;
        
        if (settings.Batch_Size__c > 0) {
            batchSize = (Integer)settings.Batch_Size__c;
        }
        
        MS_ContactSyncSendAccountsToEN b = new MS_ContactSyncSendAccountsToEN(); 
        Database.executeBatch(b, batchSize);

        MS_ContactSyncSendLeadsToEN b2 = new MS_ContactSyncSendLeadsToEN(); 
        Database.executeBatch(b2, batchSize);
    }
}