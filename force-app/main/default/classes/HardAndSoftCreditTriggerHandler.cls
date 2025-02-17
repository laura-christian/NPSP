public class HardAndSoftCreditTriggerHandler {
    
    public static List<User> rtrUser = [SELECT Id FROM User WHERE Name = 'Room to Read' LIMIT 1];
    
    // Make generic RtR user default owner of all opps
    public static void beforeOppInsert(List<Opportunity> opps) {
        for (Opportunity o : opps) {
            o.OwnerId = !rtrUser.isEmpty() ? rtrUser[0].Id : UserInfo.getUserId();
        }
    }
    
	// Recalculate account currency after every opp insert
    public static void afterOppInsertOrUpdate(List<Opportunity> closedOpps) {
		Set<Id> acctIds = new Set<Id>();      
        for (Opportunity o : closedOpps) {
            acctIds.add(o.AccountId);
        }       
        List<Contact> allHouseholdMembers = [SELECT Id FROM Contact WHERE AccountId IN :acctIds];
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : allHouseholdMembers) {
            contactIds.add(c.Id);
        }
        setAcctCurrency(contactIds, acctIds);
    }
    
    //Prevent an opportunity from being double-credited to the same account
    public static void beforePartialSoftCredInsertOrUpdate(List<npsp__Partial_Soft_Credit__c> partialSoftCredits, Boolean isInsert) {
        Set<Id> oppIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<String> currencies = new Set<String>();        
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            oppIds.add(softCred.npsp__Opportunity__c);
            contactIds.add(softCred.npsp__Contact__c);
            currencies.add(softCred.CurrencyIsoCode);
        }
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.CurrencyIsoCode, CurrencyIsoCode, Amount, CloseDate, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c FROM Opportunity WHERE Id IN :oppIds]);
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds];
        Map<Id, Id> contactIdToAcctId = new Map<Id, Id>();
        Set<Id> acctIds = new Set<Id>();
        for (Contact c : contacts) {
            contactIdToAcctId.put(c.Id, c.AccountId);
            acctIds.add(c.AccountId);
        }
        Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, CurrencyIsoCode FROM Account WHERE Id IN :acctIds]);
        for (Account a : acctMap.values()) {
            currencies.add(a.CurrencyIsoCode);
        }
        Map<String, List<DatedConversionRate>> currencyToFXRates = getDatedConversionRates(currencies);
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            Id acctId = contactIdToAcctId.get(softCred.npsp__Contact__c);
            String acctCurrency = acctMap.get(acctId).CurrencyIsoCode;
            Decimal percentSoftCredited = 1;
            if (oppMap.get(softCred.npsp__Opportunity__c).Amount > 0) {percentSoftCredited = softCred.npsp__Amount__c/oppMap.get(softCred.npsp__Opportunity__c).Amount;}
        	softCred = calculatePartialSoftCreditAmts(softCred, oppMap, currencyToFXRates, acctCurrency, percentSoftCredited);
        }
        if (isInsert) {
            for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
                if (oppMap.get(softCred.npsp__Opportunity__c).AccountId == contactIdToAcctId.get(softCred.npsp__Contact__c)) {
                    softCred.addError('Do not soft credit a contact for an opportunity that\'s already been hard credited to their account');
                }
            }
            List<npsp__Partial_Soft_Credit__c> existingContactSoftCreds = [SELECT Id, npsp__Opportunity__c, npsp__Opportunity__r.Amount, 
                                                                           npsp__Contact__c, npsp__Contact__r.AccountId, npsp__Amount__c
                                                                           FROM npsp__Partial_Soft_Credit__c
                                                                           WHERE npsp__Opportunity__c IN :oppIds AND npsp__Contact__r.AccountId IN :contactIdToAcctId.values()];
            List<npsp__Account_Soft_Credit__c> existingAcctSoftCreds = [SELECT Id, npsp__Opportunity__c, npsp__Opportunity__r.Amount, 
                                                                        npsp__Account__c, npsp__Amount__c
                                                                        FROM npsp__Account_Soft_Credit__c
                                                                        WHERE npsp__Opportunity__c IN :oppIds AND npsp__Account__c IN :contactIdToAcctId.values()];
            for (npsp__Partial_Soft_Credit__c existingContactSoftCred : existingContactSoftCreds) {
                // Only checking for duplicates on soft credits for 100% of opportunity amount (to avoid throwing errors on HM Revenue & Custom soft credits, for instance)
                if (existingContactSoftCred.npsp__Amount__c == existingContactSoftCred.npsp__Opportunity__r.Amount) {
                    for (npsp__Partial_Soft_Credit__c newSoftCred : partialSoftCredits) {
                        if (newSoftCred.npsp__Opportunity__c == existingContactSoftCred.npsp__Opportunity__c && contactIdToAcctId.get(newSoftCred.npsp__Contact__c) == existingContactSoftCred.npsp__Contact__r.AccountId) {
                            newSoftCred.addError('Do not soft credit an opportunity to the same account twice');
                        }
                    }
                }
            }
            for (npsp__Account_Soft_Credit__c existingAcctSoftCred : existingAcctSoftCreds) {
                if ((existingAcctSoftCred.npsp__Amount__c == existingAcctSoftCred.npsp__Opportunity__r.Amount) || existingAcctSoftCred.Percent__c == 100) {
                    for (npsp__Partial_Soft_Credit__c newSoftCred : partialSoftCredits) {
                        if (newSoftCred.npsp__Opportunity__c == existingAcctSoftCred.npsp__Opportunity__c && contactIdToAcctId.get(newSoftCred.npsp__Contact__c) == existingAcctSoftCred.npsp__Account__c) {
                            newSoftCred.addError('Do not soft credit an opportunity to the same account twice');
                        }
                    }
                }
            }
        }  
    }
        
    // Recalculate account currency after every partial soft credit insert
    public static void afterPartialSoftCredInsert(List<npsp__Partial_Soft_Credit__c> partialSoftCredits) {
        Set<Id> contactIds = new Set<Id>();
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            contactIds.add(softCred.npsp__Contact__c);
        }
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds];
        Set<Id> acctIds = new Set<Id>();
        for (Contact c : contacts) {
            acctIds.add(c.AccountId);
        }
        setAcctCurrency(contactIds, acctIds);
    }
    
    // Calculate soft credit amount in USD and soft credit recipient's account currency; prevent an opportunity
    // from being double-credited to the same account
    public static void beforeAccountSoftCredInsertOrUpdate(List<npsp__Account_Soft_Credit__c> acctSoftCredits, Boolean isInsert) {
        Set<Id> oppIds = new Set<Id>();
        Set<Id> acctIds = new Set<Id>();
        Set<String> currencies = new Set<String>();
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            oppIds.add(softCred.npsp__Opportunity__c);
            acctIds.add(softCred.npsp__Account__c);
            currencies.add(softCred.CurrencyIsoCode);
        }
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.CurrencyIsoCode, CurrencyIsoCode, Amount, CloseDate, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c FROM Opportunity WHERE Id IN :oppIds]);
        Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, CurrencyIsoCode FROM Account WHERE Id IN :acctIds]);
        for (Account a : acctMap.values()) {
            currencies.add(a.CurrencyIsoCode);
        }
        Map<String, List<DatedConversionRate>> currencyToFXRates = getDatedConversionRates(currencies);
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            String acctCurrency = acctMap.get(softCred.npsp__Account__c).CurrencyIsoCode;
            Decimal percentSoftCredited = 1;
			if (softCred.Percent__c > 0) {
                percentSoftCredited = softCred.Percent__c/100;
                softCred.npsp__Amount__c = percentSoftCredited*oppMap.get(softCred.npsp__Opportunity__c).Amount;
            }
            else if (oppMap.get(softCred.npsp__Opportunity__c).Amount > 0) {percentSoftCredited = softCred.npsp__Amount__c/oppMap.get(softCred.npsp__Opportunity__c).Amount;}
        	softCred = calculateAcctSoftCreditAmts(softCred, oppMap, currencyToFXRates, acctCurrency, percentSoftCredited);
        }
        if (isInsert) {
            for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
                if (softCred.npsp__Account__c == oppMap.get(softCred.npsp__Opportunity__c).AccountId) {
                    softCred.addError('Do not soft credit an account for an opportunity that\'s already been hard credited to it');
                }
            }
            List<npsp__Partial_Soft_Credit__c> existingContactSoftCreds = [SELECT Id, npsp__Opportunity__c, npsp__Opportunity__r.Amount, 
                                                                           npsp__Contact__c, npsp__Contact__r.AccountId, npsp__Amount__c
                                                                           FROM npsp__Partial_Soft_Credit__c
                                                                           WHERE npsp__Opportunity__c IN :oppIds AND npsp__Contact__r.AccountId IN :acctIds];
            List<npsp__Account_Soft_Credit__c> existingAcctSoftCreds = [SELECT Id, npsp__Opportunity__c, npsp__Opportunity__r.Amount, 
                                                                        npsp__Account__c, npsp__Amount__c
                                                                        FROM npsp__Account_Soft_Credit__c
                                                                        WHERE npsp__Opportunity__c IN :oppIds AND npsp__Account__c IN :acctIds];
            for (npsp__Partial_Soft_Credit__c existingContactSoftCred : existingContactSoftCreds) {
                // Only checking for duplicates on soft credits for 100% of opportunity amount (to avoid throwing errors on HM Revenue & Custom soft credits, for instance)
                if (existingContactSoftCred.npsp__Amount__c == existingContactSoftCred.npsp__Opportunity__r.Amount) {
                    for (npsp__Account_Soft_Credit__c newSoftCred : acctSoftCredits) {
                        if (newSoftCred.npsp__Opportunity__c == existingContactSoftCred.npsp__Opportunity__c && newSoftCred.npsp__Account__c == existingContactSoftCred.npsp__Contact__r.AccountId) {
                            newSoftCred.addError('Do not soft credit an opportunity to the same account twice');
                        }
                    }
                }
            }
            for (npsp__Account_Soft_Credit__c existingAcctSoftCred : existingAcctSoftCreds) {
                if (existingAcctSoftCred.npsp__Amount__c == existingAcctSoftCred.npsp__Opportunity__r.Amount) {
                    for (npsp__Account_Soft_Credit__c newSoftCred : acctSoftCredits) {
                        if (newSoftCred.npsp__Opportunity__c == existingAcctSoftCred.npsp__Opportunity__c && newSoftCred.npsp__Account__c == existingAcctSoftCred.npsp__Account__c) {
                            newSoftCred.addError('Do not soft credit an opportunity to the same account twice');
                        }
                    }
                }
            }
        }
    }
    
    // Recalculate account currency after insert of new account soft credit
    public static void afterAccountSoftCredInsert(List<npsp__Account_Soft_Credit__c> acctSoftCredits) {
        Set<Id> acctIds = new Set<Id>();
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            acctIds.add(softCred.npsp__Account__c);
        }
        List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId IN :acctIds];
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contacts) {contactIds.add(c.Id);}
        setAcctCurrency(contactIds, acctIds);
    }
    
    public static void setAcctCurrency(Set<Id> contactIds, Set<Id> acctIds) {
		// Query all gifts on accounts with new hard or soft credits
        List<Opportunity> donations = [SELECT Id, AccountId, CurrencyIsoCode, CloseDate
                                       FROM Opportunity
                                       WHERE AccountId IN :acctIds AND RecordType.Name IN ('Donation', 'Grant', 'Conditional Grant',
                                       'Major Gift', 'Pledge') AND ForecastCategory = 'Closed'
                                       ORDER BY AccountId, CloseDate DESC];
        // Query all partial soft credits on accounts with new hard or soft credits
        List<npsp__Partial_Soft_Credit__c> partialSoftCredits = 
            [SELECT npsp__Contact__r.AccountId, CurrencyIsoCode, npsp__Opportunity__r.CloseDate 
			 FROM npsp__Partial_Soft_Credit__c
			 WHERE npsp__Contact__c IN :contactIds
             ORDER BY npsp__Contact__r.AccountId, npsp__Opportunity__r.CloseDate DESC];
		
        // Query all account soft credits on accounts with new hard or soft credits
        List<npsp__Account_Soft_Credit__c> acctSoftCredits =
            [SELECT npsp__Account__c, CurrencyIsoCode, npsp__Opportunity__r.CloseDate
             FROM npsp__Account_Soft_Credit__c
             WHERE npsp__Account__c IN :acctIds
             ORDER BY npsp__Account__c, npsp__Opportunity__r.CloseDate DESC];
        
        // The rather byzantine map structure below allows for maintenance of running 
        // count of hard and soft credits per currency per account -- we add to count as
        // we iterate over each set of query results
        Map<Id, List<Map<String, Integer>>> acctIdToCurrencyToCount = new Map<Id, List<Map<String, Integer>>>();
        for (Opportunity o : donations) {
            if (!acctIdToCurrencyToCount.containsKey(o.AccountId)) {
                acctIdToCurrencyToCount.put(o.AccountId, new List<Map<String, Integer>>());
                Map<String, Integer> currencyToCount = new Map<String, Integer>();
                currencyToCount.put(o.CurrencyIsoCode, 1);
                acctIdToCurrencyToCount.get(o.AccountId).add(currencyToCount);
            }
            else {
                List<Map<String, Integer>> currencyCounts = acctIdToCurrencyToCount.get(o.AccountId);
                Set<String> mappedCurrencies = new Set<String>();
                for (Map<String, Integer> currencyToCount : currencyCounts) {
                    mappedCurrencies.addAll(currencyToCount.keySet());
                    if (currencyToCount.containsKey(o.CurrencyIsoCode)) {
                        Integer currentCt = currencyToCount.get(o.CurrencyIsoCode);
                        currentCt += 1;
                        currencyToCount.put(o.CurrencyIsoCode, currentCt);
                    }
                }
                if (!mappedCurrencies.contains(o.CurrencyIsoCode)) {
                    Map<String, Integer> currencyToCount = new Map<String, Integer>();
                    currencyToCount.put(o.CurrencyIsoCode, 1);
                    acctIdToCurrencyToCount.get(o.AccountId).add(currencyToCount);                    
                }
            }
        }
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
             if (!acctIdToCurrencyToCount.containsKey(softCred.npsp__Contact__r.AccountId)) {
                acctIdToCurrencyToCount.put(softCred.npsp__Contact__r.AccountId, new List<Map<String, Integer>>());
                Map<String, Integer> currencyToCount = new Map<String, Integer>();
                currencyToCount.put(softCred.CurrencyIsoCode, 1);
                acctIdToCurrencyToCount.get(softCred.npsp__Contact__r.AccountId).add(currencyToCount);
            }
            else {
                List<Map<String, Integer>> currencyCounts = acctIdToCurrencyToCount.get(softCred.npsp__Contact__r.AccountId);
                Set<String> mappedCurrencies = new Set<String>();
                for (Map<String, Integer> currencyToCount : currencyCounts) {
                    mappedCurrencies.addAll(currencyToCount.keySet());
                    if (currencyToCount.containsKey(softCred.CurrencyIsoCode)) {
                        Integer currentCt = currencyToCount.get(softCred.CurrencyIsoCode);
                        currentCt += 1;
                        currencyToCount.put(softCred.CurrencyIsoCode, currentCt);
                    }
                }
                if (!mappedCurrencies.contains(softCred.CurrencyIsoCode)) {
                    Map<String, Integer> currencyToCount = new Map<String, Integer>();
                    currencyToCount.put(softCred.CurrencyIsoCode, 1);
                    acctIdToCurrencyToCount.get(softCred.npsp__Contact__r.AccountId).add(currencyToCount);                    
                }
            }           
        }
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
             if (!acctIdToCurrencyToCount.containsKey(softCred.npsp__Account__c)) {
                acctIdToCurrencyToCount.put(softCred.npsp__Account__c, new List<Map<String, Integer>>());
                Map<String, Integer> currencyToCount = new Map<String, Integer>();
                currencyToCount.put(softCred.CurrencyIsoCode, 1);
                acctIdToCurrencyToCount.get(softCred.npsp__Account__c).add(currencyToCount);
            }
            else {
                List<Map<String, Integer>> currencyCounts = acctIdToCurrencyToCount.get(softCred.npsp__Account__c);
                Set<String> mappedCurrencies = new Set<String>();
                for (Map<String, Integer> currencyToCount : currencyCounts) {
                    mappedCurrencies.addAll(currencyToCount.keySet());
                    if (currencyToCount.containsKey(softCred.CurrencyIsoCode)) {
                        Integer currentCt = currencyToCount.get(softCred.CurrencyIsoCode);
                        currentCt += 1;
                        currencyToCount.put(softCred.CurrencyIsoCode, currentCt);
                    }
                }
                if (!mappedCurrencies.contains(softCred.CurrencyIsoCode)) {
                    Map<String, Integer> currencyToCount = new Map<String, Integer>();
                    currencyToCount.put(softCred.CurrencyIsoCode, 1);
                    acctIdToCurrencyToCount.get(softCred.npsp__Account__c).add(currencyToCount);                    
                }
            }            
        }

        // Query all accounts with new hard or soft credits
        List<Account> acctsWithNewCreds = [SELECT Id, Name, CurrencyISOCode FROM Account WHERE Id IN :acctIds];
        List<Account> acctsToUpdate = new List<Account>();
        
        // Iterate over running counts of credits per currency per account and update
        // below maps as we go, keeping track of currency with the most credits
        Map<Id, Integer> acctIdToHighestCount = new Map<Id, Integer>();
        Map<Id, String> acctIdToISOCode = new Map<Id, String>();
        for (Id acctId : acctIdToCurrencyToCount.keySet()) {
            Integer highestCount;
            List<Map<String, Integer>> listOfMaps = acctIdToCurrencyToCount.get(acctId);
            for (Map<String, Integer> currencyToCount : listOfMaps) {
                String curr;
                for (String currencyIsoCode : currencyToCount.keySet()) {
                    curr = currencyIsoCode;
                    Integer count = currencyToCount.get(curr);
                    if (!acctIdToHighestCount.containsKey(acctId) || count > acctIdToHighestCount.get(acctId)) {
                        acctIdToHighestCount.put(acctId, count);
                        acctIdToISOCode.put(acctId, curr);
                    }
                }
            }
        }
        
        // If currency with highest count is different from current account currency,
        // add to list of accounts to update
        for (Account acct : acctsWithNewCreds) {
            if (acct.CurrencyISOCode!=acctIdToISOCode.get(acct.Id)) {
                acct.CurrencyISOCode=acctIdToISOCode.get(acct.Id);
                acctsToUpdate.add(acct);
            }
        }
        if (!acctsToUpdate.isEmpty()) {
            Database.saveResult[] saveResults = Database.update(acctsToUpdate, false);
            for (Integer i=0;i<saveResults.size();i++) {
                if (saveResults.get(i).isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated account record. Account Id: ' + saveResults.get(i).getId());
                }
                else {
                    System.debug('The following error has occurred:');                    
                    Database.Error error = saveResults.get(i).getErrors().get(0);
                    System.debug(error.getMessage());
                    System.debug('Id of record that failed to update: ' + acctsToUpdate[i].Id);
                }
            }
        }
    }
    
    public static void recalculateSoftCreditAmtsInUSDAndAcctCurrencies(List<Opportunity> opps) {
        Set<Id> oppIds = new Set<Id>();
		Set<Id> acctIds = new Set<Id>();
        Set<String> currencies = new Set<String>();
        for (Opportunity o : opps) {
            oppIds.add(o.Id);
            acctIds.add(o.AccountId);
            currencies.add(o.CurrencyIsoCode);
        }
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.CurrencyIsoCode, CurrencyIsoCode, Amount, CloseDate, Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c FROM Opportunity WHERE Id IN :oppIds]);     
		List<npsp__Account_Soft_Credit__c> acctSoftCredits = [SELECT Id, npsp__Account__c, npsp__Account__r.CurrencyIsoCode,
                                                              CurrencyIsoCode, npsp__Amount__c, Percent__c,
                                                              Amount_in_USD_Dated__c, Amount_in_Acct_Currency__c,
                                                              npsp__Opportunity__c, npsp__Opportunity__r.Amount,
                                                              npsp__Opportunity__r.CloseDate, 
                                                              npsp__Opportunity__r.Account.CurrencyIsoCode,
                                                              npsp__Opportunity__r.Amount_in_USD_Dated__c,
                                                              npsp__Opportunity__r.Amount_in_Acct_Currency__c
                                                              FROM npsp__Account_Soft_Credit__c
                                                              WHERE npsp__Opportunity__c IN :oppIds];
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            currencies.add(softCred.CurrencyIsoCode);
            currencies.add(softCred.npsp__Account__r.CurrencyIsoCode);
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
                                                                 WHERE npsp__Opportunity__c IN :oppIds];
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            currencies.add(softCred.CurrencyIsoCode);
            currencies.add(softCred.npsp__Contact__r.Account.CurrencyIsoCode);
        }
        Map<String, List<DatedConversionRate>> currencyToFXRates = getDatedConversionRates(currencies);
        List<npsp__Account_Soft_Credit__c> acctSoftCreditsToUpdate = new List<npsp__Account_Soft_Credit__c>();
        List<npsp__Partial_Soft_Credit__c> partialSoftCreditsToUpdate = new List<npsp__Partial_Soft_Credit__c>();
        for (npsp__Account_Soft_Credit__c softCred : acctSoftCredits) {
            String acctCurrency = softCred.npsp__Account__r.CurrencyIsoCode;
            Decimal percentSoftCredited = 1;
			if (softCred.Percent__c > 0) {percentSoftCredited = softCred.Percent__c/100;}
            else if (softCred.npsp__Opportunity__r.Amount > 0) {percentSoftCredited = softCred.npsp__Amount__c/softCred.npsp__Opportunity__r.Amount;}
			softCred = calculateAcctSoftCreditAmts(softCred, oppMap, currencyToFXRates, acctCurrency, percentSoftCredited);
            acctSoftCreditsToUpdate.add(softCred);
        }
        for (npsp__Partial_Soft_Credit__c softCred : partialSoftCredits) {
            String acctCurrency = softCred.npsp__Contact__r.Account.CurrencyIsoCode;
            Decimal percentSoftCredited = 1;
            if (softCred.npsp__Opportunity__r.Amount > 0) {percentSoftCredited = softCred.npsp__Amount__c/softCred.npsp__Opportunity__r.Amount;}
            softCred = calculatePartialSoftCreditAmts(softCred, oppMap, currencyToFXRates, acctCurrency, percentSoftCredited);
            partialSoftCreditsToUpdate.add(softCred);
        }
        if (!acctSoftCreditsToUpdate.isEmpty()) {Database.update(acctSoftCreditsToUpdate, false);}
        if (!partialSoftCreditsToUpdate.isEmpty()) {Database.update(partialSoftCreditsToUpdate, false);}        
		        
    }
    
    public static void copyAllocationInfoToPmts(Set<Id> oppIds, Map<Id, Opportunity> newOppMap) {
        // If payment allocations turned on, GAU info and link to supporting documentation will be rolled up from
        // those records onto payments instead of being copied over from opportunity
        List<npsp__Allocation__c> pmtAllocations = [SELECT Id, npsp__Payment__r.npe01__Opportunity__c FROM npsp__Allocation__c WHERE npsp__Payment__r.npe01__Opportunity__c IN :oppIds];
        for (npsp__Allocation__c alloc : pmtAllocations) {
            oppIds.remove(alloc.npsp__Payment__r.npe01__Opportunity__c);
        }
        // Query payments that do not have an allocation under them
        List<npe01__OppPayment__c> pmts = [SELECT Id, npe01__Opportunity__c, Link_to_Supporting_Docs_for_GAU__c, GAU_s__c
                                           FROM npe01__OppPayment__c
                                           WHERE npe01__Opportunity__c IN :oppIds];
        List<npe01__OppPayment__c> pmtsToUpdate = new List<npe01__OppPayment__c>();
        for (npe01__OppPayment__c pmt : pmts) {
            pmt.Link_to_Supporting_Docs_for_GAU__c = newOppMap.get(pmt.npe01__Opportunity__c).Link_to_Supporting_Docs_for_GAU__c;
            pmt.GAU_s__c = newOppMap.get(pmt.npe01__Opportunity__c).GAU_s__c;
            pmtsToUpdate.add(pmt);
        }
        if (!pmtsToUpdate.isEmpty()) {Database.update(pmtsToUpdate, false);}      
    }
    
    public static void handleGivingArmDonations(List<npe5__Affiliation__c> affiliations, List<Opportunity> closedOpps, List<Opportunity> newOpps) {
        // Map Ids of giving arm organizations to sets of Ids of the affiliated household
        // accounts, to determine whether this org is the giving arm of multiple
        // households or just one (if it is a giving arm for more than one household, soft
        // credits will need to be created manually)
        Map<Id, Set<Id>> givingArmToAffiliatedHouseholdAccountIds = new Map<Id, Set<Id>>();
        Map<Id, Decimal> householdAcctIdToNumberOfOpenGrantsMGs = new Map<Id, Decimal>();
        Map<Id, Id> householdAcctIdToCurrentRelationshipManagerId = new Map<Id, Id>();
        Map<Id, Id> givingArmIdToCurrentRelationshipManagerId = new Map<Id, Id>();        
        Map<Id, Id> contactToAccountIds = new Map<Id, Id>();
        for (npe5__Affiliation__c affiliation : affiliations) {
            if (!givingArmToAffiliatedHouseholdAccountIds.containsKey(affiliation.npe5__Organization__c)) {
                givingArmToAffiliatedHouseholdAccountIds.put(affiliation.npe5__Organization__c, new Set<Id>{affiliation.npe5__Contact__r.AccountId});
            }
            else {givingArmToAffiliatedHouseholdAccountIds.get(affiliation.npe5__Organization__c).add(affiliation.npe5__Contact__r.AccountId);}
            if (!householdAcctIdToNumberOfOpenGrantsMGs.containsKey(affiliation.npe5__Contact__r.AccountId)) {
                householdAcctIdToNumberOfOpenGrantsMGs.put(affiliation.npe5__Contact__r.AccountId, affiliation.npe5__Contact__r.Account.Count_of_Open_Grants_Major_Gifts__c);
            }
            if (!householdAcctIdToCurrentRelationshipManagerId.containsKey(affiliation.npe5__Contact__r.AccountId) && !String.isBlank(affiliation.npe5__Contact__r.Account.Current_Relationship_Manager__c)) {
                householdAcctIdToCurrentRelationshipManagerId.put(affiliation.npe5__Contact__r.AccountId, affiliation.npe5__Contact__r.Account.Current_Relationship_Manager__c);
            }
            if (!givingArmIdToCurrentRelationshipManagerId.containsKey(affiliation.npe5__Organization__c) && !String.isBlank(affiliation.npe5__Organization__r.Current_Relationship_Manager__c)) {givingArmIdToCurrentRelationshipManagerId.put(affiliation.npe5__Organization__c, affiliation.npe5__Organization__r.Current_Relationship_Manager__c);}
            if (!contactToAccountIds.containsKey(affiliation.npe5__Contact__c)) {
                contactToAccountIds.put(affiliation.npe5__Contact__c, affiliation.npe5__Contact__r.AccountId);
            }
            
        }
        // Now map giving arm Ids to list of all closed won hard credits
		Map<Id, List<Opportunity>> givingArmIdToRelatedClosedOpps = new Map<Id, List<Opportunity>>();
        for (Opportunity o : closedOpps) {
            if (givingArmToAffiliatedHouseholdAccountIds.containsKey(o.AccountId)) {
                if (!givingArmIdToRelatedClosedOpps.containsKey(o.AccountId)) {
                    givingArmIdToRelatedClosedOpps.put(o.AccountId, new List<Opportunity>{o});
                }
                else {givingArmIdToRelatedClosedOpps.get(o.AccountId).add(o);}                    
            }
        }
		Map<Id, List<Opportunity>> givingArmIdToRelatedNewOpps = new Map<Id, List<Opportunity>>();
        for (Opportunity o : newOpps) {
            if (givingArmToAffiliatedHouseholdAccountIds.containsKey(o.AccountId)) {
                if (!givingArmIdToRelatedNewOpps.containsKey(o.AccountId)) {
                    givingArmIdToRelatedNewOpps.put(o.AccountId, new List<Opportunity>{o});
                }
                else {givingArmIdToRelatedNewOpps.get(o.AccountId).add(o);}                    
            }
        }
		Set<Id> householdAcctIdsNewOppsUnderGivingArm = new Set<Id>();
        for (Id givingArmId : givingArmIdToRelatedNewOpps.keySet()) {
            for (Id householdId :  givingArmToAffiliatedHouseholdAccountIds.get(givingArmId)) {
                householdAcctIdsNewOppsUnderGivingArm.add(householdId);
            }
        }
        Map<Id, List<AccountTeamMember>> householdAcctIdToOtherATMs = new Map<Id, List<AccountTeamMember>>();        
        List<AccountTeamMember> otherATMs = [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :householdAcctIdsNewOppsUnderGivingArm AND TeamMemberRole IN ('Team Member', 'Primary Player', 'PR Lead') AND Status__c = 'Current'];
        for (AccountTeamMember atm : otherATMs) {
            if (!householdAcctIdToOtherATMs.containsKey(atm.AccountId)) {
                householdAcctIdToOtherATMs.put(atm.AccountId, new List<AccountTeamMember>{atm});
            }
            else {householdAcctIdToOtherATMs.get(atm.AccountId).add(atm);}
        }
		List<CollaborationGroup> gbo = [SELECT Id, Name FROM CollaborationGroup WHERE Name = 'GBO' LIMIT 1];
		List<npsp__Account_Soft_Credit__c> acctSoftCreditsToInsert = new List<npsp__Account_Soft_Credit__c>();        
        List<OpportunityTeamMember> oppTeamMembersToInsert = new List<OpportunityTeamMember>();
        for (Id givingArmId : givingArmToAffiliatedHouseholdAccountIds.keySet()) {
            // Check to make sure giving arm serves no more than one account
            if (givingArmToAffiliatedHouseholdAccountIds.get(givingArmId).size() == 1) {
                for (Id householdAcctId : givingArmToAffiliatedHouseholdAccountIds.get(givingArmId)) {
                    if (givingArmIdToRelatedClosedOpps.containsKey(givingArmId)) {
                        for (Opportunity o : givingArmIdToRelatedClosedOpps.get(givingArmId)) {
                            npsp__Account_Soft_Credit__c acctSoftCred = new npsp__Account_Soft_Credit__c(
                                npsp__Opportunity__c = o.Id,
                                npsp__Account__c = householdAcctId,
                                npsp__Amount__c = o.Amount,
                                CurrencyIsoCode = o.CurrencyIsoCode,
                                npsp__Role__c = 'Soft Credit');
                            acctSoftCreditsToInsert.add(acctSoftCred);
                            if (householdAcctIdToNumberOfOpenGrantsMGs.containsKey(householdAcctId) && householdAcctIdToNumberOfOpenGrantsMGs.get(householdAcctId) > 0 && FirstRunHelperClass.firstRun && o.CloseDate.year() == System.today().year()) {
                                // Post chatter alert in case gift coming through giving arm represents the fulfillment of
                                // commitment made in relation to a major gift on the related household
                                ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();                
                                ConnectApi.MentionSegmentInput gboMentionSegmentInput = new ConnectApi.MentionSegmentInput();
                                ConnectApi.MentionSegmentInput rmMentionSegmentInput = new ConnectApi.MentionSegmentInput();
                                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                                
                                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                                
                                if (householdAcctIdToCurrentRelationshipManagerId.containsKey(householdAcctId)) {
                                    rmMentionSegmentInput.id = householdAcctIdToCurrentRelationshipManagerId.get(householdAcctId);
                                	messageBodyInput.messageSegments.add(rmMentionSegmentInput);                                
                                    ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
                                    textSegmentInput1.text = ': The account to which this hard credit just posted is the giving arm ' + 
                                        'for a household of which you are the RM. That household currently has an open grant or major gift. Would you ' +
                                        'like for ';
                                    messageBodyInput.messageSegments.add(textSegmentInput1);
                                    if (!gbo.isEmpty()) {gboMentionSegmentInput.id = gbo[0].Id;
                                        messageBodyInput.messageSegments.add(gboMentionSegmentInput);
                                    }
                                    else {
                                        ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                                        textSegmentInput2.text = 'GBO';
                                        messageBodyInput.messageSegments.add(textSegmentInput2);                                    
                                    }
                                    ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                                    textSegmentInput3.text = ' to move the open household gift into the giving arm and apply this credit to it?';
                                    messageBodyInput.messageSegments.add(textSegmentInput3);                                 
                                }
                                else {
                                    if (!gbo.isEmpty()) {gboMentionSegmentInput.id = gbo[0].Id;
                                        messageBodyInput.messageSegments.add(gboMentionSegmentInput);
                                    }
                                    else {
                                        ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
                                        textSegmentInput1.text = 'Hey, GBO';
                                        messageBodyInput.messageSegments.add(textSegmentInput1);                                    
                                    }
                                    ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();                                    
                                    textSegmentInput2.text = ': The account to which this hard credit just posted is the giving arm ' + 
                                        'for a household with at least one open grant or major gift, but the household does not have an RM. ' +
                                        'Please determine if the credit should be applied to the open household gift and which RM may have solicited it.';
                                    messageBodyInput.messageSegments.add(textSegmentInput2);                                    
                                }
                                feedItemInput.body = messageBodyInput;
                                feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                                feedItemInput.subjectId = o.Id;
                                if (!Test.isRunningTest()) {ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                                    FirstRunHelperClass.firstRun = false;
                                }                             
                            }                       
                        }
                    }
                	if (givingArmIdToRelatedNewOpps.containsKey(givingArmId) && !givingArmIdToCurrentRelationshipManagerId.containsKey(givingArmId)) {    
                        for (Opportunity o : givingArmIdToRelatedNewOpps.get(givingArmId)) {
                            if (householdAcctIdToCurrentRelationshipManagerId.containsKey(householdAcctId) && o.Count_of_Gift_Solicitors__c == 0) {
                                OpportunityTeamMember otm = new OpportunityTeamMember(
                                OpportunityId = o.Id,
                                UserId = householdAcctIdToCurrentRelationshipManagerId.get(householdAcctId),
                                TeamMemberRole = 'Relationship Manager');
                                oppTeamMembersToInsert.add(otm);
                            }
                            if (householdAcctIdToOtherATMs.containsKey(householdAcctId) && (o.RecordTypeId == '0128b0000008A6sAAE' || o.RecordTypeId == '0128b000000XLolAAG' || o.RecordTypeId == '0128b000000XLokAAG' || o.RecordTypeId == '0128b0000012G2tAAE')) {
                                for (AccountTeamMember atm : householdAcctIdToOtherATMs.get(householdAcctId)) {
                                    OpportunityTeamMember otm = new OpportunityTeamMember(
                                    OpportunityId = o.Id,
                                    UserId = atm.UserId,
                                    TeamMemberRole = atm.TeamMemberRole);
                                    oppTeamMembersToInsert.add(otm);
                                } 
                            }
                        }
                	}
                }
            }
            // If the organizational account is a giving arm for more than one household,
            // post a message to Chatter
            else {
                if (givingArmIdToRelatedClosedOpps.containsKey(givingArmId)) {
                    for (Opportunity o : givingArmIdToRelatedClosedOpps.get(givingArmId)) {
                        // If gift has been moved from a household to a giving arm account or a primary contact was designated when the gift
                        // was first created on the giving arm, the contact Id will reside on the opportunity record in connection with the 
                        // donor's opportunity contact role. We can make use of this contact Id to determine which account should be soft credited for the gift
                        // when the hard credited account is a giving arm for more than one household
                        if (!String.isBlank(o.npe01__Contact_Id_for_Role__c) && contactToAccountIds.containsKey(o.npe01__Contact_Id_for_Role__c)) {
                            npsp__Account_Soft_Credit__c acctSoftCred = new npsp__Account_Soft_Credit__c(
                                npsp__Opportunity__c = o.Id,
                                npsp__Account__c = contactToAccountIds.get(o.npe01__Contact_Id_for_Role__c),
                                npsp__Amount__c = o.Amount,
                                CurrencyIsoCode = o.CurrencyIsoCode,
                                npsp__Role__c = 'Soft Credit');
                            acctSoftCreditsToInsert.add(acctSoftCred);                        
                        }
                        else {
                            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();                
                            ConnectApi.MentionSegmentInput gboMentionSegmentInput = new ConnectApi.MentionSegmentInput();
                            ConnectApi.MentionSegmentInput rmMentionSegmentInput = new ConnectApi.MentionSegmentInput();
                            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                            
                            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                            
                            if (givingArmIdToCurrentRelationshipManagerId.containsKey(givingArmId)) {
                                rmMentionSegmentInput.id = givingArmIdToCurrentRelationshipManagerId.get(givingArmId);
                                messageBodyInput.messageSegments.add(rmMentionSegmentInput);                                
                                ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
                                textSegmentInput1.text = ': The account to which this hard credit just posted appears to be the giving arm ' + 
                                    'for more than one household. Please advise ';
                                messageBodyInput.messageSegments.add(textSegmentInput1);
                                if (!gbo.isEmpty()) {gboMentionSegmentInput.id = gbo[0].Id;
                                    messageBodyInput.messageSegments.add(gboMentionSegmentInput);
                                }
                                else {
                                    ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                                    textSegmentInput2.text = 'GBO';
                                    messageBodyInput.messageSegments.add(textSegmentInput2);                                    
                                }
                                ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                                textSegmentInput3.text = ' as to which household is responsible for the gift and should receive ' +
                                    'a soft credit for it. Please also let GBO know if this credit should be applied to any open ' +
                                    'household gift.';
                                messageBodyInput.messageSegments.add(textSegmentInput3);                                 
                            }
                            else {
                                if (!gbo.isEmpty()) {gboMentionSegmentInput.id = gbo[0].Id;
                                    messageBodyInput.messageSegments.add(gboMentionSegmentInput);
                                }
                                else {
                                    ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
                                    textSegmentInput1.text = 'Hey, GBO';
                                    messageBodyInput.messageSegments.add(textSegmentInput1);                                    
                                }
                                ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();                                    
                                textSegmentInput2.text = ': The account to which this hard credit just posted appears to be a giving arm ' + 
                                'for more than one household. Please determine which affiliated household is responsible for the gift and soft credit the household accordingly. ' +
                                'Please also check to see whether the household has an open major gift, and if it does, inquire with the ' +
                                'RM as to whether this credit should be applied to it.';
                                messageBodyInput.messageSegments.add(textSegmentInput2);                                    
                            }
                            feedItemInput.body = messageBodyInput;
                            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                            feedItemInput.subjectId = o.Id;
                            if (!Test.isRunningTest()) {ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                                FirstRunHelperClass.firstRun = false;
                            }                             
                        }
                    }
                }
            }
        }
		if (!acctSoftCreditsToInsert.isEmpty()) {
            Database.saveResult[] saveResults = Database.insert(acctSoftCreditsToInsert, false);
            for (Integer i=0;i<saveResults.size();i++) {
                if (saveResults.get(i).isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully created account soft credit. Record Id: ' + saveResults.get(i).getId());
                }
                else {
                    System.debug('The record could not be created due to the following error:');                    
                    Database.Error error = saveResults.get(i).getErrors().get(0);
                    System.debug(error.getMessage());
                }
            }
        }
		if (!oppTeamMembersToInsert.isEmpty()) {
            Database.saveResult[] saveResults = Database.insert(oppTeamMembersToInsert, false);
            for (Integer i=0;i<saveResults.size();i++) {
                if (saveResults.get(i).isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully created opportunity team member. Record Id: ' + saveResults.get(i).getId());
                }
                else {
                    System.debug('The record could not be created due to the following error:');                    
                    Database.Error error = saveResults.get(i).getErrors().get(0);
                    System.debug(error.getMessage());
                }
            }
        }
    }
    
    public static Map<String, List<DatedConversionRate>> getDatedConversionRates(Set<String> currencies) {
        List<DatedConversionRate> DCRs = [SELECT IsoCode, StartDate, NextStartDate, ConversionRate
                                          FROM DatedConversionRate
                                          WHERE IsoCode IN :currencies
                                          ORDER BY IsoCode, StartDate DESC];
        Map<String, List<DatedConversionRate>> currencyToFXRates = new Map<String, List<DatedConversionRate>>();
        for (DatedConversionRate dcr : DCRs) {
            if (!currencyToFXRates.containsKey(dcr.IsoCode)) {
                currencyToFXRates.put(dcr.IsoCode, new List<DatedConversionRate>{dcr});
            }
            else {
                currencyToFXRates.get(dcr.IsoCode).add(dcr);
            }
        }
		return currencyToFXRates;        
    }
    
    public static npsp__Account_Soft_Credit__c calculateAcctSoftCreditAmts(npsp__Account_Soft_Credit__c softCred, Map<Id, Opportunity> oppMap, Map<String, List<DatedConversionRate>> currencyToFXRates, String acctCurrency, Decimal percentSoftCredited) {
        Decimal softCredAmtInUSD;
        Decimal softCredAmtInAcctCurrency;
        if (softCred.CurrencyIsoCode == 'USD') {
            softCred.Amount_in_USD_Dated__c = softCred.npsp__Amount__c;
        }
        else if (oppMap.get(softCred.npsp__Opportunity__c).Amount_in_USD_Dated__c != null) {
            softCredAmtInUSD = percentSoftCredited*oppMap.get(softCred.npsp__Opportunity__c).Amount_in_USD_Dated__c;
            softCred.Amount_in_USD_Dated__c = softCredAmtInUSD.setScale(2);                
        }
        else {
            Decimal conversionRate;
            List<DatedConversionRate> conversionRates = currencyToFXRates.get(softCred.CurrencyIsoCode);
            for (DatedConversionRate dcr : conversionRates) {
                if (dcr.StartDate <= oppMap.get(softCred.npsp__Opportunity__c).CloseDate && dcr.NextStartDate > oppMap.get(softCred.npsp__Opportunity__c).CloseDate) {
                    conversionRate = dcr.ConversionRate;
                    break;
                }                    
            }
            if (softCred.npsp__Amount__c != null && conversionRate != null) {
                softCredAmtInUSD = softCred.npsp__Amount__c/conversionRate;
                softCred.Amount_in_USD_Dated__c = softCredAmtInUSD.setScale(2);
            }                
        }
        if (acctCurrency == 'USD') {
            softCred.Amount_in_Acct_Currency__c = softCred.Amount_in_USD_Dated__c;
        }
        else if (acctCurrency == softCred.CurrencyIsoCode) {
            softCred.Amount_in_Acct_Currency__c = softCred.npsp__Amount__c;
        }
        else if (acctCurrency == oppMap.get(softCred.npsp__Opportunity__c).Account.CurrencyIsoCode && oppMap.get(softCred.npsp__Opportunity__c).Amount_in_Acct_Currency__c != null) {
            softCredAmtInAcctCurrency = percentSoftCredited*oppMap.get(softCred.npsp__Opportunity__c).Amount_in_Acct_Currency__c;
            softCred.Amount_in_Acct_Currency__c = acctCurrency == 'JPY' ? softCredAmtInAcctCurrency.setScale(0) : softCredAmtInAcctCurrency.setScale(2);
        }
        else {
            Decimal acctCurrencyConversionRate;
            List<DatedConversionRate> conversionRates = currencyToFXRates.get(acctCurrency);
            for (DatedConversionRate dcr : conversionRates) {
                if (dcr.StartDate <= oppMap.get(softCred.npsp__Opportunity__c).CloseDate && dcr.NextStartDate > oppMap.get(softCred.npsp__Opportunity__c).CloseDate) {
                    acctCurrencyConversionRate = dcr.ConversionRate;
                    break;
                }                    
            }
			if (acctCurrencyConversionRate != null) {
            	softCredAmtInAcctCurrency = softCred.Amount_in_USD_Dated__c*acctCurrencyConversionRate;
            	softCred.Amount_in_Acct_Currency__c = acctCurrency == 'JPY' ? softCredAmtInAcctCurrency.setScale(0) : softCredAmtInAcctCurrency.setScale(2);    
            }                
        }
        return softCred;    
    }
    
    public static npsp__Partial_Soft_Credit__c calculatePartialSoftCreditAmts(npsp__Partial_Soft_Credit__c softCred, Map<Id, Opportunity> oppMap, Map<String, List<DatedConversionRate>> currencyToFXRates, String acctCurrency, Decimal percentSoftCredited) {
        Decimal softCredAmtInUSD;
        Decimal softCredAmtInAcctCurrency;
        if (softCred.CurrencyIsoCode == 'USD') {
            softCred.Amount_in_USD_Dated__c = softCred.npsp__Amount__c;
        }
        else if (oppMap.get(softCred.npsp__Opportunity__c).Amount_in_USD_Dated__c != null) {
            softCredAmtInUSD = percentSoftCredited*oppMap.get(softCred.npsp__Opportunity__c).Amount_in_USD_Dated__c;
            softCred.Amount_in_USD_Dated__c = softCredAmtInUSD.setScale(2);                
        }
        else {
            Decimal conversionRate;
            List<DatedConversionRate> conversionRates = currencyToFXRates.get(softCred.CurrencyIsoCode);
            for (DatedConversionRate dcr : conversionRates) {
                if (dcr.StartDate <= oppMap.get(softCred.npsp__Opportunity__c).CloseDate && dcr.NextStartDate > oppMap.get(softCred.npsp__Opportunity__c).CloseDate) {
                    conversionRate = dcr.ConversionRate;
                    break;
                }                    
            }
            if (softCred.npsp__Amount__c != null && conversionRate != null) {
                softCredAmtInUSD = softCred.npsp__Amount__c/conversionRate;
                softCred.Amount_in_USD_Dated__c = softCredAmtInUSD.setScale(2);
            }                
        }
        if (acctCurrency == 'USD') {
            softCred.Amount_in_Acct_Currency__c = softCred.Amount_in_USD_Dated__c;
        }
        else if (acctCurrency == softCred.CurrencyIsoCode) {
            softCred.Amount_in_Acct_Currency__c = softCred.npsp__Amount__c;
        }
        else if (acctCurrency == oppMap.get(softCred.npsp__Opportunity__c).Account.CurrencyIsoCode && oppMap.get(softCred.npsp__Opportunity__c).Amount_in_Acct_Currency__c != null) {
            softCredAmtInAcctCurrency = percentSoftCredited*oppMap.get(softCred.npsp__Opportunity__c).Amount_in_Acct_Currency__c;
            softCred.Amount_in_Acct_Currency__c = acctCurrency == 'JPY' ? softCredAmtInAcctCurrency.setScale(0) : softCredAmtInAcctCurrency.setScale(2);
        }
        else {
            Decimal acctCurrencyConversionRate;
            List<DatedConversionRate> conversionRates = currencyToFXRates.get(acctCurrency);
            for (DatedConversionRate dcr : conversionRates) {
                if (dcr.StartDate <= oppMap.get(softCred.npsp__Opportunity__c).CloseDate && dcr.NextStartDate > oppMap.get(softCred.npsp__Opportunity__c).CloseDate) {
                    acctCurrencyConversionRate = dcr.ConversionRate;
                    break;
                }                    
            }
            if (softCred.Amount_in_USD_Dated__c != null && acctCurrencyConversionRate != null) {
                softCredAmtInAcctCurrency = softCred.Amount_in_USD_Dated__c*acctCurrencyConversionRate;
                softCred.Amount_in_Acct_Currency__c = acctCurrency == 'JPY' ? softCredAmtInAcctCurrency.setScale(0) : softCredAmtInAcctCurrency.setScale(2);
                
            }                
        }
        return softCred;
    }    

}