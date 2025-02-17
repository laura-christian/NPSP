/**
 * Retrieve Contact Data for our custom contact sync, via EN API,
 * and populate this into Contact Sync Staging Records.
 * 
 * Data is retrieved using the EN Export Service API. Note that data is returned
 * as CSV so we have no way to batch process the file. We're counting on volume being
 * manageable for tageted transaction types (FCS, FCR, ECS, MSU, HSU) - and if that
 * volume grows, the retrieval of Contact Sync Staging Records will need to be rebuilt
 * using an external ETL tool that does not have Apex governor limits.
 *
 * Authored by Jake Martin White
 * jake@mustardseednonprofit.ca
 *
 */

global class MS_ContactSyncRetrieveDataFromEN implements Queueable, Database.AllowsCallouts {

    global final EN_Dataservice_Settings__mdt settings;
    global final Date trxnDate;
    global List<String> errors = new List<String>();
    global static List<String> reqdHeaderCols = new List<String>{
        'Supporter ID', 'Supporter Email', 'Title', 'First Name', 'Last Name',
        'Address 1', 'City', 'State', 'Zip Code', 'Country', 'Phone Number', 'Mobile Phone Number',
        'Campaign Date', 'Campaign Time', 'Campaign Type', 'Campaign Data 21',
        'Japanese First Name', 'Japanese Last Name', 'Campaign Data 34', 'Campaign ID',
        'External Reference 8', 'External Reference 9', 'External Reference 10'
    };
    global final Set<String> supporterIds = new Set<String>();
    
    global MS_ContactSyncRetrieveDataFromEN(Date trxnDate) {
        this.settings = [SELECT Export_Endpoint__c, Token__c,
              Contact_Sync_Export_Group__c, Contact_Transaction_Codes__c,
              Lead_Transaction_Codes__c, Notification_Emails__c, Import_Batch_Size__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
        this.trxnDate = trxnDate;
    }
    
    global void execute(QueueableContext context) {

        // do the callout, grab the CSV data from EN
        String dateFilter = String.valueOf(trxnDate.month()).leftPad(2,'0')
            + String.valueOf(trxnDate.day()).leftPad(2,'0')
            + String.valueOf(trxnDate.year());

        String typeFilter = settings.Contact_Transaction_Codes__c;
        if (!String.isBlank(settings.Lead_Transaction_Codes__c)) {
            typeFilter += ',' + settings.Lead_Transaction_Codes__c;
        
        String postData = 'token=' + settings.Token__c
            + '&startDate=' + dateFilter
            + '&endDate=' + dateFilter
            + '&type=' + 'CSV'
            + '&exportGroup=' + settings.Contact_Sync_Export_Group__c
            + '&configTypes=' + typeFilter;

        System.debug(postData);
                
        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.Export_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(postData);

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug(res.getStatusCode());

        if (res.getStatusCode() == 200) {
            
            String csvData = res.getBody();
            if (!String.isBlank(csvData)) {
                List<List<String>> results = RT_CSVReader.read(csvData);
                
                // get column indices from the header
                Map<String,Integer> columns = new Map<String,Integer>();
                for (Integer i = 0; i < results[0].size(); i++) {
                    columns.put(results[0][i], i);
                }
                // ensure expected data is present
                for (String col : reqdHeaderCols) {
                    if (!columns.containsKey(col)) {
                        errors.add('Transactional file is missing column: ' + col);
                    }
                }
                
                // build Contact Sync Staging Records
                List<Contact_Sync_Staging_Record__c> cssrsToInsert = new List<Contact_Sync_Staging_Record__c>();
                Boolean skipHeader = true;
                for (List<String> result : results) {
                    if (skipHeader) {
                        skipHeader = false;
                        continue;
                    }
                    if (result[columns.get('Campaign Status')] != 'reject' && result[columns.get('Campaign Status')] != 'pending' && !result[columns.get('Campaign ID')].contains('eCard')) {
                        Contact_Sync_Staging_Record__c cssr = new Contact_Sync_Staging_Record__c(
                            Supporter_Id__c = result[columns.get('Supporter ID')],
                            Supporter_Email__c = result[columns.get('Supporter Email')],
                            Title__c = result[columns.get('Title')],
                            First_Name__c = result[columns.get('First Name')],
                            Last_Name__c = result[columns.get('Last Name')],
                            Address_1__c = result[columns.get('Address 1')],
                            // Address_2__c = result[columns.get('Address 2')],
                            City__c = result[columns.get('City')],
                            State__c = result[columns.get('State')],
                            Zip_Code__c = result[columns.get('Zip Code')],
                            Country__c = result[columns.get('Country')],
                            Phone_Number__c = result[columns.get('Phone Number')],
                            Mobile_Phone_Number__c = result[columns.get('Mobile Phone Number')],
                            Japanese_First_Name__c = result[columns.get('Japanese First Name')],
                            Japanese_Last_Name__c = result[columns.get('Japanese Last Name')],
                            Transaction_Date__c = Date.valueOf(result[columns.get('Campaign Date')]),
                            Transaction_Date_Time__c = DateTime.valueOf(result[columns.get('Campaign Date')] + ' ' + result[columns.get('Campaign Time')]),
                            Transaction_Type__c = result[columns.get('Campaign Type')],
                            Transaction_Data_21__c = result[columns.get('Campaign Data 21')],
                            EN_Tracking_Value__c = result[columns.get('Campaign Data 34')],
                            Campaign_Reference_8__c = result[columns.get('External Reference 8')],
                            Campaign_Reference_9__c = result[columns.get('External Reference 9')],
                            Campaign_Reference_10__c = result[columns.get('External Reference 10')],                            
                            EN_Campaign_Name__c = result[columns.get('Campaign ID')]
                        );
                        cssrsToInsert.add(cssr);
                        supporterIds.add(result[columns.get('Supporter ID')]);
                    }                  
                }
                System.debug('Inserting Contact Sync Staging Records: ' + cssrsToInsert.size());
                Database.insert(cssrsToInsert, false);
                
                // kick off processing of records as a separate batch process
                List<String> supporterIdsListified = new List<String>();
                supporterIdsListified.addAll(supporterIds);
                MS_ContactSyncProcessDataFromEN b = new MS_ContactSyncProcessDataFromEN(trxnDate, supporterIdsListified);
                Database.executeBatch(b, 10);                  
            }          
        }
        else {
            errors.add('EN Response Code: ' + res.getStatusCode()
                + '\n' + 'EN Response Body: ' + res.getBody());
            
			// send email alert
            String emailBody = 'The Contact Sync job did not complete successfully.\n';
            
            for (String msg : errors) {
                System.debug(msg);
                emailBody += '\n' + msg;
            }
            
            String[] toAddresses = settings.Notification_Emails__c.split(',');        
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject('EN-SF Contact Sync Failed');
            mail.setPlainTextBody(emailBody);
			System.debug(emailBody);
            if (!Test.isRunningTest()) {Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });}            
        }
	}
}
}