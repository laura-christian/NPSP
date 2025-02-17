@isTest
public class NewContactExtTest {
    
    @isTest
    public static void testNewContactExt() {
        
        Account org = new Account(
        RecordTypeId = '0128b000000XLonAAG',
        Name = 'Halcyon Communications',
        Type = 'Corporation');
        insert org;
        
        Contact c = new Contact(
        FirstName = 'Mona',
        LastName = 'Ramsey',
        npe01__Preferred_Email__c = 'Work',
        npe01__WorkEmail__c = 'mona.ramsey@halcyoncommunications.com');
        insert c;
        
        List<Contact> contacts = new List<Contact>{c};
        
		ApexPages.StandardSetController controller = new ApexPages.StandardSetController(contacts);
		NewContactExt extension = new NewContactExt(controller);
		extension.con.FirstName = 'Mary Ann';
        extension.con.LastName = 'Singleton';
        extension.con.npe01__Preferred_Email__c = 'Work';
        extension.con.npe01__WorkEmail__c = 'mary.ann.singleton@halcyoncommunications.com';
        extension.affiliation.npe5__Organization__c = org.Id;
        extension.affiliation.Type__c = 'Employee';
		PageReference pageRef = extension.saveContact();        
        
    }
    
    @isTest
    public static void testException() {
        Contact c = new Contact(
        FirstName = 'Mona',
        LastName = 'Ramsey',
        npe01__Preferred_Email__c = 'Work',
        npe01__WorkEmail__c = 'mona.ramsey@halcyoncommunications.com');
        insert c;
        
        List<Contact> contacts = new List<Contact>{c};
        
		ApexPages.StandardSetController controller = new ApexPages.StandardSetController(contacts);
		NewContactExt extension = new NewContactExt(controller);
		extension.con.FirstName = 'Mary Ann';
		extension.saveContact();        
    }
    
    @isTest
    public static void testCancel() {
        Contact c = new Contact(
        FirstName = 'Mona',
        LastName = 'Ramsey',
        npe01__Preferred_Email__c = 'Work',
        npe01__WorkEmail__c = 'mona.ramsey@halcyoncommunications.com');
        insert c;
        
        List<Contact> contacts = new List<Contact>{c};
        
		ApexPages.StandardSetController controller = new ApexPages.StandardSetController(contacts);
		NewContactExt extension = new NewContactExt(controller);
		extension.cancel();        
    }

}