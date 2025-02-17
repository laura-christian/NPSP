@isTest
public class AddressTriggerHandlerTest {
    
    @isTest
    public static void testInsertAddress() {
        
        Account a = new Account(
        Name = 'Hackbright Academy',
        RecordTypeId = '0128b000000XLom',
        Type = 'School');
        insert a;
        
        npsp__Address__c addr = new npsp__Address__c(
        npsp__Household_Account__c = a.Id,
        npsp__MailingStreet__c = '274 14th St',
        npsp__MailingStreet2__c = 'Suite 100',
        npsp__MailingCity__c = 'Oakland',
        npsp__MailingState__c = 'CA',
        npsp__MailingPostalCode__c = '94612');
        
        try {
        	insert addr;
        }
        catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

}