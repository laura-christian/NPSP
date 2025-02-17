@isTest
public class AddressStandardizationTest {    
    
    @isTest
    public static void testAddressNormalization() {
        
        Account a = new Account(
        Name = 'Household',
        RecordTypeId = '0128b000000XLom');
        insert a;
        
        npsp__Address__c addr = new npsp__Address__c(
		npsp__Household_Account__c = a.Id,
		npsp__MailingStreet__c = '123 MAIN AVENUE STREET BOULEVARD ROAD LANE DRIVE SUITE PLACE FLOOR ROOM BUILDING BLOCK 123',
		npsp__MailingStreet2__c = '123 center parkway expressway highway court route plaza junction circle. n/a',
		npsp__MailingCity__c = 'MOUNT SAINT ANYWHERE',
		npsp__MailingState__c = 'california',
		npsp__MailingPostalCode__c = 'zzz xxx 00000',
		npsp__MailingCountry__c = 'USA',
		npsp__Verified__c = false,
		Do_Not_Verify__c = false);
		insert addr;
        
        List<npsp__Address__c> addresses = new List<npsp__Address__c>{addr};
        
        AddressStandardization.normalizeAddress(addresses);
        
		addr.npsp__MailingState__c = 'ca';
        update addr;
        
        addresses = new List<npsp__Address__c>{addr};
        
        AddressStandardization.normalizeAddress(addresses);
        
		System.assertEquals('123 Main Ave St Blvd Rd Ln Dr Ste Pl Fl Rm Bldg Blk 123', [SELECT Id, npsp__MailingStreet__c FROM npsp__Address__c WHERE Id=:addr.Id][0].npsp__MailingStreet__c);
    }
    
}