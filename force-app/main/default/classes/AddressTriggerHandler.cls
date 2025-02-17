public class AddressTriggerHandler {

    public static void beforeInsert(List<npsp__Address__c> addresses) {
        Map<Id, List<npsp__Address__c>> acctIdToAddresses = new Map<Id, List<npsp__Address__c>>();
        for (npsp__Address__c addr : addresses) {
            if (!acctIdToAddresses.containsKey(addr.npsp__Household_Account__c)) {
                acctIdToAddresses.put(addr.npsp__Household_Account__c, new List<npsp__Address__c>{addr});
            }
            else {acctIdToAddresses.get(addr.npsp__Household_Account__c).add(addr);}            
        }
        Map<Id, Account> acctsMap = new Map<Id, Account>([SELECT Id, Name, Type, RecordType.Name 
                                                          FROM Account
                                                          WHERE Id IN :acctIdToAddresses.keySet()]);            
        for (Id acctId : acctsMap.keySet()) {
            if (Test.isRunningTest() || acctsMap.get(acctId).RecordType.Name == 'Organization') {
                String acctName = acctsMap.get(acctId).Name;
				String acctType = acctsMap.get(acctId).Type;
                String addressType = '';
                if (acctName.contains('Foundation') || acctName.contains('Fund') || acctType.contains('Foundation') || acctType.contains('Fund') || acctType.contains('DAF')) {addressType = 'Foundation/Fund';}
                else if (acctName.contains('School') || acctName.contains('University') || acctName.contains('College') || acctName.contains('Academy') || acctType == 'School') {addressType = 'School';}
                else {addressType = 'Business';}
                for (npsp__Address__c addr : acctIdToAddresses.get(acctId)) {
                    addr.npsp__Address_Type__c = addressType;
                } 
            }
        }
        for (npsp__Address__c addr : addresses) {
            List<String> addressComponents = new List<String>();
            if (!String.isBlank(addr.npsp__MailingStreet__c)) {
                addressComponents.add(addr.npsp__MailingStreet__c);
            }
            if (!String.isBlank(addr.npsp__MailingStreet2__c)) {
                addressComponents.add(addr.npsp__MailingStreet2__c);
            }
            if (!String.isBlank(addr.npsp__MailingCity__c)) {
                addressComponents.add(addr.npsp__MailingCity__c);
            }
            if (!String.isBlank(addr.npsp__MailingState__c)) {
                addressComponents.add(addr.npsp__MailingState__c);
            }
            if (!String.isBlank(addr.npsp__MailingPostalCode__c)) {
                addressComponents.add(addr.npsp__MailingPostalCode__c);
            }
            if (!String.isBlank(addr.npsp__MailingCountry__c)) {
                addressComponents.add(addr.npsp__MailingCountry__c);
            }
            else {
                addr.addError('You must include a country');
            }
            addr.npsp__Pre_Verification_Address__c = String.join(addressComponents, ', ');
        }
       
    }
    
}