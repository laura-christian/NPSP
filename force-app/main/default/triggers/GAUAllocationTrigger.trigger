trigger GAUAllocationTrigger on npsp__Allocation__c (before insert, before update, after insert, after update) {

    Set<Id> relatedOppIds = new Set<Id>();
    Set<Id> relatedPmtIds = new Set<Id>();
    for (npsp__Allocation__c alloc : Trigger.new) {
        if (!String.isBlank(alloc.npsp__Opportunity__c)) {
            relatedOppIds.add(alloc.npsp__Opportunity__c);
        }
        else if (!String.isBlank(alloc.npsp__Payment__c)) {relatedPmtIds.add(alloc.npsp__Payment__c);}
    	}    
        Map<Id, Opportunity> allocatedOppMap = new Map<Id, Opportunity>([SELECT Id, Amount FROM Opportunity WHERE Id IN :relatedOppIds]);
        Map<Id, npe01__OppPayment__c > allocatedPmtMap = new Map<Id, npe01__OppPayment__c >([SELECT Id, npe01__Payment_Amount__c FROM npe01__OppPayment__c  WHERE Id IN :relatedPmtIds]);    
    if (Trigger.isBefore) {
        // Ensure that allocation percentage is always filled in
        for (npsp__Allocation__c alloc : Trigger.new) {
            if (!String.isBlank(alloc.npsp__Opportunity__c) && allocatedOppMap.containsKey(alloc.npsp__Opportunity__c) && alloc.npsp__Amount__c != null && alloc.npsp__Percent__c == null && allocatedOppMap.get(alloc.npsp__Opportunity__c).Amount != 0) {
                alloc.npsp__Percent__c = alloc.npsp__Amount__c/allocatedOppMap.get(alloc.npsp__Opportunity__c).Amount*100;
            }
            else if (!String.isBlank(alloc.npsp__Payment__c) && allocatedPmtMap.containsKey(alloc.npsp__Payment__c) && allocatedPmtMap.get(alloc.npsp__Payment__c).npe01__Payment_Amount__c != null && allocatedPmtMap.get(alloc.npsp__Payment__c).npe01__Payment_Amount__c != 0 && alloc.npsp__Percent__c == null) {alloc.npsp__Percent__c = alloc.npsp__Amount__c/allocatedPmtMap.get(alloc.npsp__Payment__c).npe01__Payment_Amount__c*100;}
        }
        Set<Id> GAUIds = new Set<Id>();
        for (npsp__Allocation__c alloc : Trigger.new) {
            GAUIds.add(alloc.npsp__General_Accounting_Unit__c);
        }
        Map<Id, npsp__General_Accounting_Unit__c> GAUs = new Map<Id, npsp__General_Accounting_Unit__c>([SELECT Id, Name FROM npsp__General_Accounting_Unit__c WHERE Id IN :GAUIds]);
        for (npsp__Allocation__c alloc : Trigger.new) {
            alloc.GAU_and_Percent_Allocated__c = GAUs.get(alloc.npsp__General_Accounting_Unit__c).Name + ': '  + String.valueOf(alloc.npsp__Percent__c.setScale(0)) + '%';
        }
    }
    if (Trigger.isAfter) {
        List<npsp__Allocation__c> allocations = [SELECT Id, GAU_and_Percent_Allocated__c, Link_to_Supporting_Docs_for_GAU__c, npsp__Opportunity__c FROM npsp__Allocation__c WHERE npsp__Opportunity__c IN :relatedOppIds ORDER BY npsp__Opportunity__c];
    	Map<Id, List<npsp__Allocation__c>> oppIdToAllocsMap = new Map<Id, List<npsp__Allocation__c>>();
        for (npsp__Allocation__c alloc : allocations) {
            if (!oppIdToAllocsMap.containsKey(alloc.npsp__Opportunity__c)) {
                oppIdToAllocsMap.put(alloc.npsp__Opportunity__c, new List<npsp__Allocation__c>{alloc});
            }
            else {oppIdToAllocsMap.get(alloc.npsp__Opportunity__c).add(alloc);}
        }
        for (Id oppId : oppIdToAllocsMap.keySet()) {
            List<String> GAUs = new List<String>();
            List<String> supportingDocs = new List<String>();
            for (npsp__Allocation__c alloc : oppIdToAllocsMap.get(oppId)) {
                GAUs.add(alloc.GAU_and_Percent_Allocated__c);
                supportingDocs.add(alloc.Link_to_Supporting_Docs_for_GAU__c);
            }
            allocatedOppMap.get(oppId).GAU_s__c = String.join(GAUs, '; ');
            allocatedOppMap.get(oppId).Link_to_Supporting_Docs_for_GAU__c = String.join(supportingDocs, '; ');
        }
        Database.update(allocatedOppMap.values(), false);
    }
    
}