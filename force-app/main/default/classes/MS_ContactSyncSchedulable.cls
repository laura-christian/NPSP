/**
 * Retrieve Contact Data for our custom contact sync, via EN API,
 * and populate this into Contact Sync Staging Records. Then go ahead
 * and process these records into Contact/Lead updates via our custom
 * algorithm.
 * 
 * Runs for yesterday's records - see MS_ContactSyncRetrieveDataFromEN
 * for full details.
 */
global class MS_ContactSyncSchedulable implements Schedulable {
    global void execute(SchedulableContext SC) {
        Date yesterday = Date.today().addDays(-1);
		System.enqueueJob(new MS_ContactSyncRetrieveDataFromEN(yesterday));
    }
}