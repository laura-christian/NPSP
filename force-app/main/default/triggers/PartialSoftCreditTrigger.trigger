trigger PartialSoftCreditTrigger on npsp__Partial_Soft_Credit__c (before insert, before update, after insert) {
    

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            HardAndSoftCreditTriggerHandler.beforePartialSoftCredInsertOrUpdate(Trigger.new, Trigger.isInsert);
        }
        else if (Trigger.isUpdate) {
			List<npsp__Partial_Soft_Credit__c> creditAmtsChanged = new List<npsp__Partial_Soft_Credit__c>();
            for (npsp__Partial_Soft_Credit__c softCred : Trigger.new) {
                if (Trigger.oldMap.get(softCred.Id).npsp__Amount__c != softCred.npsp__Amount__c || Trigger.oldMap.get(softCred.Id).Amount_in_USD_Dated__c != softCred.Amount_in_USD_Dated__c || Trigger.oldMap.get(softCred.Id).Amount_in_Acct_Currency__c != softCred.Amount_in_Acct_Currency__c) {
                    creditAmtsChanged.add(softCred);
                }
            }
			if (!creditAmtsChanged.isEmpty()) {HardAndSoftCreditTriggerHandler.beforePartialSoftCredInsertOrUpdate(creditAmtsChanged, Trigger.isInsert);}
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
        	HardAndSoftCreditTriggerHandler.afterPartialSoftCredInsert(Trigger.new);            
        }
    } 
}