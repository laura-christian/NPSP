trigger RecurringDonationTrigger on npe03__Recurring_Donation__c (before insert, before update) {

    if (Trigger.isBefore) {
        RecurringDonationTriggerHandler.beforeInsertOrUpdate(Trigger.new, Trigger.isInsert);
    } 
	
}