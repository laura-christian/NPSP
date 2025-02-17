@isTest
public class DuplicateRecordSetTriggerTest {
    
   	public static final Id dupeContactRuleId =  
        [SELECT Id
         FROM DuplicateRule
         WHERE MasterLabel = 'Standard Rule for New Contacts with Duplicate Contacts'][0].Id;    
    
    @isTest
    public static void testBeforeDeleteDuplicateContactsRecSet() {
        
        Contact con1 = new Contact(
        FirstName = 'Test',
        LastName = 'Contact',
        npe01__Preferred_Email__c = 'Work',
        npe01__WorkEmail__c = 'test@work.com');
        insert con1;

        Contact con2 = new Contact(
        FirstName = 'Test',
        LastName = 'Contact',
        npe01__Preferred_Email__c = 'Work',
        npe01__WorkEmail__c = 'test@work.com');
        insert con2;
        
        DuplicateRecordSet drs = new DuplicateRecordSet(
        DuplicateRuleId = dupeContactRuleId);
        insert drs;
       
        DuplicateRecordItem origCon = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = con1.Id);
        DuplicateRecordItem dupeCon = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = con2.Id);
        List<DuplicateRecordItem> driList = new List<DuplicateRecordItem>{origCon, dupeCon};
        insert driList;
        
		Test.startTest();
        delete drs;
        Test.stopTest();
        
        System.assertEquals(false, [SELECT Id, Review_Before_Emailing__c FROM Contact WHERE Id = :con1.Id][0].Review_Before_Emailing__c);
    }
}