/**
 * See MS_ContactSyncSendLeadsToEN for comments
 *
 * Authored by Jake Martin White
 * jake@mustardseednonprofit.ca
 */
 
@istest
global class MS_ContactSyncSendLeadsToENTest {
 
    global class ENImportServiceMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            System.assertEquals(true, req.getBody().contains('sue@test.com'));
            System.assertEquals(true, req.getBody().contains('bob@test.com'));
            System.assertEquals(false, req.getBody().contains('donotpush@test.com'));

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Your file has been uploaded successfully and scheduled for import');
            return res;
        }
    }

    global class ENImportServiceFailureMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Mismatched headers');
            return res;
        }
    }
    
    static testmethod void testSuccess() {
     
        Lead l1 = new Lead(
            FirstName = 'Susan',
            LastName = 'Test',
            Email = 'sue@test.com',
            Company = 'Household',            
            Email_Opted_In__c = true,
            GDPR_Consent_Date__c = System.today(),
            HasOptedOutOfEmail = false,
            Newsletter__c = true,
            Book_Club__c = false,
            Do_Not_Solicit__c = true,
            SMS_Opt_In__c = true,
            SMS_Consent_Date__c = System.today()-90,
            MobilePhone = '+19999999999',
            EN_Push__c = true
        );
        Lead l2 = new Lead(
            FirstName = 'Bob',
            LastName = 'Test',
            Email = 'bob@test.com',
            Company = 'Household',
            Email_Opted_In__c = false,
            HasOptedOutOfEmail = false,
            Newsletter__c = false,
            Book_Club__c = true,
            Do_Not_Solicit__c = false,
			SMS_Opt_In__c = false,            
            EN_Push__c = true
        );
        Lead l3 = new Lead(
            FirstName = 'Donot',
            LastName = 'Push',
            Email = 'donotpush@test.com',
            Company = 'Household',
            Email_Opted_In__c = false,
            HasOptedOutOfEmail = true,
            Newsletter__c = true,
            Book_Club__c = true,
            Do_Not_Solicit__c = false,
			SMS_Opt_In__c = false,            
            EN_Push__c = false
        );
        insert l1;
        insert l2;
        insert l3;
        
        l3.EN_Push__c = false;
        update l3;
        
        Test.setMock(HttpCalloutMock.class, new ENImportServiceMock());
        
        Test.startTest();
        
        MS_ContactSyncSendLeadsToEN b = new MS_ContactSyncSendLeadsToEN();
        Database.executeBatch(b);

        Test.stopTest();
    }
    
    static testmethod void testFail() {
 
        Lead l1 = new Lead(
            FirstName = 'Susan',
            LastName = 'Test',
            Email = 'sue@test.com',
            Company = 'Household',
            EN_Push__c = true
        );
        insert l1;
        
        Test.setMock(HttpCalloutMock.class, new ENImportServiceFailureMock());
        
        Test.startTest();
        
        MS_ContactSyncSendLeadsToEN b = new MS_ContactSyncSendLeadsToEN();
        Database.executeBatch(b);

        Test.stopTest();
    }
}