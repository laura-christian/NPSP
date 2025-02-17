public class VerifyAddressExt { 

    public npsp__Address__c addr { get; set; }     
    public Id addressId { get; set; }          
       
    public VerifyAddressExt(ApexPages.StandardController controller) {     
        addr =  (npsp__Address__c)controller.getRecord();     
        addressId = addr.Id;
    }     
    
    //Method that can be called from Visualforce page action attribute (custom button)
    public PageReference verifyAddress() {        
        List<npsp__Address__c> addresses = [SELECT Id, npsp__MailingStreet__c, npsp__MailingStreet2__c,
											npsp__MailingCity__c, npsp__MailingState__c, npsp__MailingPostalCode__c,
                                            npsp__MailingCountry__c, Do_Not_Verify__c, npsp__Verified__c,
                                           	npsp__Pre_Verification_Address__c, Original_Address_Scrubbed__c
                                            FROM npsp__Address__c
                                            WHERE Id = :addressId];
        Database.executeBatch(new BatchVerifyAddresses(addresses), 1);
        PageReference pageRef = new PageReference('/' + addr.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
}