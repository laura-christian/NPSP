public class BatchVerifyAddresses Implements Database.Batchable<npsp__Address__c>, Database.AllowsCallouts {

    public List<npsp__Address__c> addresses = new List<npsp__Address__c>();

    public BatchVerifyAddresses(List<npsp__Address__c> addresses) {
        this.addresses = addresses;
    }
    
	public List<npsp__Address__c> start(Database.BatchableContext bc) {
    	System.debug('>>>> Init batch verification of addresses');
        return addresses;
    }

    public void execute(Database.BatchableContext bc, List<npsp__Address__c> scope) {
	
        npsp__Address__c addr = scope[0];
        System.debug('Address in scope: ' + addr);

        List<npsp__Address__c> matchedAddresses = [SELECT Id, npsp__Verified__c 
                                                   FROM npsp__Address__c
                                                   WHERE ((npsp__Pre_Verification_Address__c != null AND npsp__Pre_Verification_Address__c = :addr.npsp__Pre_Verification_Address__c)
                                                   OR (Original_Address_Scrubbed__c!= null AND Original_Address_Scrubbed__c = :addr.Original_Address_Scrubbed__c))
                                                   AND Id != :addr.Id AND Do_Not_Verify__c = false AND npsp__Verified__c = false];
        if (!matchedAddresses.isEmpty()) {
            System.debug('Found matching address(es)');
        }
        List<npsp__Address__c> addressesToUpdate = new List<npsp__Address__c>();
        
		String smartyAPIKey = '9340b463-fc5c-99ae-6d3d-c6609c24b85c';
        String authToken = 'Ev6X60UTDD4lEB1BRgAe';        

        if (addr.npsp__MailingCountry__c == 'US' || addr.npsp__MailingCountry__c == 'United States' || addr.npsp__MailingCountry__c == 'USA' || addr.npsp__MailingCountry__c == 'U.S.A.' || addr.npsp__MailingCountry__c == 'U.S.') {
            if (!String.isBlank(addr.npsp__MailingStreet__c)) {
            	String street;
                if (!String.isBlank(addr.npsp__MailingStreet2__c)) {street = addr.npsp__MailingStreet__c + ' ' + addr.npsp__MailingStreet2__c;}
                else {street = addr.npsp__MailingStreet__c;}
                street = street.trim();
                street = EncodingUtil.urlEncode(street, 'UTF-8');
                String city='';
                if (!String.isBlank(addr.npsp__MailingCity__c)) {city = EncodingUtil.urlEncode(addr.npsp__MailingCity__c, 'UTF-8');}
                String state='';
                if (!String.isBlank(addr.npsp__MailingState__c)) {state = EncodingUtil.urlEncode(addr.npsp__MailingState__c, 'UTF-8');}
                String zip='';
                if (!String.isBlank(addr.npsp__MailingPostalCode__c)) {zip = EncodingUtil.urlEncode(addr.npsp__MailingPostalCode__c, 'UTF-8');}
                
                String USEndpoint = 'https://us-street.api.smartystreets.com/street-address';
                USEndpoint += '?auth-id=' + smartyAPIKey;
                USEndpoint += '&auth-token=' + authToken;
                USEndpoint += '&candidates=10';
                USEndpoint += '&street=' + street;
                USEndpoint += '&city=' + city;
                USEndpoint += '&state=' + state;
                USEndpoint += '&zipcode=' + zip;                
                
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(USEndpoint);
                request.setHeader('content-type', 'application/json; charset=utf-8');                
                request.setMethod('GET');
                HttpResponse response = http.send(request);
                System.debug(response.getStatusCode());
                // If the request is successful, parse the JSON response.
                if (response.getStatusCode() == 200) {
                    String jsonObj = response.getBody();
                    System.debug(jsonObj);
                    addr.npsp__API_Response__c = jsonObj;
                    Datetime now = System.now();
                    Datetime localNow = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
                    addr.npsp__Verified_Date__c = localNow;
                    if (jsonObj == '[]') {
                        addr.npsp__Verified__c = true;
                        addr.Do_Not_Verify__c = true;
                        addr.DPV__c = 'N';
                    }
                    else {
                        // API returns a JSON list instead of an object; remove brackets in order to parse as regular JSON object
                        jsonObj = jsonObj.removeStart('[');
                        jsonObj = jsonObj.removeEnd(']');
                        System.debug(jsonObj);
						addr = ParseJSONAddressVerificationAPIs.parseSmartyStreetsJSONDomestic(addr, jsonObj);
                        addressesToUpdate.add(addr);
                        for (npsp__Address__c matchedAddr : matchedAddresses) {
                            matchedAddr = ParseJSONAddressVerificationAPIs.parseSmartyStreetsJSONDomestic(matchedAddr, jsonObj);
                        	matchedAddr.npsp__API_Response__c = jsonObj;                           
                            matchedAddr.npsp__Verified_Date__c = localNow;
                            addressesToUpdate.add(matchedAddr);
                        }
                    }
                }                        
            }
            else {
                addr.npsp__Verified__c = true;
                Datetime now = System.now();
                Datetime localNow = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
                addr.npsp__Verified_Date__c = localNow;
                addr.Do_Not_Verify__c = true;
                addr.DPV__c = 'E';
                addressesToUpdate.add(addr);
                for (npsp__Address__c matchedAddr : matchedAddresses) {
                    matchedAddr.npsp__Verified__c = true;
                    matchedAddr.npsp__Verified_Date__c = localNow;
                    matchedAddr.Do_Not_Verify__c = true;
                    matchedAddr.DPV__c = 'E';
                    addressesToUpdate.add(matchedAddr);
                }
            }
        }
        else {
            if (!String.isBlank(addr.npsp__MailingCountry__c) && !String.isBlank(addr.npsp__MailingStreet__c)) {
				
                String freeformAddress = '{"address" : "' + addr.Original_Address_Scrubbed__c + '"}';
                
                Http http = new Http();
                HttpRequest request = new HttpRequest();
				request.setHeader('content-type', 'application/json; charset=utf-8');              
                request.setEndpoint('callout:PostGridAPI');
                request.setMethod('POST');
                request.setBody(freeformAddress);
                HttpResponse response = http.send(request);
                System.debug(response.getStatusCode());
                // If the request is successful, parse the JSON response.
                if (response.getStatusCode() == 200) {
                    String jsonObj = response.getBody();
                    System.debug(jsonObj);
                    addr.npsp__API_Response__c = jsonObj;
                    Datetime now = System.now();
                    Datetime localNow = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
                    addr.npsp__Verified_Date__c = localNow;
                    System.debug(jsonObj);
                    addr = ParseJSONAddressVerificationAPIs.parsePostGridJSONInternational(addr, jsonObj);
                    addressesToUpdate.add(addr);
                    for (npsp__Address__c matchedAddr : matchedAddresses) {
                        matchedAddr = ParseJSONAddressVerificationAPIs.parsePostGridJSONInternational(matchedAddr, jsonObj);
                        matchedAddr.npsp__API_Response__c = jsonObj;
                        matchedAddr.npsp__Verified_Date__c = localNow;
                        addressesToUpdate.add(matchedAddr);
                    }
                }
            }
            else {
                addr.npsp__Verified__c = true;
                Datetime now = System.now();
                Datetime localNow = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
                addr.npsp__Verified_Date__c = localNow;
                addr.Do_Not_Verify__c = true;
                addr.DPV__c = 'E';
                addressesToUpdate.add(addr);
                for (npsp__Address__c matchedAddr : matchedAddresses) {
                    matchedAddr.npsp__Verified__c = true;
                    matchedAddr.npsp__Verified_Date__c = localNow;
                    matchedAddr.Do_Not_Verify__c = true;
                    matchedAddr.DPV__c = 'E';
                    addressesToUpdate.add(matchedAddr);
                }                
            }            
        }
        Database.update(addressesToUpdate, false);
    }

	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job verifying addresses: ' + job.Status);
    }
    
}