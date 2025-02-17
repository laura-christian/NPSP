@isTest
public class BatchProcessVerifyAddressesTest {
    
    @testSetup
    public static void testSetup() {
        
        Account a1 = new Account(
        Name = 'Household',
        RecordTypeId = '0128b000000XLom');
        insert a1;

        npsp__Address__c usAddr1 = new npsp__Address__c(
        npsp__Household_Account__c = a1.Id,
        npsp__Default_Address__c = true,
        npsp__Address_Type__c = 'Work',
        npsp__MailingStreet__c = '465 California Street',
        npsp__MailingStreet2__c = 'Suite 1000',
        npsp__MailingCity__c = 'San Francisco',
        npsp__MailingState__c = 'California',
        npsp__MailingPostalCode__c = '94104',
        npsp__MailingCountry__c = 'United States',
        npsp__Verified__c = true,
        Do_Not_Verify__c = true);
        insert usAddr1; 
        
        npsp__Address__c usAddr2 = new npsp__Address__c(
        npsp__Household_Account__c = a1.Id,
        npsp__Default_Address__c = true,
        npsp__Address_Type__c = 'Work',            
        npsp__MailingStreet__c = '465 California St # 1000',
        npsp__MailingCity__c = 'San Francisco',
        npsp__MailingState__c = 'California',
        npsp__MailingPostalCode__c = '94104',
        npsp__MailingCountry__c = 'US',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert usAddr2;        
        
        Account a2 = new Account(
        Name = 'Household',
        RecordTypeId = '0128b000000XLom');
        insert a2;

        npsp__Address__c usAddr3 = new npsp__Address__c(
        npsp__Household_Account__c = a2.Id,
        npsp__Default_Address__c = true,
        npsp__Address_Type__c = 'Work',            
        npsp__MailingStreet__c = '465 California Street',
        npsp__MailingStreet2__c = 'Suite 1000',
        npsp__MailingCity__c = 'San Francisco',
        npsp__MailingState__c = 'California',
        npsp__MailingPostalCode__c = '94104',
        npsp__MailingCountry__c = 'United States',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert usAddr3;          
        
        Account a3 = new Account(
        Name = 'Household',
        RecordTypeId = '0128b000000XLom');
        insert a3;        

        npsp__Address__c australiaAddr = new npsp__Address__c(
        npsp__Household_Account__c = a3.Id,
        npsp__Address_Type__c = 'Work',
        npsp__MailingStreet__c = '166 Glebe Street',
        npsp__MailingStreet2__c = 'Suite 201',
        npsp__MailingCity__c = 'Glebe',
        npsp__MailingState__c = 'NSW',
        npsp__MailingPostalCode__c = '2037',
        npsp__MailingCountry__c = 'AU',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert australiaAddr;
        
        npsp__Address__c hongKongAddr = new npsp__Address__c(
        npsp__Household_Account__c = a3.Id,
        npsp__Address_Type__c = 'Home',
        npsp__MailingStreet__c = 'Rm 7, 17/F, Blk A, Po Sing Centre',
        npsp__MailingStreet2__c = '1-25 Ta Chuen Ping Street',
        npsp__MailingCity__c = 'Kwai Chung',
        npsp__MailingState__c = 'NT',
        npsp__MailingPostalCode__c = '852',
        npsp__MailingCountry__c = 'HK',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert hongKongAddr;        

        Account a4 = new Account(
        Name = 'Household',
        RecordTypeId = '0128b000000XLom');
        insert a4;
        
        npsp__Address__c addrNoStreetLine = new npsp__Address__c(
        npsp__Household_Account__c = a4.Id,            
        npsp__Default_Address__c = true,
        npsp__Address_Type__c = 'Work',            
        npsp__MailingStreet__c = '',
        npsp__MailingCity__c = 'San Francisco',
        npsp__MailingState__c = 'CA',
        npsp__MailingPostalCode__c = '94104',
        npsp__MailingCountry__c = 'United States',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert addrNoStreetLine;        
        
        npsp__Address__c australiaAddr2 = new npsp__Address__c(
        npsp__Household_Account__c = a4.Id,
        npsp__Address_Type__c = 'Work',
        npsp__MailingStreet__c = '166 Glebe Street',
        npsp__MailingStreet2__c = 'Suite 201',
        npsp__MailingCity__c = 'Glebe',
        npsp__MailingState__c = 'NSW',
        npsp__MailingPostalCode__c = '2037',
        npsp__MailingCountry__c = 'AU',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert australiaAddr2;        
        
    }

    @isTest
    public static void testScheduleAddressDedupingVerification() {
		String jobId = System.schedule('Scheduled Job 4', '0 45 * * * ?', new ScheduleAddressDedupingVerification());
    }

    @isTest
    public static void testVerifyAddressControllerExtension() {
        
		npsp__Address__c addr = [SELECT Id, npsp__Household_Account__c,
                                 npsp__Pre_Verification_Address__c, Original_Address_Scrubbed__c,
                                 npsp__MailingStreet__c, npsp__MailingStreet2__c,
                                 npsp__MailingCity__c, npsp__MailingState__c,
                                 npsp__MailingPostalCode__c, npsp__MailingCountry__c,
                                 npsp__Verified__c, Do_Not_Verify__c
                                 FROM npsp__Address__c
                                 WHERE npsp__MailingPostalCode__c = '94104' AND
                                 npsp__MailingStreet__c != null LIMIT 1];
            
		SingleRequestMock jsonResponseUSAddress = new SingleRequestMock(200,
			'OK',
            '[' +
            '    {' +
            '        "input_index": 0,' +
            '        "candidate_index": 0,' +
            '        "delivery_line_1": "465 California St Ste 1000",' +
            '        "last_line": "San Francisco CA 94104-1824",' +
            '        "delivery_point_barcode": "941041824502",' +
            '        "components": {' +
            '            "primary_number": "465",' +
            '            "street_name": "California",' +
            '            "street_suffix": "St",' +
            '            "secondary_number": "1000",' +
            '            "secondary_designator": "Ste",' +
            '            "city_name": "San Francisco",' +
            '            "default_city_name": "San Francisco",' +
            '            "state_abbreviation": "CA",' +
            '            "zipcode": "94104",' +
            '            "plus4_code": "1824",' +
            '            "delivery_point": "50",' +
            '            "delivery_point_check_digit": "2"' +
            '        },' +
            '        "metadata": {' +
            '            "record_type": "H",' +
            '            "zip_type": "Standard",' +
            '            "county_fips": "06075",' +
            '            "county_name": "San Francisco",' +
            '            "carrier_route": "C020",' +
            '            "congressional_district": "12",' +
            '            "rdi": "Commercial",' +
            '            "elot_sequence": "0080",' +
            '            "elot_sort": "A",' +
            '            "latitude": 37.79283,' +
            '            "longitude": -122.4022,' +
            '            "precision": "Zip9",' +
            '            "time_zone": "Pacific",' +
            '            "utc_offset": -8,' +
            '            "dst": true' +
            '        },' +
            '        "analysis": {' +
            '            "dpv_match_code": "Y",' +
            '            "dpv_footnotes": "AABB",' +
            '            "dpv_cmra": "N",' +
            '            "dpv_vacant": "N",' +
            '            "active": "Y",' +
            '            "footnotes": "A#N#"' +
            '        }' +
            '    }' +
			']', null);
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, jsonResponseUSAddress);
		Test.setCurrentPage(Page.VerifyAddressButtonVF);
		ApexPages.StandardController controller = new ApexPages.StandardController(addr);
		VerifyAddressExt extension = new VerifyAddressExt(controller);        
		PageReference pageRef = extension.verifyAddress();
        Test.stopTest();

		System.assertEquals('/' + addr.Id, pageRef.getUrl());
    }

    @isTest
    public static void testIntlAddressVerificationCalloutBatch() {
        
		List<npsp__Address__c> addresses = [SELECT Id, npsp__Household_Account__c,
								 npsp__Pre_Verification_Address__c, Original_Address_Scrubbed__c,                                            
                                 npsp__MailingStreet__c, npsp__MailingStreet2__c,
                                 npsp__MailingCity__c, npsp__MailingState__c,
                                 npsp__MailingPostalCode__c, npsp__MailingCountry__c,
                                 npsp__Verified__c, Do_Not_Verify__c
                                 FROM npsp__Address__c
                                 WHERE npsp__MailingPostalCode__c = '2037' LIMIT 1];        
        
		SingleRequestMock jsonResponseIntlAddress = new SingleRequestMock(200, 'OK',
            '{' +
            '    "status": "success",' +
            '    "message": "International address verified successfully.",' +
            '    "data": {' +
            '        "city": "GLEBE",' +
            '        "country": "AU",' +
            '        "countryName": "Australia",' +
            '        "details": {' +
            '            "subBuilding": "Se 201",' +
            '            "premise": "166"' +
            '        },' +
            '        "formattedAddress": "Se 201 166 Glebe St,GLEBE NSW 2037",' +
            '        "geoData": {' +
            '            "latitude": "-33.881170",' +
            '            "longitude": "151.191217",' +
            '            "geoAccuracy": "A3"' +
            '        },' +
            '        "line1": "Se 201 166 Glebe St",' +
            '        "line2": "GLEBE NSW 2037",' +
            '        "postalOrZip": "2037",' +
            '        "provinceOrState": "NSW",' +
            '        "summary": {' +
            '            "verificationStatus": "verified",' +
            '            "postProcessedVerificationMatchLevel": "street_or_road",' +
            '            "preProcessedVerificationMatchLevel": "street_or_road",' +
            '            "parsingStatus": "identified_and_parsed",' +
            '            "lexiconIdentificationMatchLevel": "postbox_or_subbuilding",' +
            '            "contextIdentificationMatchLevel": "postbox_or_subbuilding",' +
            '            "postCodeStatus": "postal_code_primary_verified",' +
            '            "matchScore": 100' +
            '        }' +
            '    }' +
            '}', null);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, jsonResponseIntlAddress);
        Database.executeBatch(new BatchVerifyAddresses(addresses), 1);
        Test.stopTest();
    }
    
    @isTest
    public static void testMultiLineIntlAddressVerificationCalloutBatch() {
        
		List<npsp__Address__c> addresses = [SELECT Id, npsp__Household_Account__c,
								 npsp__Pre_Verification_Address__c, Original_Address_Scrubbed__c,                                            
                                 npsp__MailingStreet__c, npsp__MailingStreet2__c,
                                 npsp__MailingCity__c, npsp__MailingState__c,
                                 npsp__MailingPostalCode__c, npsp__MailingCountry__c,
                                 npsp__Verified__c, Do_Not_Verify__c
                                 FROM npsp__Address__c
                                 WHERE npsp__MailingCountry__c = 'Hong Kong' LIMIT 1];        
        
		SingleRequestMock jsonResponseIntlAddress = new SingleRequestMock(200, 'OK',
            '{' +
            '    "status": "success",' +
            '    "message": "International address verified successfully.",' +
            '    "data": {' +
            '        "city": "Kwai Tsing District",' +
            '        "country": "HK",' +
            '        "countryName": "Hong Kong",' +
            '        "details": {' +
            '            "building": "Po Sing Centre",' +
            '            "subBuilding": "Rm 7 17/F",' +
            '            "premise": "1-25"' +
            '        },' +
            '        "formattedAddress": "Rm 7 17/F Block A,Po Sing Centre,1-25 Ta Chuen Ping Street,Kwai Chung,Kwai Tsing District,New Territories",' +
            '        "geoData": {' +
            '            "latitude": "22.363380",' +
            '            "longitude": "114.141380",' +
            '            "geoAccuracy": "P4"' +
            '        },' +
            '        "line1": "Rm 7 17/F Block A",' +
            '        "line2": "Po Sing Centre",' +
            '        "line3": "1-25 Ta Chuen Ping Street",' +
            '        "line4": "Kwai Chung",' +
            '        "provinceOrState": "New Territories",' +
            '        "summary": {' +
            '            "verificationStatus": "ambiguous",' +
            '            "postProcessedVerificationMatchLevel": "premise_or_building",' +
            '            "preProcessedVerificationMatchLevel": "premise_or_building",' +
            '            "parsingStatus": "identified_and_parsed",' +
            '            "lexiconIdentificationMatchLevel": "postbox_or_subbuilding",' +
            '            "contextIdentificationMatchLevel": "postbox_or_subbuilding",' +
            '            "postCodeStatus": "postal_code_primary_empty",' +
            '            "matchScore": 100' +
            '        }' +
            '    }' +
            '}', null);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, jsonResponseIntlAddress);
        Database.executeBatch(new BatchVerifyAddresses(addresses), 1);
        Test.stopTest();
    }    
    
    @isTest
    public static void testNoStreetLine1Batch() {
        
        Account a = new Account(
        Name = 'Household',
        RecordTypeId = '0128b000000XLom');
        insert a; 
        
        npsp__Address__c addr1 = new npsp__Address__c(
        npsp__Household_Account__c = a.Id,
        npsp__Default_Address__c = true,
        npsp__MailingStreet__c = '',
        npsp__MailingCity__c = 'San Francisco',
        npsp__MailingState__c = 'CA',
        npsp__MailingPostalCode__c = '94104',
        npsp__MailingCountry__c = 'United States',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert addr1;       

        npsp__Address__c addr2 = new npsp__Address__c(
        npsp__Household_Account__c = a.Id,
        npsp__Address_Type__c = 'Work',
        npsp__MailingStreet__c = '',
        npsp__MailingCity__c = 'Glebe',
        npsp__MailingState__c = 'NSW',
        npsp__MailingPostalCode__c = '2037',
        npsp__MailingCountry__c = 'AU',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert addr2;   
        
        List<npsp__Address__c> addresses1 = new List<npsp__Address__c>{addr1};
        List<npsp__Address__c> addresses2 = new List<npsp__Address__c>{addr2};            

        Test.startTest();
        Database.executeBatch(new BatchVerifyAddresses(addresses1), 1);
        Database.executeBatch(new BatchVerifyAddresses(addresses2), 1);
        Test.stopTest();
        
    }    

    @isTest
    public static void testInvalidAddressBatch() {
        
        Account a = new Account(
        Name = 'Household',
        RecordTypeId = '0128b000000XLom');
        insert a;        
        
        npsp__Address__c fakeAddress = new npsp__Address__c(
		npsp__Household_Account__c = a.Id,
        npsp__MailingStreet__c = '123 Main Street',
        npsp__MailingCity__c = 'Anytown',
        npsp__MailingState__c = 'CA',
        npsp__MailingPostalCode__c = '99999',
        npsp__MailingCountry__c = 'United States');
        insert fakeAddress;
        
        List<npsp__Address__c> addresses = new List<npsp__Address__c>{fakeAddress};
        
        SingleRequestMock emptyJSONResponse = new SingleRequestMock(200, 'OK', '[]', null);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, emptyJSONResponse);
        Database.executeBatch(new BatchVerifyAddresses(addresses), 1);
        Test.stopTest();        
    }

	@isTest
    public static void testBatchProcessNewAddresses() {

		List<npsp__Address__c> addresses = [SELECT Id, npsp__Household_Account__c,
                                 npsp__Pre_Verification_Address__c, Original_Address_Scrubbed__c,
                                 npsp__MailingStreet__c, npsp__MailingStreet2__c,
                                 npsp__MailingCity__c, npsp__MailingState__c,
                                 npsp__MailingPostalCode__c, npsp__MailingCountry__c,
                                 npsp__Verified__c, Do_Not_Verify__c
                                 FROM npsp__Address__c
                                 WHERE npsp__MailingStreet__c LIKE '%California%'
                                 ORDER BY CreatedDate DESC];
        
        DuplicateRule dupeAddrRule = [SELECT Id FROM DuplicateRule WHERE MasterLabel = 'Rule for Duplicate Addresses' LIMIT 1];

        DuplicateRecordSet drs = new DuplicateRecordSet(
        DuplicateRuleId = dupeAddrRule.Id);
        insert drs;
        
        DuplicateRecordItem dri1 = new DuplicateRecordItem(
        RecordId = addresses[0].Id,
        DuplicateRecordSetId = drs.Id);
        insert dri1;
        
        DuplicateRecordItem dri2 = new DuplicateRecordItem(
        RecordId = addresses[1].Id,
        DuplicateRecordSetId = drs.Id);
        insert dri2;
        
        Test.startTest();
        Database.executeBatch(new BatchProcessNewAddresses(addresses));
        Test.stopTest();
    }

	@isTest
    public static void testBatchProcessNewAddressLessComplete() {

		npsp__Address__c addr = [SELECT Id, npsp__Household_Account__c,
                                 npsp__Pre_Verification_Address__c, Original_Address_Scrubbed__c,
                                 npsp__MailingStreet__c, npsp__MailingStreet2__c,
                                 npsp__MailingCity__c, npsp__MailingState__c,
                                 npsp__MailingPostalCode__c, npsp__MailingCountry__c,
                                 npsp__Verified__c, Do_Not_Verify__c
                                 FROM npsp__Address__c
                                 WHERE npsp__MailingPostalCode__c = '94104' AND
                                 npsp__MailingStreet__c != null LIMIT 1];
		Account a = [SELECT Id FROM Account WHERE Id = :addr.npsp__Household_Account__c LIMIT 1];

        npsp__Address__c partialAddress = new npsp__Address__c(
        npsp__Household_Account__c = a.Id,
        npsp__Default_Address__c = true,
		npsp__Address_Type__c = 'Work',            
        npsp__MailingStreet__c = '',
        npsp__MailingCity__c = 'San Francisco',
        npsp__MailingState__c = 'CA',
        npsp__MailingPostalCode__c = '94104',
        npsp__MailingCountry__c = 'United States',
        npsp__Verified__c = false,
        Do_Not_Verify__c = false);
        insert partialAddress;
        
        List<npsp__Address__c> addresses = new List<npsp__Address__c>{partialAddress};
            
        Test.startTest();
        Database.executeBatch(new BatchProcessNewAddresses(addresses), 1);
        Test.stopTest();

    }    
}