public class BatchDetermineBestGivingYearTotal implements Database.Batchable<Account> {
    
    public List<Account> accounts;
    
    public BatchDetermineBestGivingYearTotal(List<Account> accounts) {
        this.accounts = accounts;
    }
    
	public List<Account> start(Database.BatchableContext bc) {
    	System.debug('>>>> Init batch determination of best giving year total');
        return accounts;
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
	
        // Work on one account at a time
        Account a = scope[0];
        List<Opportunity> gifts = [SELECT Id, AccountId, CurrencyIsoCode, CloseDate, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c
								   FROM Opportunity
								   WHERE AccountId = :a.Id AND RecordType.Name IN ('Donation',
								   'Grant', 'Conditional Grant', 'Major Gift', 'Pledge')
                                   AND ForecastCategory = 'Closed'
								   ORDER BY CloseDate];
        List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :a.Id];
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }
        // Query all partial soft credits on account
        List<npsp__Partial_Soft_Credit__c> partialSoftCredits = 
            [SELECT npsp__Contact__r.AccountId, CurrencyIsoCode, npsp__Opportunity__r.CloseDate, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c 
             FROM npsp__Partial_Soft_Credit__c
             WHERE npsp__Contact__c IN :contactIds AND Is_P2P_Soft_Credit__c = false AND npsp__Role_Name__c != 'Solicitor'
             ORDER BY npsp__Opportunity__r.CloseDate];        
        // Query all account soft credits on account
        List<npsp__Account_Soft_Credit__c> acctSoftCredits =
            [SELECT npsp__Account__c, CurrencyIsoCode, npsp__Opportunity__r.CloseDate, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c
             FROM npsp__Account_Soft_Credit__c
             WHERE npsp__Account__c = :a.Id
             ORDER BY npsp__Opportunity__r.CloseDate];
        
        Map<Integer, Decimal> yearToSumOfGivingUSD = new Map<Integer, Decimal>();
        Map<Integer, Decimal> yearToSumOfGivingAcctCurrency = new Map<Integer, Decimal>();
        for (Opportunity o : gifts) {
            o.Amount_in_USD_Dated__c = o.Amount_in_USD_Dated__c != null ? o.Amount_in_USD_Dated__c : 0;
            o.Amount_in_Acct_Currency__c = o.Amount_in_Acct_Currency__c != null ? o.Amount_in_Acct_Currency__c : 0;
            if (!yearToSumOfGivingUSD.containsKey(o.CloseDate.year())) {
                yearToSumOfGivingUSD.put(o.CloseDate.year(), o.Amount_in_USD_Dated__c);
            	yearToSumOfGivingAcctCurrency.put(o.CloseDate.year(), o.Amount_in_Acct_Currency__c);
            }
            else {
                Decimal runningTotal = yearToSumOfGivingUSD.get(o.CloseDate.year());
                runningTotal += o.Amount_in_USD_Dated__c;
				yearToSumOfGivingUSD.put(o.CloseDate.year(), runningTotal);
                runningTotal = yearToSumOfGivingAcctCurrency.get(o.CloseDate.year());
                runningTotal += o.Amount_in_Acct_Currency__c;
				yearToSumOfGivingAcctCurrency.put(o.CloseDate.year(), runningTotal);                
            }           
        }
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            softCred.Amount_in_USD_Dated__c = softCred.Amount_in_USD_Dated__c != null ? softCred.Amount_in_USD_Dated__c : 0;
            softCred.Amount_in_Acct_Currency__c = softCred.Amount_in_Acct_Currency__c != null ? softCred.Amount_in_Acct_Currency__c : 0;
            if (!yearToSumOfGivingUSD.containsKey(softCred.npsp__Opportunity__r.CloseDate.year())) {
                yearToSumOfGivingUSD.put(softCred.npsp__Opportunity__r.CloseDate.year(), softCred.Amount_in_USD_Dated__c);
                yearToSumOfGivingAcctCurrency.put(softCred.npsp__Opportunity__r.CloseDate.year(), softCred.Amount_in_Acct_Currency__c);
            }
            else {
                Decimal runningTotal = yearToSumOfGivingUSD.get(softCred.npsp__Opportunity__r.CloseDate.year());
                runningTotal += softCred.Amount_in_USD_Dated__c;
				yearToSumOfGivingUSD.put(softCred.npsp__Opportunity__r.CloseDate.year(), softCred.Amount_in_USD_Dated__c);
                runningTotal = yearToSumOfGivingAcctCurrency.get(softCred.npsp__Opportunity__r.CloseDate.year());
                runningTotal += softCred.Amount_in_Acct_Currency__c;
				yearToSumOfGivingAcctCurrency.put(softCred.npsp__Opportunity__r.CloseDate.year(), runningTotal);
            }           
        }
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            softCred.Amount_in_USD_Dated__c = softCred.Amount_in_USD_Dated__c != null ? softCred.Amount_in_USD_Dated__c : 0;
            softCred.Amount_in_Acct_Currency__c = softCred.Amount_in_Acct_Currency__c != null ? softCred.Amount_in_Acct_Currency__c : 0;            
            if (!yearToSumOfGivingUSD.containsKey(softCred.npsp__Opportunity__r.CloseDate.year())) {
                yearToSumOfGivingUSD.put(softCred.npsp__Opportunity__r.CloseDate.year(), softCred.Amount_in_USD_Dated__c);
                yearToSumOfGivingAcctCurrency.put(softCred.npsp__Opportunity__r.CloseDate.year(), softCred.Amount_in_Acct_Currency__c);
            }
            else {
                Decimal runningTotal = yearToSumOfGivingUSD.get(softCred.npsp__Opportunity__r.CloseDate.year());
                runningTotal += softCred.Amount_in_USD_Dated__c;
				yearToSumOfGivingUSD.put(softCred.npsp__Opportunity__r.CloseDate.year(), softCred.Amount_in_USD_Dated__c);
                runningTotal = yearToSumOfGivingAcctCurrency.get(softCred.npsp__Opportunity__r.CloseDate.year());
                runningTotal += softCred.Amount_in_Acct_Currency__c;
				yearToSumOfGivingAcctCurrency.put(softCred.npsp__Opportunity__r.CloseDate.year(), runningTotal);
            }
        }
        List<Integer> years = new List<Integer>();
        years.addAll(yearToSumOfGivingAcctCurrency.keySet());
        years.sort();
        System.debug(years);

        Integer bestGivingYear;
        Decimal bestGivingYearTotalUSD;
		Decimal bestGivingYearTotalAcctCurrency;        
        
        for (Integer i=years.size()-1; i>=0; i--) {
            if (i == years.size()-1) {
                bestGivingYear = years[i];
                bestGivingYearTotalUSD = yearToSumOfGivingUSD.get(bestGivingYear);
                bestGivingYearTotalAcctCurrency = yearToSumOfGivingAcctCurrency.get(bestGivingYear);
            }
            else if (yearToSumOfGivingAcctCurrency.get(years[i]) > bestGivingYearTotalAcctCurrency) {
                bestGivingYear = years[i];
                bestGivingYearTotalUSD = yearToSumOfGivingUSD.get(bestGivingYear);
                bestGivingYearTotalAcctCurrency = yearToSumOfGivingAcctCurrency.get(bestGivingYear);                
            }
        }
        
        if (bestGivingYear > 0) {
            a.npo02__Best_Gift_Year__c = String.valueOf(bestGivingYear);
            a.Best_Giving_Year_Total_USD__c = bestGivingYearTotalUSD;
            a.npo02__Best_Gift_Year_Total__c = bestGivingYearTotalAcctCurrency;
            a.Updated_Via_Apex_Trigger__c = true;
        }
        else {
            a.npo02__Best_Gift_Year__c = null;
            a.Best_Giving_Year_Total_USD__c = null;
            a.npo02__Best_Gift_Year_Total__c = null;
            a.Updated_Via_Apex_Trigger__c = true;
        }
        update a;
    }

	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job determining best giving year total: ' + job.Status);
    }

}