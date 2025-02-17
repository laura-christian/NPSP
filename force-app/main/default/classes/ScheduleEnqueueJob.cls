global class ScheduleEnqueueJob Implements Schedulable {

    
	global Set<Id> acctsWCurrencyISOCodeOrGeolocationChanges;
    global Set<Id> acctsWCurrencyISOCodeChanges;
    
    global ScheduleEnqueueJob(Set<Id> acctsWCurrencyISOCodeOrGeolocationChanges, Set<Id> acctsWCurrencyISOCodeChanges) {
        this.acctsWCurrencyISOCodeOrGeolocationChanges = acctsWCurrencyISOCodeOrGeolocationChanges;
        this.acctsWCurrencyISOCodeChanges = acctsWCurrencyISOCodeChanges;
    }
    
    global void execute(SchedulableContext sc) {
        if (!Test.isRunningTest()) {System.enqueueJob(new QueueableRunTerritoryAssignmentRules(acctsWCurrencyISOCodeOrGeolocationChanges, acctsWCurrencyISOCodeChanges));}
        // Abort the job to prevent it from hanging in the background indefinitely
        System.abortJob(sc.getTriggerId());
    }
}