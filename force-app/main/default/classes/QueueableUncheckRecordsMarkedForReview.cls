public class QueueableUncheckRecordsMarkedForReview implements Queueable {
    
    Set<Id> contactIds;
    
    public QueueableUncheckRecordsMarkedForReview(Set<Id> contactIds) {
        this.contactIds = contactIds;
    }
    
    public void execute(QueueableContext context) {
        
		List<Contact> contacts = [SELECT Id FROM Contact WHERE Id IN :contactIds];
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : contacts) {
            c.Review_Before_Emailing__c = false;
            contactsToUpdate.add(c);
        }
        if (!contactsToUpdate.isEmpty()) {Database.update(contactsToUpdate, false);} 
        
    }
}