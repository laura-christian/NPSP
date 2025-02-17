public class ScheduleAddressDedupingVerification Implements Schedulable {

    public void execute(SchedulableContext sc) {
        
        Datetime now = Test.isRunningTest() ? Datetime.newInstance(2022, 1, 1, 12, 06, 0) : System.now();        

        Datetime tenMinutesAfterHour = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), 10, 0);
        Datetime oneHourAgo = tenMinutesAfterHour.addMinutes(-60);
        
        List<npsp__Address__c> newAddresses = [SELECT Id, Name, Original_Address_Scrubbed__c, 
                                               npsp__Pre_Verification_Address__c, npsp__Household_Account__c,
                                               npsp__Verified__c, Do_Not_Verify__c,
                                               npsp__MailingStreet__c, npsp__MailingStreet2__c,
                                               npsp__MailingCity__c, npsp__MailingState__c,   
                                               npsp__MailingPostalCode__c, npsp__MailingCountry__c,
                                               CreatedDate
                                               FROM npsp__Address__c
                                               WHERE CreatedDate > :oneHourAgo AND
                                               CreatedDate <= :tenMinutesAfterHour];
        
        if (!newAddresses.isEmpty()) {Id batchJobId = Database.executeBatch(new BatchProcessNewAddresses(newAddresses), 1);}
    }
    
    
}