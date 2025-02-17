@isTest
public class WisepopsWebhookCreateLeadTest {
    
	@isTest
    public static void testHttpPost() {
        String jsonString = 
            '[' +
            '  {' +
            '    \"collected_at\": \"2020-10-10T10:10:58.389Z\",' +
            '    \"wisepop_id\": 12345,' +
            '    \"ip\": \"127.0.0.1\",' +
            '    \"country_code\": \"US\",' +
            '    \"fields\": {' +
            '      \"first_name\": \"Test\",' +
            '      \"last_name\": \"Lead\",' +
            '      \"email\": \"email@test.com\",' +
            '      \"lead_source\": \"Advertising Google\",' +
            '      \"lead_sub_source\": \"Book Club Sign Up Lightbox\",' +
            '      \"book_club_form\": \"Yes\",' +
            '      \"she_creates_change\": \"Yes\"' +            
            '    }' +
            '  }' +
            ']';
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/WisepopsFormProcessing';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonString);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String leadId = WisepopsWebhookCreateLead.createLead();
        Test.stopTest();

		System.assertEquals(true, [SELECT Id, Book_Club__c FROM Lead WHERE Id = :leadId][0].Book_Club__c);        

    }

}