@isTest
global class MS_ContactSyncSendCRMSegmentToENTest {
 
    global class ENImportServiceMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
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
    
    @isTest
    static void testSuccess() {
        
        Campaign cmpn = new Campaign(
            Name = 'Test CRM Segment',
            IsActive = true
        );
        insert cmpn;
        
        Contact c1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            npe01__HomeEmail__c = 'test.contact@email.com',
            npe01__Preferred_Email__c = 'Personal',             
            Email = 'test.contact@email.com'
        );
        insert c1;

        Lead l1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Lead Household',
            Email = 'test_lead@me.com'
        );
        insert l1;
        
        CampaignMember cm1 = new CampaignMember(
        	ContactId = c1.Id,
            CampaignId = cmpn.Id
        );
        insert cm1;
        
        CampaignMember cm2 = new Campaignmember(
        	LeadId = l1.Id,
        	CampaignId = cmpn.Id
        );
        insert cm2;

		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ENImportServiceMock());
        PageReference pageRef = Page.SendCRMSegmentToEN_VF;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(cmpn);
        CRMSegmentPushExt extension = new CRMSegmentPushExt(sc);
        extension.sendCRMSegmentToEN();
        Test.stopTest();
    }
    
    static testmethod void testFail() {
        Campaign cmpn = new Campaign(
            Name = 'Test CRM Segment',
            IsActive = true
        );
        insert cmpn;
                              
        Contact c1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            npe01__HomeEmail__c = 'test.contact@email.com',
            npe01__Preferred_Email__c = 'Personal',            
            Email = 'test.contact@email.com'
        );
        insert c1;
        
        CampaignMember cm1 = new CampaignMember(
        	ContactId = c1.Id,
            CampaignId = cmpn.Id
        );
        insert cm1;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ENImportServiceFailureMock());
        Database.executeBatch(new MS_ContactSyncSendCRMSegmentToEN(cmpn));
        Test.stopTest();
    }
}