public class BatchUpdatePaymentAllocations implements Database.Batchable<sObject> {

    
    public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = '';
        if (Test.isRunningTest()) {
            query = 'SELECT Id, Name, npsp__Payment__c, npsp__General_Accounting_Unit__c, ' +
            		'npsp__Payment__r.npe01__Opportunity__c FROM npsp__Allocation__c ' +
            		'WHERE npsp__Payment__r.npe01__Opportunity__r.RecordType.Name = \'Donation\' LIMIT 100';
        }
            
        else {
            query = 'SELECT Id, Name, npsp__Payment__c, npsp__General_Accounting_Unit__c, ' +
            		'npsp__Payment__r.npe01__Opportunity__c FROM npsp__Allocation__c ' +
            		'WHERE npsp__Payment__r.npe01__Opportunity__r.RecordType.Name = \'Donation\'';
        }   
        return Database.getQueryLocator(query);
    }    


    public void execute(Database.BatchableContext bc, List<npsp__Allocation__c> scope) {
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Id> paymentOppIdToGAUId = new Map<Id, Id>();
        for (npsp__Allocation__c alloc : scope) {
            oppIds.add(alloc.npsp__Payment__r.npe01__Opportunity__c);
            paymentOppIdToGAUId.put(alloc.npsp__Payment__r.npe01__Opportunity__c, alloc.npsp__General_Accounting_Unit__c);
        }
        List<npsp__Allocation__c> oppAllocations = [SELECT Id, npsp__General_Accounting_Unit__c, npsp__Opportunity__c
                                                    FROM npsp__Allocation__c
                                                    WHERE npsp__Opportunity__c IN :oppIds];
        Map<Id, Id> oppIdToGAUId = new Map<Id, Id>();
        for (npsp__Allocation__c alloc : oppAllocations) {
            oppIdToGAUId.put(alloc.npsp__Opportunity__c, alloc.npsp__General_Accounting_Unit__c);
        }
        List<npsp__Allocation__c> pmtAllocationsToUpdate = new List<npsp__Allocation__c>();
        for (npsp__Allocation__c alloc : scope) {
            if (paymentOppIdToGAUId.get(alloc.npsp__Payment__r.npe01__Opportunity__c) != oppIdToGAUId.get(alloc.npsp__Payment__r.npe01__Opportunity__c)) {
                System.debug('Payment has been allocated to ' + alloc.npsp__Payment__r.npe01__Opportunity__c + '; opportunity has been allocated to ' + alloc.npsp__Payment__r.npe01__Opportunity__c);
                alloc.npsp__General_Accounting_Unit__c = oppIdToGAUId.get(alloc.npsp__Payment__r.npe01__Opportunity__c);
                pmtAllocationsToUpdate.add(alloc);
            }
        }
        if (!pmtAllocationsToUpdate.isEmpty()) {Database.update(pmtAllocationsToUpdate, false);}

    }
    
  	public void finish(Database.BatchableContext bc) { 
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job: ' + job.Status);
    }    
    
}