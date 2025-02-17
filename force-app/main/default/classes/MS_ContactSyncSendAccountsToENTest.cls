/**
 * See MS_ContactSyncSendAccountsToEN for comments
 *
 * Authored by Jake Martin White
 * jake@mustardseednonprofit.ca
 */
 
@istest
global class MS_ContactSyncSendAccountsToENTest {
 
    global class ENImportServiceMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            System.assertEquals(true, req.getBody().contains('sue@test.com'));
            System.assertEquals(true, req.getBody().contains('bob@test.com'));
            System.assertEquals(true, req.getBody().contains('alice@test.com'));
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
        Account a1 = new Account(
            Name = 'Susan Test Household',
            RecordTypeId = '0128b000000XLomAAG',
            Type = 'Household',
            CurrencyIsoCode = 'EUR',
            npo02__LargestAmount__c = 1000,
            npo02__FirstCloseDate__c = System.today()-90,
            EN_Push__c = true
        );
        insert a1;
        
        Account a2 = new Account(
            Name = 'Alice Test Household',
            RecordTypeId = '0128b000000XLomAAG',
            Type = 'Household',            
            EN_Push__c = true
        );
        insert a2;

        Account a3 = new Account(
            Name = 'DoNotPush Household',
            RecordTypeId = '0128b000000XLomAAG',
            Type = 'Household',            
            EN_Push__c = false
        );
        insert a3;
                        
        Contact c1 = new Contact(
            AccountId = a1.Id,
            FirstName = 'Susan',
            LastName = 'Test',
            npe01__HomeEmail__c = 'sue@test.com',
            npe01__Preferred_Email__c = 'Personal',            
            Email = 'sue@test.com',
            Email_Opted_In__c = true,
            HasOptedOutOfEmail = false,
            Newsletter__c = true,
            Book_Club__c = false,
            Do_Not_Solicit__c = true, 
            SMS_Opt_In__c = true,
            SMS_Consent_Date__c = System.today()-90,
            MobilePhone = '+19999999999'
        );
        Contact c2 = new Contact(
            AccountId = a1.Id,
            FirstName = 'Bob',
            LastName = 'Test',
            npe01__HomeEmail__c = 'bob@test.com',
            npe01__Preferred_Email__c = 'Personal',            
            Email = 'bob@test.com',
            Email_Opted_In__c = false,
            HasOptedOutOfEmail = false,
            Newsletter__c = false,
            Book_Club__c = true,
            Do_Not_Solicit__c = false,
			SMS_Opt_In__c = false            
        );
        Contact c3 = new Contact(
            AccountId = a2.Id,
            FirstName = 'Alice',
            LastName = 'Test',
            npe01__HomeEmail__c = 'alice@test.com',
            npe01__Preferred_Email__c = 'Personal',
            Email = 'alice@test.com',
            Email_Opted_In__c = false,
            HasOptedOutOfEmail = true,
            Newsletter__c = true,
            Book_Club__c = true,
            Do_Not_Solicit__c = false,
			SMS_Opt_In__c = false            
        );
        Contact c4 = new Contact(
            AccountId = a3.Id,
            FirstName = 'DoNotPush',
            LastName = 'Test',
            npe01__HomeEmail__c = 'donotpush@test.com',
            npe01__Preferred_Email__c = 'Personal',            
            Email = 'donotpush@test.com'
        );
        insert c1;
        insert c2;
        insert c3;
        insert c4;
        
        // reset push flag for donotpush test - contact insert would have hit a workflow and been flagged as true
        a3.EN_Push__c = false;
        update a3;
        
        Test.setMock(HttpCalloutMock.class, new ENImportServiceMock());
        
        Test.startTest();
        
        String jobId = System.schedule('testSendDateToEN',
            '0 0 23 * * ?', new MS_ContactSyncSendDataToENSchedulable());

        Test.stopTest();
    }
    
    static testmethod void testFail() {
        Account a1 = new Account(
            Name = 'Susan Test Household',
            RecordTypeId = '0128b000000XLomAAG',
            Type = 'Household',            
            EN_Push__c = true
        );
        insert a1;
        
        Contact c1 = new Contact(
            AccountId = a1.Id,
            FirstName = 'Susan',
            LastName = 'Test',
            Email = 'sue@test.com'
        );
        insert c1;
        
        Test.setMock(HttpCalloutMock.class, new ENImportServiceFailureMock());
        
        Test.startTest();
        
        String jobId = System.schedule('testSendDateToEN',
            '0 0 23 * * ?', new MS_ContactSyncSendDataToENSchedulable());

        Test.stopTest();
    }
}