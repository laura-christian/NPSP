@isTest
public class BatchValidateEmailsTest {
    

    @isTest
    public static void testSchedulable() {
        
        Lead l = new Lead(
        FirstName = 'Test',
        LastName = 'Lead',
        Company = 'Household',
        Email = 'email@test.com',
        Country = 'United Kingdom',
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        Email_ZeroBounce_Status__c = '');
        insert l;
        
        Contact c = new Contact(
        FirstName = 'Test',
        LastName = 'Contact',
        npe01__AlternateEmail__c = 'my_email@test.co',
        npe01__Preferred_Email__c = 'Alternate',
        MailingCountry = 'United States',
        HasOptedOutOfEmail = false,
        Email_ZeroBounce_Status__c = '');
        insert c;        
        
        Test.startTest();
		String jobId = System.schedule('Scheduled Job', '0 45 * * * ?', new ScheduleEmailAddressValidation());
		Test.stopTest();        
    }
    
    @isTest
    public static void testSecondSchedulable() {
        SingleRequestMock zeroBounceResponse = new SingleRequestMock(200,
		'OK',
        '{' +
        '      "email_batch": [' +
        '          {' +
        '              "address": "typo.guy@gmail.com",' +
        '              "status": "valid",' +
        '              "sub_status": "",' +
        '              "free_email": false,' +
        '              "did_you_mean": null,' +
        '              "account": null,' +
        '              "domain": null,' +
        '              "domain_age_days": "9692",' +
        '              "smtp_provider": "example",' +
        '              "mx_found": "true",' +
        '              "mx_record": "mx.gmail.com",' +
        '              "firstname": "Typo",' +
        '              "lastname": "Guy",' +
        '              "gender": "male",' +
        '              "country": null,' +
        '              "region": null,' +
        '              "city": null,' +
        '              "zipcode": null,' +
        '              "processed_at": "2020-09-17 17:43:11.829"' +
        '          },' +
        '          {' +
        '              "address": "my_email@test.com",' +
        '              "status": "valid",' +
        '              "sub_status": "",' +
        '              "free_email": false,' +
        '              "did_you_mean": "",' +
        '              "account": null,' +
        '              "domain": null,' +
        '              "domain_age_days": "9692",' +
        '              "smtp_provider": "test",' +
        '              "mx_found": "true",' +
        '              "mx_record": "mx.test.com",' +
        '              "firstname": "Sloppy",' +
        '              "lastname": "Typist",' +
        '              "gender": "male",' +
        '              "country": null,' +
        '              "region": null,' +
        '              "city": null,' +
        '              "zipcode": null,' +
        '              "processed_at": "2020-09-17 17:43:11.830"' +
        '          }' +
        '      ],' +
        '      "errors": []' +
		'}',null);        
        
        
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, zeroBounceResponse);        
        String jobId = System.schedule('Scheduled Job', '0 45 * * * ?', new ScheduleSecondEmailAddressValidation(new List<String>{'my_email@test.com', 'typo.guy@gmail.com'}));
        Test.stopTest(); 
    }
    
    @isTest
    public static void testBatchValidation() {
        
        Lead l = new Lead(
        FirstName = 'Test',
        LastName = 'Lead',
        Company = 'Household',
        Email = 'email@test.com',
        Country = 'United Kingdom',
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        Email_ZeroBounce_Status__c = '');
        insert l;
        
        Lead l2 = new Lead(
        FirstName = 'Typo',
        LastName = 'Maker',
        Company = 'Household',
        Email = 'typo.guy@gmial.com',
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        Email_ZeroBounce_Status__c = '');
        insert l2;
        
        Contact c = new Contact(
        FirstName = 'Test',
        LastName = 'Contact',
        npe01__HomeEmail__c = 'valid@example.com',
        npe01__Preferred_Email__c = 'Home',
        MailingCountry = 'United States',
        HasOptedOutOfEmail = false,
        Email_ZeroBounce_Status__c = '');
        insert c;         
        
        Contact c2 = new Contact(
        FirstName = 'Sloppy',
        LastName = 'Typist',
        npe01__AlternateEmail__c = 'my_email@test.co',
        npe01__Preferred_Email__c = 'Other',
        MailingCountry = 'United States',
        HasOptedOutOfEmail = false,
        Email_ZeroBounce_Status__c = '');
        insert c2;        
        
        SingleRequestMock zeroBounceResponse = new SingleRequestMock(200,
		'OK',
        '{' +
        '      "email_batch": [' +
        '          {' +
        '              "address": "email@test.com",' +
        '              "status": "valid",' +
        '              "sub_status": "",' +
        '              "free_email": false,' +
        '              "did_you_mean": null,' +
        '              "account": null,' +
        '              "domain": null,' +
        '              "domain_age_days": "9692",' +
        '              "smtp_provider": "example",' +
        '              "mx_found": "true",' +
        '              "mx_record": "mx.example.com",' +
        '              "firstname": "Test",' +
        '              "lastname": "Lead",' +
        '              "gender": "female",' +
        '              "country": null,' +
        '              "region": null,' +
        '              "city": null,' +
        '              "zipcode": null,' +
        '              "processed_at": "2020-09-17 17:43:11.829"' +
        '          },' +
        '          {' +
        '              "address": "my_email@test.co",' +
        '              "status": "invalid",' +
        '              "sub_status": "possible_typo",' +
        '              "free_email": false,' +
        '              "did_you_mean": "my_email@test.com",' +
        '              "account": null,' +
        '              "domain": null,' +
        '              "domain_age_days": "9692",' +
        '              "smtp_provider": "test",' +
        '              "mx_found": "true",' +
        '              "mx_record": "mx.test.com",' +
        '              "firstname": "Sloppy",' +
        '              "lastname": "Typist",' +
        '              "gender": "male",' +
        '              "country": null,' +
        '              "region": null,' +
        '              "city": null,' +
        '              "zipcode": null,' +
        '              "processed_at": "2020-09-17 17:43:11.830"' +
        '          },' +
        '          {' +
        '              "address": "valid@example.com",' +
        '              "status": "valid",' +
        '              "sub_status": "",' +
        '              "free_email": false,' +
        '              "did_you_mean": null,' +
        '              "account": null,' +
        '              "domain": null,' +
        '              "domain_age_days": "9692",' +
        '              "smtp_provider": "example",' +
        '              "mx_found": "true",' +
        '              "mx_record": "mx.example.com",' +
        '              "firstname": "Test",' +
        '              "lastname": "Contact",' +
        '              "gender": "male",' +
        '              "country": null,' +
        '              "region": null,' +
        '              "city": null,' +
        '              "zipcode": null,' +
        '              "processed_at": "2020-09-17 17:43:11.830"' +
        '          },' +
        '          {' +
        '              "address": "typo.guy@gmial.com",' +
        '              "status": "invalid",' +
        '              "sub_status": "possible_typo",' +
        '              "free_email": false,' +
        '              "did_you_mean": "typo.guy@gmail.com",' +
        '              "account": null,' +
        '              "domain": null,' +
        '              "domain_age_days": "9692",' +
        '              "smtp_provider": "gmail",' +
        '              "mx_found": "true",' +
        '              "mx_record": "mx.gmail.com",' +
        '              "firstname": "Typo",' +
        '              "lastname": "Maker",' +
        '              "gender": "male",' +
        '              "country": null,' +
        '              "region": null,' +
        '              "city": null,' +
        '              "zipcode": null,' +
        '              "processed_at": "2020-09-17 17:43:11.830"' +
        '          }' +
        '      ],' +
        '      "errors": []' +
		'}',null);
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, zeroBounceResponse);
        List<Id> fixedSearchResults = new List<Id>{l.Id, l2.Id, c.Id, c2.Id};
        //Necessary to use below system method "setFixedSearchResults" in order for SOSL query to return any results during execution of unit test
        Test.setFixedSearchResults(fixedSearchResults);
        Database.executeBatch(new BatchValidateEmails(new List<String>{'email@test.com', 'my_email@test.co', 'typo.guy@gmial.com', 'valid@example.com'}));
        Test.stopTest();
    }
    
}