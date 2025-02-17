public class ParseJSONAddressVerificationAPIs {

    public static npsp__Address__c parseSmartyStreetsJSONDomestic(npsp__Address__c addr, String s) {
		addr.npsp__API_Response__c = s;
        Map<String, Object> mappedJSON = (Map<String, Object>)JSON.deserializeUntyped(s);
        if (mappedJSON.containsKey('delivery_line_1')) {
            addr.Address1__c = (String)mappedJSON.get('delivery_line_1');
            addr.npsp__MailingStreet__c = addr.Address1__c;
            addr.npsp__MailingStreet2__c = '';
        }
        if (mappedJSON.containsKey('last_line')) {addr.Address2__c = (String)mappedJSON.get('last_line');}
        if (mappedJSON.containsKey('delivery_point_barcode')) {addr.Delivery_Point_Barcode_Number__c = (String)mappedJSON.get('delivery_point_barcode');}
        if (mappedJSON.containsKey('components')) {
            Map<String, Object> components = (Map<String, Object>)mappedJSON.get('components');
			addr.npsp__MailingCity__c = (String)components.get('city_name');
        	System.debug(addr.npsp__MailingCity__c);
			addr.npsp__MailingState__c = (String)components.get('state_abbreviation');
			System.debug(addr.npsp__MailingState__c);
			addr.ZIP__c = (String)components.get('zipcode');
			addr.ZIP_Plus_4__c = (String)components.get('plus4_code');
            addr.npsp__MailingPostalCode__c = (String)components.get('zipcode') + '-' + (String)components.get('plus4_code');
			System.debug(addr.npsp__MailingPostalCode__c);
            addr.npsp__MailingCountry__c = 'United States';
            if (components.containsKey('primary_number')) {addr.Street_Number__c = (String)components.get('primary_number');}
            if (components.containsKey('street_name')) {addr.Street_Name__c = (String)components.get('street_name');}
            if (components.containsKey('street_suffix')) {addr.Street_Type__c = (String)components.get('street_suffix');}
            if (components.containsKey('secondary_number')) {addr.Building_Unit_Number__c = (String)components.get('secondary_number');}
            if (components.containsKey('secondary_designator')) {addr.Building_Unit_Type__c = (String)components.get('secondary_designator');}
            if (components.containsKey('street_predirection')) {addr.Pre_Direction__c = (String)components.get('street_predirection');}
            if (components.containsKey('street_postdirection')) {addr.Post_Direction__c = (String)components.get('street_postdirection');}
            if (components.containsKey('pmb_number')) {addr.PMB__c = (String)components.get('pmb_number');}
            if (components.containsKey('pmb_designator')) {addr.PMB_Designator__c = (String)components.get('pmb_designator');}
        }
        if (mappedJSON.containsKey('metadata')) {
			Map<String, Object> metadata = (Map<String, Object>)mappedJSON.get('metadata');
            if (metadata.containsKey('county_name')) {addr.npsp__County_Name__c = (String)metadata.get('county_name');}
            if (metadata.containsKey('carrier_route')) {addr.Carrier_Route__c = (String)metadata.get('carrier_route');}
            if (metadata.containsKey('congressional_district')) {addr.npsp__Congressional_District__c  = (String)metadata.get('congressional_district');}
            if (metadata.containsKey('latitude')) {addr.npsp__Geolocation__Latitude__s = (Decimal)metadata.get('latitude');}
            if (metadata.containsKey('longitude')) {addr.npsp__Geolocation__Longitude__s = (Decimal)metadata.get('longitude');}
            if (metadata.containsKey('precision')) {addr.Address_Precision__c = (String)metadata.get('precision');}
            if (metadata.containsKey('rdi')) {addr.RDI__c = (String)metadata.get('rdi');}            
        }
        if (mappedJSON.containsKey('analysis')) {
			Map<String, Object> analysis = (Map<String, Object>)mappedJSON.get('analysis');
            if (analysis.containsKey('dpv_match_code')) {
                if ((String)analysis.get('dpv_match_code') == '') {addr.DPV__c = 'E';}
                else {addr.DPV__c = (String)analysis.get('dpv_match_code');} 
        	}
            if (analysis.containsKey('dpv_vacant') && (String)analysis.get('dpv_vacant') == 'Y') {addr.Vacant__c = true;}
            if (analysis.containsKey('dpv_footnotes')) {addr.DPV_Footnote__c = (String)analysis.get('dpv_footnotes');}
        }
        addr.npsp__Verified__c = true;
        addr.Do_Not_Verify__c = true;
        return addr;
    }
    
    public static npsp__Address__c parsePostGridJSONInternational(npsp__Address__c addr, String s) {
        
		Set<String> countriesWStatesProvinces = new Set<String>{'Canada', 'Brazil', 'Mexico', 'Australia', 'Spain', 'Hong Kong', 'Italy', 'Malaysia', 'Japan'};        
        
        addr.npsp__API_Response__c = s;
		Map<String, Object> mappedJSON = (Map<String, Object>)JSON.deserializeUntyped(s);
        if (mappedJSON.containsKey('data')) {
        	Map<String, Object> data = (Map<String, Object>)mappedJSON.get('data');
            if (data.containsKey('summary')) {
                Map<String, Object> summary = (Map<String, Object>)data.get('summary');
                if (summary.containsKey('verificationStatus')) {
                    String verificationStatus = (String)summary.get('verificationStatus');
                    List<String> statusSplit = verificationStatus.split('_');
                    verificationStatus = String.join(statusSplit, ' ');
                    verificationStatus = DataQualityUtilities.capitalizeFirstLetter(verificationStatus);
                    addr.DPV__c = verificationStatus;
                    Set<String> validVerificationStatuses = new Set<String>{'Verified', 'Partially Verified', 'Ambiguous', 'Conflict'};
                    if (validVerificationStatuses.contains(verificationStatus)) {
                        if (summary.containsKey('postProcessedVerificationMatchLevel')) {
                            String matchLevel = (String)summary.get('postProcessedVerificationMatchLevel');
                            List<String> matchLevelSplit = matchLevel.split('_');
                            matchLevel = String.join(matchLevelSplit, ' ');
                            matchLevel = DataQualityUtilities.capitalizeFirstLetter(matchLevel);
                            addr.Address_Precision__c = matchLevel;
                        }
                        if (data.containsKey('line1')) {addr.Address1__c = (String)data.get('line1');}
                        if (data.containsKey('line2')) {addr.Address2__c = (String)data.get('line2');}
                        if (data.containsKey('line3')) {addr.Address3__c = (String)data.get('line3');}
                        else {addr.Address3__c = null;}
                        if (data.containsKey('line4')) {addr.Address4__c = (String)data.get('line4');}
                        else {addr.Address4__c = null;}
                        if (data.containsKey('country')) {addr.npsp__MailingCountry__c = AddressStandardization.ISOCodeToCountryName.get((String)data.get('country'));}
                        if (data.containsKey('city')) {
                            addr.npsp__MailingCity__c = (String)data.get('city');
                            addr.Locality__c = (String)data.get('city');
                            if ((String)data.get('country')=='HK' && addr.npsp__MailingCity__c.contains('District')) {addr.npsp__MailingCity__c = addr.npsp__MailingCity__c.replaceAll(' District', '');}                            
                        }
                        if (data.containsKey('provinceOrState')) {
                            if (countriesWStatesProvinces.contains(addr.npsp__MailingCountry__c)) {
                                addr.npsp__MailingState__c = (String)data.get('provinceOrState');
                            }
                            else {addr.npsp__MailingState__c = null;}
                            addr.npsp__Administrative_Area__c = (String)data.get('provinceOrState');
                        }
                        else {addr.npsp__MailingState__c = null;}
                        if (data.containsKey('postalOrZip')) {addr.npsp__MailingPostalCode__c = (String)data.get('postalOrZip');}
                        else {addr.npsp__MailingPostalCode__c = null;}
                        if (data.containsKey('details')) {
                            Map<String, Object> details = (Map<String, Object>)data.get('details');
                            if (details.containsKey('premise')) {addr.Street_Number__c = (String)details.get('premise');}
                            if (details.containsKey('building')) {addr.Building__c = (String)details.get('building');}
                            if (details.containsKey('subBuilding')) {addr.Sub_Building__c = (String)details.get('subBuilding');}
                            if (details.containsKey('organization')) {addr.Organization__c = (String)details.get('organization');}
                            if (details.containsKey('postBox')) {addr.PMB__c = (String)details.get('postBox');}                            
                        }
                        if (data.containsKey('geoData')) {
                            Map<String, Object> geoData = (Map<String, Object>)data.get('geoData');
                            if (geoData.containsKey('latitude')) {addr.npsp__Geolocation__Latitude__s = Decimal.valueOf((String)geoData.get('latitude'));}
                            if (geoData.containsKey('longitude')) {addr.npsp__Geolocation__Longitude__s = Decimal.valueOf((String)geoData.get('latitude'));}                
                        }
                        if (data.containsKey('formattedAddress')) {
                            String formattedAddress = (String)data.get('formattedAddress');
                            addr.Address_Format__c = formattedAddress;
                            if (data.containsKey('city')) {formattedAddress = formattedAddress.replaceAll((String)data.get('city'), '');}
                            if (data.containsKey('provinceOrState')) {formattedAddress = formattedAddress.replaceAll((String)data.get('provinceOrState'), '');}
                            if (data.containsKey('postalOrZip')) {formattedAddress = formattedAddress.replaceAll((String)data.get('postalOrZip'), '');}
                            List<String> addressLinesSplit = formattedAddress.split(',');
                            List<String> addressLinesRecompiled = new List<String>();
                            for (String addressLine : addressLinesSplit) {
                                String clearedLine = addressLine.replaceAll('(\\s+)|([\\p{P}\\p{S}])', '');
                                if (clearedLine.length() > 0) {
                                    addressLinesRecompiled.add(addressLine);
                                }
                            }
                            if (addressLinesRecompiled.size() == 1) {
                                addr.npsp__MailingStreet__c = addressLinesRecompiled[0];
                                addr.npsp__MailingStreet2__c = null;
                            }
                            else {
                                // The following is meant to account for when the premise number of an address is separated from the
                                // thoroughfare by a comma, and thus ends up being assigned to a different line when the entire address
                                // is split apart. Assuming the premise number comes either before or after the thoroughfare and is less
                                // than or equal to five characters in length, the following keeps the two elements of the address together
                                // on the same line.
                                if (addressLinesRecompiled.size() > 1 && (addressLinesRecompiled[0].length() <= 5 || addressLinesRecompiled[1].length() <= 5)) {
                                    addressLinesRecompiled.set(0, addressLinesRecompiled[0] + ', ' + addressLinesRecompiled[1]);
                                    addressLinesRecompiled.remove(1);
                                }
                                Long numAddressLinesHalved = (addressLinesRecompiled.size()/2.0).round(System.RoundingMode.CEILING);
                                Integer numAddressLinesHalvedInt = Integer.valueOf(numAddressLinesHalved);
                                System.debug(numAddressLinesHalvedInt);
                                List<String> street1 = new List<String>();
                                List<String> street2 = new List<String>();
                                for (Integer i=0; i<numAddressLinesHalvedInt; i++) {
                                    street1.add(addressLinesRecompiled[i]);
                                }
                                for (Integer i=numAddressLinesHalvedInt; i<addressLinesRecompiled.size(); i++) {
                                    street2.add(addressLinesRecompiled[i]);
                                }
                                addr.npsp__MailingStreet__c = String.join(street1, ', ');
                                System.debug(addr.npsp__MailingStreet__c);
                                addr.npsp__MailingStreet2__c = String.join(street2, ', '); 
                                System.debug(addr.npsp__MailingStreet2__c);                                         
                            }
                        }
                    }
                }
            }
        }
        addr.npsp__Verified__c = true;
        addr.Do_Not_Verify__c = true;       
        return addr;
    }    
}