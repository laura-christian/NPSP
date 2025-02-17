trigger DuplicateRecordSetTrigger on DuplicateRecordSet (before delete) {
    
    List<DuplicateRecordItem> dupeRecItems = 
        [SELECT Id, RecordId, DuplicateRecordSetId, DuplicateRecordSet.DuplicateRuleId 
		 FROM DuplicateRecordItem
		 WHERE DuplicateRecordSetId IN :Trigger.Old];
    System.debug('Number of duplicate record items being deleted: ' + dupeRecItems.size());
    Set<Id> contactIds = new Set<Id>();
    for (DuplicateRecordItem dri : dupeRecItems) {
		contactIds.add(dri.RecordId);             
    }
    if (!contactIds.isEmpty()) {
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id IN :contactIds AND Review_Before_Emailing__c = true];
        for (Contact c : contacts) {
            c.Review_Before_Emailing__c = false;
            contactsToUpdate.add(c);
        }
        Database.update(contactsToUpdate, false);
    }
}