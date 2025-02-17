public class BatchRecalcConvertedPmtAmts implements Database.Batchable<sObject> {

    public List<DatedConversionRate> DCRs = new List<DatedConversionRate>();
    
    public BatchRecalcConvertedPmtAmts(List<DatedConversionRate> DCRs) {
        this.DCRs = DCRs;
    }
    
	public Database.QueryLocator start(Database.BatchableContext bc) {
    	System.debug('>>>> Init batch recalculation of converted payment amounts (dated)');
        List<String> queryTargetsByIsoCode = new List<String>();
        for (DatedConversionRate dcr : DCRs) {
            String criterion = '(CurrencyIsoCode = \'' + dcr.isoCode + '\' AND ((npe01__Paid__c = true AND npe01__Payment_Date__c != null AND npe01__Payment_Date__c >= ' + String.valueOf(dcr.StartDate) + 
                ' AND npe01__Payment_Date__c < ' + String.valueOf(dcr.nextStartDate) + ') OR (npe01__Paid__c = false AND npe01__Opportunity__r.RecordType.Name = \'Pledge\' AND npe01__Opportunity__r.CloseDate >= ' + String.valueOf(dcr.StartDate) +
                ' AND npe01__Opportunity__r.CloseDate < ' + String.valueOf(dcr.nextStartDate) + ') OR (npe01__Paid__c = false AND npe01__Opportunity__r.RecordType.Name != \'Pledge\' AND npe01__Scheduled_Date__c != null' + 
                ' AND npe01__Scheduled_Date__c >= ' + String.valueOf(dcr.StartDate) + ' AND npe01__Scheduled_Date__c < ' + String.valueOf(dcr.nextStartDate) + ')))';
            queryTargetsByIsoCode.add(criterion);
        }
        String queryCriteria = String.join(queryTargetsByIsoCode, ' OR ');
        String stringQuery = 'SELECT Id FROM npe01__OppPayment__c WHERE ' + queryCriteria;
        System.debug(stringQuery);
        return Database.getQueryLocator(stringQuery);
    }   
    
    public void execute(Database.BatchableContext bc, List<npe01__OppPayment__c> scope) {
        List<npe01__OppPayment__c> pmtsToUpdate = new List<npe01__OppPayment__c>();
        for (npe01__OppPayment__c pmt : scope) {
            pmt.Recalculate_Converted_Amount__c = true;
            pmtsToUpdate.add(pmt);
        }
        Database.update(pmtsToUpdate, false);
    }
    
	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job recalculating converted payment amounts: ' + job.Status);
        if (!Test.isRunningTest()) {Database.executeBatch(new BatchRecalcConvertedOppAmts(DCRs), 20);}
    }       
}