trigger AddressTrigger on npsp__Address__c (before insert, before update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
			AddressTriggerHandler.beforeInsert(Trigger.new);
        }
		AddressStandardization.normalizeAddress(Trigger.new);          
    }
   
    
}