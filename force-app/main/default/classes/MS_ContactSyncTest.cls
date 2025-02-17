/**
 * See MS_RetrieveContactData for comments
 *
 * Authored by Jake Martin White
 * jake@mustardseednonprofit.ca
 */
 
@istest
global class MS_ContactSyncTest {
    global class ENExportServiceMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Account ID,Supporter ID,Supporter Email,Date Created,Date Modified,Campaign Number,Campaign Type,Campaign ID,Campaign Date,Campaign Time,Campaign Status,Campaign Data 1,Campaign Data 2,Campaign Data 3,Campaign Data 4,Campaign Data 5,Campaign Data 6,Campaign Data 7,Campaign Data 8,Campaign Data 9,Campaign Data 10,Campaign Data 11,Campaign Data 12,Campaign Data 13,Campaign Data 14,Campaign Data 15,Campaign Data 16,Campaign Data 17,Campaign Data 18,Campaign Data 19,Campaign Data 20,Campaign Data 21,Campaign Data 22,Campaign Data 23,Campaign Data 24,Campaign Data 25,Campaign Data 26,Campaign Data 27,Campaign Data 28,Campaign Data 29,Campaign Data 30,Campaign Data 31,Campaign Data 32,Campaign Data 33,Campaign Data 34,Campaign Data 35,External Reference 6,External Reference 7,External Reference 8,External Reference 9,External Reference 10,Origin Source,Email Address,Title,First Name,Last Name,Address 1,City,State,Zip Code,Country,Phone Number,Mobile Phone Number,Japanese First Name,Japanese Last Name' + '\n' +
                '"2258","209191155","andrew.highlandtours@gmail.com","2021-03-31","2021-03-31","210342","FCR","USD Donation Page Stripe Test","2021-03-31","21:01:43","success","22611123","pm_1IbEueHFzDpavqBwUKdWKj1r__cus_JDgHyVCdYn4IWF__pi_1IbEuoHFzDpavqBwUobL6Zuu","","2.00","USD","amex","R","30","MONTHLY","CANCELED","","Stripe Gateway","08/2024","N","0","","","","","","","","","","","2.00","1.45","1.70","2.51","2.63","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","andrew.highlandtours@gmail.com","","Andrew","Smith","13993 Fern Road","Guerneville","CA","95446","US",,,,\n' +
                '"2258","209191155","andrew.highlandtours@gmail.com","2021-03-31","2021-03-31","210342","FCS","USD Donation Page Stripe Test","2021-03-31","21:01:44","success","22611124","pm_1IbEueHFzDpavqBwUKdWKj1r__cus_JDgHyVCdYn4IWF__pi_1IbEuoHFzDpavqBwUobL6Zuu","","2.00","USD","amex","R","30","MONTHLY","CANCELED","","Stripe Gateway","08/2024","N","0","","","","","","Dupe Org","","","","","2.00","1.45","1.70","2.51","2.63","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","andrew.highlandtours@gmail.com","","Andrew","Smith","13993 Fern Road","Guerneville","CA","95446","US",,,,\n' +                
                '"2258","209191155","andrew.highlandtours@gmail.com","2021-03-31","2021-03-31","210342","FCS","USD Donation Page Stripe Test","2021-03-31","21:01:45","success","22611125","pm_1IbEueHFzDpavqBwUKdWKj1r__cus_JDgHyVCdYn4IWF__pi_1IbEuoHFzDpavqBwUobL6Zuu","","2.00","USD","amex","R","30","MONTHLY","CANCELED","","Stripe Gateway","08/2024","N","0","","","","","","New Org","","","","","2.00","1.45","1.70","2.51","2.63","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","andrew.highlandtours@gmail.com","","Andrew","Smith","13993 Fern Road","Guerneville","CA","95446","US",,,,\n' +                
                '"2258","209191156","not_in@gmail.com","2021-03-31","2021-03-31","210342","FCS","USD Donation Page Stripe Test","2021-03-31","21:01:46","success","22611126","pm_1IbEueHFzDpavqBwUKdWKj1r__cus_JDgHyVCdYn4IWF__pi_1IbEuoHFzDpavqBwUobL6Zuu","","2.00","USD","amex","R","30","MONTHLY","CANCELED","","Stripe Gateway","08/2024","N","0","","","","","","","","","","","2.00","1.45","1.70","2.51","2.63","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","not_in@gmail.com","","NotIn","SalesforceYet","555 Anywhere Road","Guerneville","CA","95446","US",,,,\n' +
                '"2258","209191156","not_in@gmail.com","2021-03-31","2021-03-31","210342","FCS","USD Donation Page Stripe Test","2021-03-31","21:01:47","success","22611127","pm_1IbEueHFzDpavqBwUKdWKj1r__cus_JDgHyVCdYn4IWF__pi_1IbEuoHFzDpavqBwUobL6Zuu","","2.00","USD","amex","R","30","MONTHLY","CANCELED","","Stripe Gateway","08/2024","N","0","","","","","","","","","","","2.00","1.45","1.70","2.51","2.63","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","not_in@gmail.com","","NotIn","SalesforceYet","555 Anywhere Road","Guerneville","CA","95446","US",,,,\n' +
                '"2258","209191157","shared_email@gmail.com","2021-03-31","2021-03-31","210342","FCS","USD Donation Page Stripe Test","2021-03-31","21:01:48","success","22611128","pm_1IbEueHFzDpavqBwUKdWKj1r__cus_JDgHyVCdYn4IWF__pi_1IbEuoHFzDpavqBwUobL6Zuu","","2.00","USD","amex","R","30","MONTHLY","CANCELED","","Stripe Gateway","08/2024","N","0","","","","","","","","","","","2.00","1.45","1.70","2.51","2.63","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","shared_email@gmail.com","","Shared","Email","550 Anywhere Road","Guerneville","CA","95446","US",,,,\n' +
                '"2258","206838456","salma.nakhuda@roomtoread.org","2021-03-15","2021-03-31","210342","DCF","Lead Test","2021-03-31","18:00:40","P","","","","","","","","","","","","","","","","","","","","","","","","","","1.00",".73",".85","1.26","1.32","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","salma.nakhuda@roomtoread.org","Ms.","Salma","Nakhuda","2180 Lewis Street","Hercules","CA","94547","US","1234467890","+19999999999",,\n' +
                '"2258","206838458","shared_email_lead@gmail.com","2021-03-15","2021-03-31","210342","DCF","Lead Test","2021-03-31","18:00:40","P","","","","","","","","","","","","","","","","","","","","","","","","","","1.00",".73",".85","1.26","1.32","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","shared_email_lead@gmail.com","","Dupe","Lead","2180 Lewis Street","Hercules","CA","94547","US","1234467890","+19999999999",,\n' +
                '"2258","209191155","andrew.highlandtours@gmail.com","2021-03-31","2021-03-31","210342","DCF","Lead Test","2021-03-31","21:01:41","success","22611123","pm_1IbEueHFzDpavqBwUKdWKj1r__cus_JDgHyVCdYn4IWF__pi_1IbEuoHFzDpavqBwUobL6Zuu","","2.00","USD","amex","R","30","MONTHLY","CANCELED","","Stripe Gateway","08/2024","N","0","","","","","","","","","","","2.00","1.45","1.70","2.51","2.63","","mobile:N~tablet:N~device:MICROSOFT~os:Windows 10~browser:Chrome 8","https://e-activist.com/page/79012/donate/1?mode=DEMO","","","","","","","","","andrew.highlandtours@gmail.com","","Andrew","Smith","13993 Fern Road","Guerneville","CA","95446","US",,,,\n');
            return res;
        }
    }

    global class ENExportServiceFailureMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Mismatched headers');
            return res;
        }
    }
    
    static testmethod void testRetrieveData() {

        Test.setMock(HttpCalloutMock.class, new ENExportServiceMock());
        
        EN_Dataservice_Settings__mdt settings = [SELECT Contact_Sync_Household_Record_Type__c,
                Contact_Sync_Organization_Record_Type__c,
                Contact_Transaction_Codes__c,
                Lead_Transaction_Codes__c, Notification_Emails__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
            
        // insert a duplicate contact
        Account a1 = new Account(
            Name = 'Duplicate Household',
            RecordTypeId = settings.Contact_Sync_Household_Record_Type__c
        );
        insert a1;
        Contact c1 = new Contact(
            AccountId = a1.Id,
            FirstName = 'Andrew',
            LastName = 'Smith',
            npe01__Preferred_Email__c = 'Personal',
            npe01__HomeEmail__c = 'smithand@gmail.com',
            npe01__WorkEmail__c = 'andrew@highlandtours.com',
            npe01__AlternateEmail__c = 'alt_email@me.com',
            MailingStreet = '13993 Fern Road',
            MailingCity = 'Guerneville',
            MailingState = 'CA',
            MailingPostalCode = '95446', 
            MailingCountry = 'US'
        );
        insert c1;
        
        // insert a shared email address
        Account a2 = new Account(
            Name = 'SharedEmail Household',
            RecordTypeId = settings.Contact_Sync_Household_Record_Type__c
        );
        insert a2;
        Contact c2 = new Contact(
            AccountId = a2.Id,
            FirstName = 'Different',
            LastName = 'Name',
            npe01__AlternateEmail__c = 'shared_email@gmail.com',
            npe01__Preferred_Email__c = 'Alternate',
            Email = 'shared_email@gmail.com',
            MailingStreet = '550 Anywhere Road',
            MailingCity = 'Guerneville',
            MailingState = 'CA',
            MailingPostalCode = '95446', 
            MailingCountry = 'US'
        );
        insert c2;
                
        // insert a duplicate lead
        Lead l = new Lead(
            FirstName = 'Dupe',
            LastName = 'Lead',
            Company = 'Individual',
            Email = 'shared_email_lead@gmail.com'
        );
        insert l;
        
        // insert a duplicate Organization
        Account a3 = new Account(
            Name = 'Dupe Org',
            BillingCity = 'Guerneville',
            BillingCountry = 'US',
            RecordTypeId = settings.Contact_Sync_Organization_Record_Type__c
        );
        insert a3;
        
        Test.startTest();
        
        // run batch
       	System.enqueueJob(new MS_ContactSyncRetrieveDataFromEN(Date.newInstance(2021,3,31)));
                
        Test.stopTest();

        List<Contact_Sync_Staging_Record__c> failedResults = [
            SELECT Id, Supporter_Id__c, Supporter_Email__c, Transaction_Data_21__c, Error_Details__c,
                Matched_Account__c, Matched_Contact__c, Matched_Lead__c, Matched_Organization__c, Transaction_Date_Time__c
            FROM Contact_Sync_Staging_Record__c
            WHERE Processed__c = false
        ];
        for (Contact_Sync_Staging_Record__c r : failedResults ) {
            System.debug('Not Processed: ' + r.Supporter_Id__c + '/' + r.Supporter_Email__c + '/' + r.Transaction_Date_Time__c
                + '/Error: ' + r.Error_Details__c);
        }
        
                
        List<Contact_Sync_Staging_Record__c> results = [
            SELECT Id, Supporter_Id__c, Supporter_Email__c, Transaction_Data_21__c, Match_Method__c,
                Matched_Account__c, Matched_Contact__c, Matched_Lead__c, Matched_Organization__c, Transaction_Date_Time__c
            FROM Contact_Sync_Staging_Record__c
            WHERE Processed__c = True
        ];
        for (Contact_Sync_Staging_Record__c r : results ) {
            System.debug('Processed: ' + r.Supporter_Id__c + '/' + r.Supporter_Email__c + '/' + r.Transaction_Date_Time__c
                + '/Match method: ' + r.Match_Method__c);
        }
        System.assertEquals(9, results.size());
        
        // check correct contact count
        List<Contact> contacts = [
            SELECT Id
            FROM Contact
        ];
        System.assertEquals(4, contacts.size());
     
        // check correct lead count - one for Salma, one for shared_email_lead@gmail.com. none for Andrew.
        List<Lead> leads = [
            SELECT Id
            FROM Lead
        ];
        System.assertEquals(2, leads.size());   
        
        // check accurate matching on duplicate contact and shared contact
        for (Contact_Sync_Staging_Record__c cssr : results) {
            if (cssr.Supporter_Email__c == 'andrew.highlandtours@gmail.com') {
                System.assertEquals(cssr.Matched_Contact__c, c1.Id);
                if (cssr.Transaction_Data_21__c == 'Dupe Org') {
                    System.assertEquals(a3.Id, cssr.Matched_Organization__c);
                }
            }
            if (cssr.Supporter_Email__c == 'shared_email@gmail.com') {
                System.assertEquals(cssr.Matched_Account__c, a2.Id);
                System.assertNotEquals(cssr.Matched_Contact__c, c2.Id);
            }   
            if (cssr.Supporter_Email__c == 'shared_email_lead@gmail.com') {
                System.assertEquals(cssr.Matched_Lead__c, l.Id);
            }
        }
        
        // check shared account
        contacts = [
            SELECT Id
            FROM Contact
            WHERE AccountId = :a2.Id
        ];
        System.assertEquals(2, contacts.size());
        
        // check Dupe Org account
        Account[] accounts = [
            SELECT Id
            FROM Account
            WHERE Name = 'Dupe Org'
        ];
        System.assertEquals(1, accounts.size());
        
        // check new account
        accounts = [
            SELECT Id
            FROM Account
            WHERE Name = 'New Org'
        ];
        System.assertEquals(1, accounts.size());
        
    }
    
    static testmethod void testEmailMatching() {
    
        EN_Dataservice_Settings__mdt settings = [SELECT Contact_Sync_Household_Record_Type__c,
                Contact_Sync_Organization_Record_Type__c,
                Contact_Transaction_Codes__c,
                Lead_Transaction_Codes__c, Notification_Emails__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
                
        Contact_Sync_Staging_Record__c cssr1 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191155',
        Supporter_Email__c = 'test@email.com',
        Title__c = 'Ms.',
        First_Name__c = 'Test',
        Last_Name__c = 'Supporter',
        Japanese_First_Name__c = 'テスト',
        Japanese_Last_Name__c = 'サポーター',        
        Transaction_Type__c = 'FCS', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
        
        Contact_Sync_Staging_Record__c cssr2 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191156',
        Supporter_Email__c = 'work_email@acme.com',
        First_Name__c = 'Workplace',
        Last_Name__c = 'Supporter',
        Phone_Number__c = '(999) 999-9999',
        Transaction_Type__c = 'FCS', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today()); 
        
        Contact_Sync_Staging_Record__c cssr3 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191157',
        Supporter_Email__c = 'alt_email@test.net',
        First_Name__c = 'Other',
        Last_Name__c = 'Supporter',
        Mobile_Phone_Number__c = '+19999999999',
        Transaction_Type__c = 'FCS', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
        
        List<Contact_Sync_Staging_Record__c> cssrs = new List<Contact_Sync_Staging_Record__c>{cssr1, cssr2, cssr3};
        insert cssrs;
        
        Account a = new Account(
            Name = 'Test Supporter Household',
            RecordTypeId = settings.Contact_Sync_Household_Record_Type__c
        );
        insert a;
        
        Contact con1 = new Contact(
        AccountId = a.Id,
        FirstName = 'Test',
        LastName = 'Supporter',
        npe01__Preferred_Email__c = 'Personal',
        npe01__HomeEmail__c = 'test@email.com',
        npe01__WorkEmail__c = 'work_email@acme.com',
        npe01__AlternateEmail__c = 'alt_email@test.net',
        Email = 'test@email.com');
        
        Contact con2 = new Contact(
        AccountId = a.Id,
        FirstName = 'Workplace',
        LastName = 'Supporter',
        npe01__Preferred_Email__c = 'Work',
        npe01__HomeEmail__c = 'test@email.com',
        npe01__WorkEmail__c = 'work_email@acme.com',
        Email = 'work_email@acme.com');
        
        Contact con3 = new Contact(
        AccountId = a.Id,
        FirstName = 'Other',
        LastName = 'Supporter',
        npe01__Preferred_Email__c = 'Personal',
        npe01__HomeEmail__c = 'my_personal_email@test.com',
        npe01__AlternateEmail__c = 'alt_email@test.net',
        Email = 'my_personal_email@test.com');
        
        List<Contact> contacts = new List<Contact>{con1, con2, con3};
        insert contacts;
        
        Test.startTest();
        Database.executeBatch(new MS_ContactSyncProcessDataFromEN(System.today(), new List<String>{'209191155','209191156','209191157'}));
        Test.stopTest();
        
        System.assertEquals('Alternate', [SELECT Id, Name, npe01__Preferred_Email__c FROM Contact WHERE Id = :con3.Id][0].npe01__Preferred_Email__c);
        
    }
    
    static testmethod void testErrorHandlingDMLOps() {
        Contact_Sync_Staging_Record__c cssr1 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191160',
        Supporter_Email__c = 'home@email.net',
        Title__c = 'Ms.',
        First_Name__c = 'Test', 
        Last_Name__c = 'Contact',
        Address_1__c = '123 Main St', 
        City__c = 'Anytown', 
        State__c = 'CA', 
        Zip_Code__c = '99999', 
        Country__c = 'US', 
        Phone_Number__c = '(999) 999-9999',
        Transaction_Type__c = 'FCR', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
        insert cssr1;
        
        Contact_Sync_Staging_Record__c cssr2 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191161',
        Supporter_Email__c = 'my_email@yahoo.com',
        First_Name__c = 'Test', 
        Last_Name__c = 'Contact II',
        Transaction_Type__c = 'DCF', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
        insert cssr2;

        Contact_Sync_Staging_Record__c cssr3 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191162',
        Supporter_Email__c = 'testemail@test.com',
        First_Name__c = 'Test', 
        Last_Name__c = 'Contact III',
        Address_1__c = '123 Main St', 
        City__c = 'Anytown', 
        State__c = 'CA', 
        Zip_Code__c = '99999', 
        Country__c = 'US', 
        Mobile_Phone_Number__c = '+19999999999',
        Transaction_Type__c = 'FCR', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
        insert cssr3;
        
        Contact_Sync_Staging_Record__c cssr4 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191163',
        Supporter_Email__c = 'testcontact4@me.com',
        First_Name__c = 'Test', 
        Last_Name__c = 'Contact IV',
        Address_1__c = '123 Broadway Ste 1000', 
        City__c = 'City Center', 
        State__c = 'CA', 
        Zip_Code__c = '99999', 
        Country__c = 'US',
        Transaction_Type__c = 'FCS', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
        insert cssr4;
        
        Contact_Sync_Staging_Record__c cssr5 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191164',
        Transaction_Data_21__c = 'Acme Co.',
        Supporter_Email__c = 'testcontact5@acme.com',
        First_Name__c = 'Test', 
        Last_Name__c = 'Contact V',
        Address_1__c = '123 Broadway Ste 1000', 
        City__c = 'City Center', 
        State__c = 'CA', 
        Zip_Code__c = '99999', 
        Country__c = 'US',
        Transaction_Type__c = 'FCS', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
    	insert cssr5;        
        
        Test.startTest();
        Database.executeBatch(new MS_ContactSyncProcessDataFromEN(System.today(), new List<String>{'209191160','209191161','209191162','209191103','209191164'}));
        Test.stopTest();
    }
    
    static testmethod void testLeadsWithDupes() {
        EN_Dataservice_Settings__mdt settings = [SELECT Contact_Sync_Household_Record_Type__c,
                Contact_Sync_Organization_Record_Type__c,
                Contact_Transaction_Codes__c,
                Lead_Transaction_Codes__c, Notification_Emails__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
            
        Contact_Sync_Staging_Record__c cssr = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191161',
        Supporter_Email__c = 'my_email@yahoo.com',
        First_Name__c = 'Dupe', 
        Last_Name__c = 'Lead',
        Transaction_Type__c = 'DCF', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());       

        Contact_Sync_Staging_Record__c cssr2 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191162',
        Supporter_Email__c = 'converted_lead@yahoo.com',
        First_Name__c = 'Converted', 
        Last_Name__c = 'Lead',
        Transaction_Type__c = 'DCF', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());
        
        Contact_Sync_Staging_Record__c cssr3 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191163',
        Supporter_Email__c = 'subscriber@gmail.com',
        First_Name__c = 'New', 
        Last_Name__c = 'Lead',
        Transaction_Type__c = 'DCF', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());         

        Contact_Sync_Staging_Record__c cssr4 = new Contact_Sync_Staging_Record__c(
        Supporter_Id__c = '209191163',
        Supporter_Email__c = 'subscriber@gmail.com',
        First_Name__c = 'New', 
        Last_Name__c = 'Lead',
        Transaction_Type__c = 'DCF', 
        Transaction_Date_Time__c = System.now(), 
        Transaction_Date__c = System.today());        
        
        List<Contact_Sync_Staging_Record__c> cssrs = new List<Contact_Sync_Staging_Record__c>{cssr, cssr2, cssr3, cssr4};
        insert cssrs;
        
        Lead l = new Lead(
        FirstName = 'Dupe',
        LastName = 'Lead',
        Company = 'Household',
        Email = 'my_email@yahoo.com');
        insert l;
        
        Account a = new Account(
            Name = 'Converted Lead Household',
            RecordTypeId = settings.Contact_Sync_Household_Record_Type__c
        );
        insert a;
        
        Contact c = new Contact(
        FirstName = 'Converted',
        LastName = 'Lead',
        AccountId = a.Id,
        npe01__Preferred_Email__c = 'Personal',
        npe01__HomeEmail__c = 'converted_lead@yahoo.com',
        Email = 'converted_lead@yahoo.com');
        insert c;
        
        Test.startTest();
        Database.executeBatch(new MS_ContactSyncProcessDataFromEN(System.today(), new List<String>{'209191161','209191162','209191103'}));
        Test.stopTest(); 
        
        System.assertEquals([SELECT Id, Name FROM Lead WHERE Id = :l.Id][0].Id, [SELECT Id, Matched_Lead__c FROM Contact_Sync_Staging_Record__c WHERE Id = :cssr.Id][0].Matched_Lead__c);
    }
    
    static testmethod void testCalloutFail() {

        Test.setMock(HttpCalloutMock.class, new ENExportServiceFailureMock());
        
        Test.startTest();

        // run schedule
        String jobId = System.schedule('testRetrieveContacts',
            '0 0 23 * * ?', new MS_ContactSyncSchedulable());

        Test.stopTest();
    }
}