public class BatchRecalcAcctHardSoftCreditAmts implements Database.Batchable<sObject> {
   
	public Set<Id> acctIds;
    public String query;
    
    public BatchRecalcAcctHardSoftCreditAmts(Set<Id> acctIds, String query) {
        this.acctIds = acctIds;
        this.query = query;
    }
    
	public Database.QueryLocator start(Database.BatchableContext bc) {
    	System.debug('>>>> Init batch recalculation of account hard and soft credit amounts in USD and account currency');
        String queryString;
        if (!String.isBlank(query)) {queryString = query;}
        else {queryString = 'SELECT Id, CurrencyIsoCode FROM Account WHERE Id IN :acctIds';}
        return Database.getQueryLocator(queryString);
    }
    
	public void execute(Database.BatchableContext bc, List<Account> scope) { 
        Set<Id> acctIdsInBatch = new Set<Id>();
        Set<String> currencies = new Set<String>();
        for (Account a : scope) {
            acctIdsInBatch.add(a.Id);
            currencies.add(a.CurrencyIsoCode);
        }
        List<npe01__OppPayment__c> pmts = [SELECT Id, npe01__Payment_Amount__c, Converted_Amount_Dated__c, Amount_in_Acct_Currency__c, CurrencyIsoCode, 
                                           npe01__Scheduled_Date__c, npe01__Payment_Date__c, npe01__Paid__c, npe01__Opportunity__r.AccountId
                                  		   FROM npe01__OppPayment__c
                                  		   WHERE npe01__Opportunity__r.AccountId IN :acctIdsInBatch];
        List<npe01__OppPayment__c> pmtsToUpdate = new List<npe01__OppPayment__c>();
        for (npe01__OppPayment__c pmt : pmts) {
			pmt.Recalculate_Converted_Amount__c = true;
            pmtsToUpdate.add(pmt);
        }
        Database.update(pmtsToUpdate, false);
        Set<Id> oppIds = new Set<Id>();
        List<npsp__Account_Soft_Credit__c> acctSoftCredits = [SELECT Id, npsp__Account__c, npsp__Account__r.CurrencyIsoCode,
                                                              CurrencyIsoCode, npsp__Amount__c, Percent__c,
                                                              Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c,
                                                              npsp__Opportunity__c, npsp__Opportunity__r.Amount,
                                                              npsp__Opportunity__r.CloseDate, 
                                                              npsp__Opportunity__r.Account.CurrencyIsoCode,
                                                              npsp__Opportunity__r.Amount_in_USD_Dated__c,
                                                              npsp__Opportunity__r.Amount_in_Acct_Currency__c
                                                              FROM npsp__Account_Soft_Credit__c
                                                              WHERE npsp__Account__c IN :acctIdsInBatch];
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            currencies.add(softCred.CurrencyIsoCode);
            oppIds.add(softCred.npsp__Opportunity__c);
        } 
        List<npsp__Partial_Soft_Credit__c> partialSoftCredits = [SELECT Id, npsp__Contact__r.AccountId, 
                                                                 npsp__Contact__r.Account.CurrencyIsoCode, 
                                                                 CurrencyIsoCode, npsp__Amount__c,
                                                                 Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c,
                                                                 npsp__Opportunity__c, npsp__Opportunity__r.Amount,
                                                                 npsp__Opportunity__r.CloseDate,
                                                                 npsp__Opportunity__r.Amount_in_USD_Dated__c,
                                                                 npsp__Opportunity__r.Amount_in_Acct_Currency__c,
                                                                 npsp__Opportunity__r.Account.CurrencyIsoCode                                                                 
                                                                 FROM npsp__Partial_Soft_Credit__c
                                                                 WHERE npsp__Contact__r.AccountId IN :acctIdsInBatch];
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            currencies.add(softCred.CurrencyIsoCode);
            oppIds.add(softCred.npsp__Opportunity__c);
        }
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.CurrencyIsoCode, CurrencyIsoCode, Amount, CloseDate, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c FROM Opportunity WHERE Id IN :oppIds]);        
        Map<String, List<DatedConversionRate>> currencyToFXRates = HardAndSoftCreditTriggerHandler.getDatedConversionRates(currencies);
        List<npsp__Account_Soft_Credit__c> acctSoftCreditsToUpdate = new List<npsp__Account_Soft_Credit__c>();
        List<npsp__Partial_Soft_Credit__c> partialSoftCreditsToUpdate = new List<npsp__Partial_Soft_Credit__c>();
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            String acctCurrency = softCred.npsp__Account__r.CurrencyIsoCode;
            Decimal percentSoftCredited = 1;
			if (softCred.Percent__c > 0) {percentSoftCredited = softCred.Percent__c/100;}
            else if (softCred.npsp__Opportunity__r.Amount > 0) {percentSoftCredited = softCred.npsp__Amount__c/softCred.npsp__Opportunity__r.Amount;}
			softCred = HardAndSoftCreditTriggerHandler.calculateAcctSoftCreditAmts(softCred, oppMap, currencyToFXRates, acctCurrency, percentSoftCredited);
            acctSoftCreditsToUpdate.add(softCred);
        }
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            String acctCurrency = softCred.npsp__Contact__r.Account.CurrencyIsoCode;
            Decimal percentSoftCredited = 1;
            if (softCred.npsp__Opportunity__r.Amount > 0) {percentSoftCredited = softCred.npsp__Amount__c/softCred.npsp__Opportunity__r.Amount;}
            softCred = HardAndSoftCreditTriggerHandler.calculatePartialSoftCreditAmts(softCred, oppMap, currencyToFXRates, acctCurrency, percentSoftCredited);
            partialSoftCreditsToUpdate.add(softCred);
        }
        if (!acctSoftCreditsToUpdate.isEmpty()) {Database.update(acctSoftCreditsToUpdate, false);}
        if (!partialSoftCreditsToUpdate.isEmpty()) {Database.update(partialSoftCreditsToUpdate, false);}        
    }
    
	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job recalculating converted amounts: ' + job.Status);
    }     

}