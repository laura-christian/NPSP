trigger DuplicateRecordItemTrigger on DuplicateRecordItem (after insert, after delete) {

    Map<Id, DuplicateRule> duplicateLeadRuleMap = new Map<Id, DuplicateRule>(
        [SELECT Id 
         FROM DuplicateRule 
         WHERE MasterLabel = 'Standard Rule for New Leads with Duplicate Leads']);
    Map<Id, DuplicateRule> leadWithDupeContactRuleMap = new Map<Id, DuplicateRule>(
        [SELECT Id 
         FROM DuplicateRule 
         WHERE MasterLabel = 'Standard Rule for New Leads with Duplicate Contacts']);    
    Map<Id, DuplicateRule> contactWithDupeLeadRuleMap = new Map<Id, DuplicateRule>(
        [SELECT Id 
         FROM DuplicateRule 
         WHERE MasterLabel = 'Standard Rule for New Contacts with Duplicate Leads']);
    Map<Id, DuplicateRule> duplicateContactRuleMap = new Map<Id, DuplicateRule>(
        [SELECT Id
         FROM DuplicateRule
         WHERE MasterLabel = 'Standard Rule for New Contacts with Duplicate Contacts']);
    Map<Id, DuplicateRule> duplicateContactMatchingAddress = new Map<Id, DuplicateRule>(
        [SELECT Id
         FROM DuplicateRule
         WHERE MasterLabel = 'Rule for New Contacts with Matching Addresses']);   
    Map<Id, DuplicateRule> contactWithLeadHavingMatchingEmailOnly = new Map<Id, DuplicateRule>(
        [SELECT Id 
         FROM DuplicateRule 
         WHERE MasterLabel = 'Rule for New Contacts Having Leads with Matching Email (Only)']);
    Map<Id, DuplicateRule> contactMatchNonPreferredEmail = new Map<Id, DuplicateRule>(
        [SELECT Id 
         FROM DuplicateRule 
         WHERE MasterLabel = 'Rule for New Contacts with Match on Non-Preferred Email Address']);
    Map<Id, DuplicateRule> leadsMatchingEmailOnly = new Map<Id, DuplicateRule>(
        [SELECT Id 
         FROM DuplicateRule 
         WHERE MasterLabel = 'Rule for New Leads Having Leads with Matching Email (Only)']); 
    Map<Id, DuplicateRule> leadWithContactHavingMatchingEmailOnly = new Map<Id, DuplicateRule>(
        [SELECT Id 
         FROM DuplicateRule 
         WHERE MasterLabel = 'Rule for New Leads Having Contacts with Matching Email (Only)']);
    
	if (Trigger.isInsert) {
    	System.debug('>>>>Duplicate record item(s) created...');
        // When a new duplicate record item is created, determine the particular rule according
        // to which the corresponding record was flagged as a duplicate
        Set<Id> dupeRecSetIds = new Set<Id>();
    	for (DuplicateRecordItem dri : Trigger.New) {
            dupeRecSetIds.add(dri.DuplicateRecordSetId);
        }
        List<DuplicateRecordSet> dupeRecSets = [SELECT Id, DuplicateRuleId
                                                FROM DuplicateRecordSet
                                                WHERE Id IN :dupeRecSetIds];
        List<DuplicateRecordSet> dupeLeadRecSets = new List<DuplicateRecordSet>();
        List<DuplicateRecordSet> dupeLeadContactRecSets = new List<DuplicateRecordSet>();
        List<DuplicateRecordSet> dupeContactRecSets = new List<DuplicateRecordSet>();
        List<DuplicateRecordSet> contactMatchingEmailOnly = new List<DuplicateRecordSet>();
        // Sort duplicate record sets between those whose creation was triggered by the insertion/update
        // of a lead, and those whose creation was triggered by the insertion/update of a contact;
        // if the lead was created *after* there was already a contact record in the system for the 
        // individual, we'll just transcribe any pertinent details from the lead record onto the contact
        // record and delete the duplicate lead. On the other hand, if the lead record was created first
        // and a contact record was subsequently created when the individual first gave to RtR, the original
        // lead record will be converted/merged into their contact record.
        for (DuplicateRecordSet drs : dupeRecSets) {
            if (duplicateLeadRuleMap.containsKey(drs.DuplicateRuleId) || leadsMatchingEmailOnly.containsKey(drs.DuplicateRuleId)) {
                dupeLeadRecSets.add(drs);
            }
            else if (contactWithDupeLeadRuleMap.containsKey(drs.DuplicateRuleId) || leadWithDupeContactRuleMap.containsKey(drs.DuplicateRuleId)
                     || leadWithContactHavingMatchingEmailOnly.containsKey(drs.DuplicateRuleId) || contactWithLeadHavingMatchingEmailOnly.containsKey(drs.DuplicateRuleId)) {
                dupeLeadContactRecSets.add(drs);
            }
            else if (duplicateContactRuleMap.containsKey(drs.DuplicateRuleId) || duplicateContactMatchingAddress.containsKey(drs.DuplicateRuleId) || contactMatchNonPreferredEmail.containsKey(drs.DuplicateRuleId)) {
                dupeContactRecSets.add(drs);
            }
        }        
        if (!dupeLeadRecSets.isEmpty()) {
            System.debug('Executing batch class to dedupe leads...');
            Database.executeBatch(new BatchDedupeLeads(dupeLeadRecSets), 1);
        }
        if (!dupeLeadContactRecSets.isEmpty()) {
            System.debug('Executing batch class to convert leads to contacts...');
            Database.executeBatch(new BatchConvertLeadsToContacts(dupeLeadContactRecSets), 1);
        }
        if (!dupeContactRecSets.isEmpty()) {
            List<DuplicateRecordItem> dupeContactRecItems = [SELECT Id, Name, RecordId
                                                             FROM DuplicateRecordItem
                                                             WHERE DuplicateRecordSetId IN :dupeContactRecSets];
            Set<Id> dupeContactIds = new Set<Id>();
            for (DuplicateRecordItem dri : dupeContactRecItems) {
                dupeContactIds.add(dri.RecordId);
            }
            List<Contact> dupeContacts = [SELECT Id, Name
                                          FROM Contact
                                          WHERE Id IN :dupeContactIds];
            List<Contact> contactsToUpdate = new List<Contact>();
            for (Contact c : dupeContacts) {
                c.Review_Before_Emailing__c = true;
                contactsToUpdate.add(c);
            }
            Database.update(contactsToUpdate, false);
        }
    }
    else if (Trigger.isDelete) {
        Set<Id> dupeRecSetIds = new Set<Id>();
        for (DuplicateRecordItem dri : Trigger.Old) {
            dupeRecSetIds.add(dri.DuplicateRecordSetId);
        }
        List<DuplicateRecordSet> dupeRecSets = [SELECT Id, DuplicateRuleId
                                                FROM DuplicateRecordSet
                                                WHERE Id IN :dupeRecSetIds];
        Set<Id> dupeContactRecSetIds = new Set<Id>();
        for (DuplicateRecordSet drs : dupeRecSets) {
            if (duplicateContactRuleMap.containsKey(drs.DuplicateRuleId) || duplicateContactMatchingAddress.containsKey(drs.DuplicateRuleId) || contactMatchNonPreferredEmail.containsKey(drs.DuplicateRuleId)) {
                dupeContactRecSetIds.add(drs.Id);
            }            
        }        
        Set<Id> remainingDRIRecordIds = new Set<Id>();
        for (DuplicateRecordSet drs : [SELECT Id, DuplicateRuleId, (SELECT Id, RecordId FROM DuplicateRecordItems WHERE isDeleted = false) FROM DuplicateRecordSet WHERE Id IN :dupeContactRecSetIds]) {
            System.debug(drs.DuplicateRecordItems.size());
            if (drs.DuplicateRecordItems.size() <= 1) {
                for (DuplicateRecordItem dri : drs.DuplicateRecordItems) {
            		remainingDRIRecordIds.add(dri.RecordId);                    
                }
            }
        }
        
        if (!remainingDRIRecordIds.isEmpty() && Limits.getQueueableJobs()==0) {
            System.enqueueJob(new QueueableUncheckRecordsMarkedForReview(remainingDRIRecordIds));
        }
    }    
}