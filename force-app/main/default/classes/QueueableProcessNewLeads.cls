public class QueueableProcessNewLeads implements Queueable {

    List<Lead> leads;
    
    public QueueableProcessNewLeads(List<Lead> leads) {
        this.leads = leads;
    }
    
    public void execute(QueueableContext context) {
        
        // Create map of key-value pairs with Email as key and lead record as value
        Map<String, Lead> emailToLeadMap = new Map<String, Lead>();
        for (Lead l : leads) {
            if (!String.isBlank(l.Email)) {
                emailToLeadMap.put(l.Email, l);
            }
        }
        if (!emailToLeadMap.keySet().isEmpty()) {
			List<Contact> testContacts = new List<Contact>();
			Set<Id> dupeContactIds = new Set<Id>();
			// Loop over key set in map; for each email in key set, create a test contact
			// record to run through duplicate rules. No test contacts will be inserted, they
			// are simply being used to check for fuzzy matches on first and last names of 
			// contacts and their non-preferred email addresses            
            for (String email : emailToLeadMap.keySet()) {
                Contact c = new Contact(
                FirstName = emailToLeadMap.get(email).FirstName,
                LastName = emailToLeadMap.get(email).LastName,
                npe01__HomeEmail__c = email,
                npe01__WorkEmail__c = email,
                npe01__AlternateEmail__c = email,
                Email = email);
                testContacts.add(c);
            }
            // Run all test contacts through duplicate rules
            DataCloud.FindDuplicatesResult[] results = DataCloud.FindDuplicates.findDuplicates(testContacts);
            for (Integer i=0; i < testContacts.size(); i++) {
                for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {                   
                    if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
                        if (dr.getMatchResults()[0].getMatchRecords()[0].getRecord().Id.getSObjectType().getDescribe().getName() == 'Contact') {
                            dupeContactIds.add(dr.getMatchResults()[0].getMatchRecords()[0].getRecord().Id);
                            break;
                        }
                    }
                }
            }
            // If any duplicate contacts found, query for all email addresses associated with them
            List<Contact> allDupeContactEmailValues = [SELECT Id, FirstName, LastName, Email,
                                                	   npe01__HomeEmail__c, npe01__WorkEmail__c, npe01__AlternateEmail__c
                                                       FROM Contact 
                                                       WHERE Id IN :dupeContactIds];
            List<Contact> contactsToUpdate = new List<Contact>();
            for (Contact c : allDupeContactEmailValues) {
                // If a match has been found on a contact that already has the email
                // address shared with the lead marked as preferred (and thus has the same 
                // email in the standard Email field), don't do anything; the lead
                // will automatically be merged with the duplicate contact
                if (emailToLeadMap.containsKey(c.Email)) {continue;}
                else if (!String.isBlank(c.npe01__HomeEmail__c) && emailToLeadMap.containsKey(c.npe01__HomeEmail__c)) {
                    c.npe01__Preferred_Email__c = 'Personal';
                    c.Email = c.npe01__HomeEmail__c;
                }
                else if (!String.isBlank(c.npe01__WorkEmail__c) && emailToLeadMap.containsKey(c.npe01__WorkEmail__c)) {
                    c.npe01__Preferred_Email__c = 'Work';
                    c.Email = c.npe01__WorkEmail__c;
                }
                else if (!String.isBlank(c.npe01__AlternateEmail__c) && emailToLeadMap.containsKey(c.npe01__AlternateEmail__c)) {
                    c.npe01__Preferred_Email__c = 'Alternate';
                    c.Email = c.npe01__AlternateEmail__c;
                }
                contactsToUpdate.add(c);
            }
            if (!contactsToUpdate.isEmpty()) {Database.update(contactsToUpdate, false);}
        }
    }
    
}