trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            HardAndSoftCreditTriggerHandler.beforeOppInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            for (Opportunity o : Trigger.new) {
                if (((Trigger.oldMap.get(o.Id).Amount > 0 && o.Amount == 0) || (Trigger.oldMap.get(o.Id).Amount_in_USD_Dated__c > 0 && o.Amount_in_USD_Dated__c == 0) || (Trigger.oldMap.get(o.Id).Amount_in_Acct_Currency__c > 0 && o.Amount_in_Acct_Currency__c == 0)) && o.npe01__Number_of_Payments__c == 0 && o.ForecastCategory != 'Closed') {
                    o.Amount = Trigger.oldMap.get(o.Id).Amount;
                    o.Amount_in_USD_Dated__c = Trigger.oldMap.get(o.Id).Amount_in_USD_Dated__c;
                    o.Amount_in_Acct_Currency__c = Trigger.oldMap.get(o.Id).Amount_in_Acct_Currency__c;
                }
            }
            for (Opportunity o : Trigger.new) {
                if (Trigger.oldMap.get(o.Id).OwnerId != o.OwnerId && !o.Updated_Via_Trigger__c) {
                    o.addError('To change the owner of an opportunity you must add an opportunity team member with a role of Relationship Manager; you cannot change the owner directly.');
                }
                else {o.Updated_Via_Trigger__c = false;}
            }
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Set<Id> oppIdsCopyAllocInfo = new Set<Id>();
            List<Opportunity> recalcSoftCredAmtsInAcctCurrencies = new List<Opportunity>();
            // If there have been any changes to opportunity allocation details, reproduce those on child payment records
            for (Opportunity o : Trigger.new) {
                if (Trigger.oldMap.get(o.Id).Link_to_Supporting_Docs_for_GAU__c != o.Link_to_Supporting_Docs_for_GAU__c || Trigger.oldMap.get(o.Id).GAU_s__c != o.GAU_s__c) {
                    oppIdsCopyAllocInfo.add(o.Id);
                }
                if ((Trigger.oldMap.get(o.Id).Amount_in_USD_Dated__c != o.Amount_in_USD_Dated__c || Trigger.oldMap.get(o.Id).Amount_in_Acct_Currency__c != o.Amount_in_Acct_Currency__c) && o.ForecastCategory == 'Closed') {
                    recalcSoftCredAmtsInAcctCurrencies.add(o);
                }                
            }
            if (!oppIdsCopyAllocInfo.isEmpty()) {
                HardAndSoftCreditTriggerHandler.copyAllocationInfoToPmts(oppIdsCopyAllocInfo, Trigger.newMap);
            }
            if (!recalcSoftCredAmtsInAcctCurrencies.isEmpty()) {
                HardAndSoftCreditTriggerHandler.recalculateSoftCreditAmtsInUSDAndAcctCurrencies(recalcSoftCredAmtsInAcctCurrencies);
            }            
        }
        // Calculate account currency on insert of new closed opp, or when existing opp is marked closed won.
        // If closed gift has been hard credited to a giving arm, or household gift has been reparented
        // under a giving arm, automatically soft credit the household that was responsible for the gift        
        List<Opportunity> newOpps = new List<Opportunity>();
        List<Opportunity> closedOpps = new List<Opportunity>();
        Set<Id> acctIds = new Set<Id>();
        for (Opportunity o : Trigger.new) {
            if (Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(o.Id).RecordTypeId == '0128b000000XLooAAG' && (o.RecordTypeId == '0128b0000008A6sAAE' || o.RecordTypeId == '0128b000000XLolAAG' || o.RecordTypeId == '0128b000000XLokAAG' || o.RecordTypeId == '0128b0000012G2tAAE'))) {
                newOpps.add(o);
                acctIds.add(o.AccountId);
            }
            if ((Trigger.isInsert || Trigger.oldMap.get(o.Id).ForecastCategory != 'Closed') && o.ForecastCategory == 'Closed') {
                closedOpps.add(o);
                acctIds.add(o.AccountId);                
            }
        }
        // Query affiliations under hard-credited accounts where the affiliation type is 'Giving Arm' -- one or more
        // such affiliations indicates that the account is a giving arm    
        List<npe5__Affiliation__c> affiliations = [SELECT npe5__Contact__c, npe5__Contact__r.AccountId,
                                                   npe5__Contact__r.Account.Count_of_Open_Grants_Major_Gifts__c,
                                                   npe5__Contact__r.Account.Current_Relationship_Manager__c,
                                                   npe5__Organization__c, npe5__Organization__r.Current_Relationship_Manager__c
                                                   FROM npe5__Affiliation__c
                                                   WHERE npe5__Organization__c IN :acctIds
                                                   AND Type__c LIKE 'Giving Arm%'
                                                   ORDER BY npe5__Organization__c, npe5__Contact__r.AccountId];
        if (!affiliations.isEmpty()) {        
            HardAndSoftCreditTriggerHandler.handleGivingArmDonations(affiliations, closedOpps, newOpps);
        }
        if (!closedOpps.isEmpty()) {
            HardAndSoftCreditTriggerHandler.afterOppInsertOrUpdate(closedOpps);
        }
        
    }
    
}