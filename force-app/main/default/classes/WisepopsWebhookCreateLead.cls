@RestResource(urlMapping='/WisepopsFormProcessing')
global class WisepopsWebhookCreateLead {

    @HttpPost
    global static String createLead() {
        String jsonObj = RestContext.request.requestBody.toString();
        System.debug(jsonObj);
        jsonObj = jsonObj.replace('[', '');
        jsonObj = jsonObj.replace(']', '');
        Map<String, Object> mappedJSON = (Map<String, Object>)JSON.deserializeUntyped(jsonObj);
        Map<String, Object> fields = (Map<String, Object>)mappedJSON.get('fields');
        Boolean bookClub = false;
        Boolean sheCreatesChange = false;
        if (fields.containsKey('book_club_form') && (String)fields.get('book_club_form')=='Yes') {
            System.debug('This is a book club signup form');
            bookClub = true;
        }
        if (fields.containsKey('she_creates_change') && (String)fields.get('she_creates_change')=='Yes') {
            System.debug('This is a She Creates Change signup form');
            sheCreatesChange = true;
        }        
        Lead l = new Lead(
        FirstName = (String)fields.get('first_name'),
        LastName = (String)fields.get('last_name'),
        Email = (String)fields.get('email'),
        Company = 'Household',
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        Book_Club__c = bookClub,
        She_Creates_Change__c = sheCreatesChange,
        Newsletter__c = true,
        LeadSource = (String)fields.get('lead_source'),
        Lead_Sub_Source__c = (String)fields.get('lead_sub_source'),
        Last_Form_Filled_Out__c = (String)fields.get('lead_sub_source'),
        Country = AddressStandardization.ISOCodeToCountryName.get(((String)mappedJSON.get('country_code'))));
        insert l;
        return l.Id;
    }
    
}