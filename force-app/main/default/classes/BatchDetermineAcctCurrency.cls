global class BatchDetermineAcctCurrency implements Database.Batchable<sObject> {
    
    global String query;
    
    global BatchDetermineAcctCurrency(String query) {
        this.query = query;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        
        // Work on one account at a time
        Account a = scope[0];
        List<Opportunity> gifts = [SELECT Id, AccountId, CurrencyIsoCode, CloseDate
								   FROM Opportunity
								   WHERE AccountId = :a.Id AND RecordType.Name IN ('Donation',
								   'Grant', 'Conditional Grant', 'Major Gift', 'Pledge')
                                   AND ForecastCategory = 'Closed'
								   ORDER BY CloseDate DESC];
        List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :a.Id];
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }
        // Query all partial soft credits on account
        List<npsp__Partial_Soft_Credit__c> partialSoftCredits = 
            [SELECT npsp__Contact__r.AccountId, CurrencyIsoCode, npsp__Opportunity__r.CloseDate 
             FROM npsp__Partial_Soft_Credit__c
             WHERE npsp__Contact__c IN :contactIds
             ORDER BY npsp__Opportunity__r.CloseDate DESC];        
        // Query all account soft credits on account
        List<npsp__Account_Soft_Credit__c> acctSoftCredits =
            [SELECT npsp__Account__c, CurrencyIsoCode, npsp__Opportunity__r.CloseDate
             FROM npsp__Account_Soft_Credit__c
             WHERE npsp__Account__c = :a.Id
             ORDER BY npsp__Opportunity__r.CloseDate DESC];
        
        // Iterate over query results while maintaining running count of hard and soft credits per currency.
        // List is used alongside map structure to track the order in which new currencies are encountered going
        // from the most recent credit to the least. This is so that if the donor gives or is soft credited
        // in two currencies with equal frequency, the currency of the more recent credits will be prioritized
        // over older credits.
        List<String> currenciesInOrder = new List<String>();
        Map<String, Integer> currencyToCount = new Map<String, Integer>();
        for (Opportunity o : gifts) {
            if (!currencyToCount.containsKey(o.CurrencyIsoCode)) {
                currencyToCount.put(o.CurrencyIsoCode, 1);
                currenciesInOrder.add(o.CurrencyIsoCode);
            }
            else {
                Integer currentCt = currencyToCount.get(o.CurrencyIsoCode);
                currentCt += 1;
                currencyToCount.put(o.CurrencyIsoCode, currentCt);
            }
        }
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
			if (!currencyToCount.containsKey(softCred.CurrencyIsoCode)) {
                currencyToCount.put(softCred.CurrencyIsoCode, 1);
                currenciesInOrder.add(softCred.CurrencyIsoCode);
            }
            else {
                Integer currentCt = currencyToCount.get(softCred.CurrencyIsoCode);
                currentCt += 1;
                currencyToCount.put(softCred.CurrencyIsoCode, currentCt);
			}
        }
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
			if (!currencyToCount.containsKey(softCred.CurrencyIsoCode)) {
                currencyToCount.put(softCred.CurrencyIsoCode, 1);
                currenciesInOrder.add(softCred.CurrencyIsoCode);
            }
            else {
                Integer currentCt = currencyToCount.get(softCred.CurrencyIsoCode);
                currentCt += 1;
                currencyToCount.put(softCred.CurrencyIsoCode, currentCt);
			}
        }

        Integer highestCount = 0;
		String isoCode = 'USD';
        for (String currencyCode : currenciesInOrder) {
			Integer count = currencyToCount.get(currencyCode);
            if (count > highestCount) {
                highestCount = count;
                isoCode = currencyCode;
            }
        }
        
        // If currency with highest count is different from current account currency,
        // update account
        if (a.CurrencyIsoCode != isoCode) {
            a.CurrencyIsoCode = isoCode;
            update a;
        }               
    }   
     
    global void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job determining account currency: ' + job.Status);
    }
}