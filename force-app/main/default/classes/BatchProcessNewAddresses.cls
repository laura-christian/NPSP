public class BatchProcessNewAddresses implements Database.Batchable<npsp__Address__c>, Database.Stateful {
    
    public List<npsp__Address__c> addresses = new List<npsp__Address__c>();
    public List<npsp__Address__c> addressesToVerify = new List<npsp__Address__c>();
    
    public BatchProcessNewAddresses(List<npsp__Address__c> addresses) {
        this.addresses = addresses;
    }

	public List<npsp__Address__c> start(Database.BatchableContext bc) {
    	System.debug('>>>> Init batch updates of addresses');
        return addresses;
    }

    public void execute(Database.BatchableContext bc, List<npsp__Address__c> scope) {
        
        npsp__Address__c address = scope[0];
        System.debug('Address in scope: ' + address);
        Id acctId = address.npsp__Household_Account__c;
        
		npsp__Address__c masterAddr = address;
        List<npsp__Address__c> addressesToDelete = new List<npsp__Address__c>(); 
        // If address is missing a street, check to see if a more complete address has ever previously been entered on
        // the account; if one has, and the country is the same as the new, less-complete address, select it as the master
        // address
        if (String.isBlank(address.npsp__MailingStreet__c)) {
            List<npsp__Address__c> previousAddresses = [SELECT Id, npsp__Household_Account__c, npsp__MailingStreet__c, npsp__MailingCity__c, npsp__MailingState__c,
                                                        npsp__MailingPostalCode__c, npsp__MailingCountry__c, npsp__Verified__c, Do_Not_Verify__c, npsp__Pre_Verification_Address__c,
                                                        Original_Address_Scrubbed__c
                                                        FROM npsp__Address__c
                                                        WHERE npsp__Household_Account__c = :acctId
                                                        AND Id != :address.Id
                                                        ORDER BY CreatedDate DESC];
            for (npsp__Address__c addr : previousAddresses) {
                if (!String.isBlank(addr.npsp__MailingStreet__c) && addr.npsp__MailingCountry__c == address.npsp__MailingCountry__c) {
                    masterAddr = addr;
                    masterAddr.npsp__Default_Address__c = true;
                    addressesToDelete.add(address);
                    break;
                }
            }
        }
        else {
            // If address is complete, check to see if address is in a duplicate record set with other addresses on the same account
            Set<Id> dupeRecSetIds = new Set<Id>();
            Set<Id> dupeAddressIds = new Set<Id>();        
            for (DuplicateRecordItem dri : [SELECT Id, DuplicateRecordSetId, RecordId FROM DuplicateRecordItem WHERE RecordId = :address.Id]) {
                dupeRecSetIds.add(dri.DuplicateRecordSetId);
            }
            if (!dupeRecSetIds.isEmpty()) {
                System.debug('Address found in duplicate record set');
                for (DuplicateRecordItem dri : [SELECT RecordId FROM DuplicateRecordItem WHERE DuplicateRecordSetId IN :dupeRecSetIds]) {
                    dupeAddressIds.add(dri.RecordId);
                }
            }
    
            List<npsp__Address__c> dupeAddresses = [SELECT Id, npsp__Household_Account__c, npsp__MailingStreet__c, npsp__MailingCity__c, npsp__MailingState__c,
                                                    npsp__MailingPostalCode__c, npsp__MailingCountry__c, npsp__Verified__c, Do_Not_Verify__c,
                                                    npsp__Pre_Verification_Address__c, Original_Address_Scrubbed__c
                                                    FROM npsp__Address__c
                                                    WHERE Id IN :dupeAddressIds
                                                    ORDER BY CreatedDate];
            for (npsp__Address__c addr : dupeAddresses) {
                if (addr.npsp__Household_Account__c == acctId && addr.npsp__Verified__c == true) {
                    masterAddr = addr;
                    masterAddr.npsp__Default_Address__c = true;
                    break;
                }
            }
            for (npsp__Address__c addr : dupeAddresses) {
                if (addr.Id != masterAddr.Id) {
                    System.debug('This duplicate address can be deleted');
                    addressesToDelete.add(addr);
                }
            }
        }
        if (!masterAddr.npsp__Verified__c && !masterAddr.Do_Not_Verify__c) {addressesToVerify.add(masterAddr);}
        if (!addressesToDelete.isEmpty()) {Database.delete(addressesToDelete, false);}
        if (masterAddr.Id != address.Id) {update masterAddr;}
    }
    
  	public void finish(Database.BatchableContext bc) { 
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job processing new addresses: ' + job.Status);
        if (!Test.isRunningTest() && !addressesToVerify.isEmpty()) {System.debug('Executing asynch job to verify addresses'); Id jobId = Database.executeBatch(new BatchVerifyAddresses(addressesToVerify), 1);}
    }    
    
}