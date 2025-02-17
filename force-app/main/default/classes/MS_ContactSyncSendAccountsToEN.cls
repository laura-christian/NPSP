/**
 * Pushes data from Lead and Account objects to Engaging Networks, to supplement the
 * out-of-box contact sync.
 *
 * Data is sent via the EN Import Service API, which requires a CSV format.
 *
 * Authored by Jake Martin White
 * jake@mustardseednonprofit.ca
 *
 */
 
global class MS_ContactSyncSendAccountsToEN implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global final EN_Dataservice_Settings__mdt settings;
    global List<EN_Contact_Push_Mapping__mdt> mappings;
    global Integer failedBatches = 0;
    global Integer contactCount = 0;
    global Integer calloutCount = 0;
    global String[] enErrors = new String[]{};
    
    global MS_ContactSyncSendAccountsToEN() {
        settings = [SELECT Import_Endpoint__c, Token__c, Account_Import_Format_Name__c, Notification_Emails__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // build the query from metadata
        mappings = [SELECT Column_Position__c, SF_Field_API_Name__c, ENS_Column_Name__c, Date_Field__c, Boolean_Field__c, Currency_Field__c
            FROM EN_Contact_Push_Mapping__mdt
            WHERE Object__c = 'Account'
            ORDER BY Column_Position__c];
        
        List<String> sfFields = new List<String>();    
        for (EN_Contact_Push_Mapping__mdt m : mappings) {
            if (m.Currency_Field__c) {sfFields.add('convertCurrency(' + m.SF_Field_API_Name__c + ')');}
            else {sfFields.add(m.SF_Field_API_Name__c);}
        }
        String sfQuery = String.join(sfFields, ',');
        
        // collect recently modified Accounts
        String query = 'SELECT Id, EN_Push__c, ' + sfQuery + ', ' +
            '(SELECT Id, Email, Is_Covered_By_GDPR__c, Email_Opted_In__c, HasOptedOutOfEmail, Newsletter__c, Book_Club__c, She_Creates_Change__c, Do_Not_Solicit__c, npsp__Do_Not_Contact__c, EN_Salesforce_Opt_In_Status__c, SMS_Opt_In__c FROM Contacts) ' + 
            'FROM Account ' +
            'WHERE EN_Push__c = true LIMIT 75000';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> items) {        
        String csvContent = buildRequest(items);
        Boolean success = sendRequest(csvContent);
        
        if (success) {
            // reset flag on Account
            for (Account a : items) {
                a.EN_Push__c = false;
            }
            update items;
        }
        else {
            failedBatches++;
        }
    }
    
    global String buildRequest(List<Account> items) {
        List<String> headers = new List<String>();
        for (EN_Contact_Push_Mapping__mdt m : mappings) {
            if (m.ENS_Column_Name__c != 'Email Address') {
                headers.add(m.ENS_Column_Name__c);
            }
        }        
        String csvHeader = 'Email Address,Salesforce Type,Contact Id from Account Sync,Email Opt-In,Global Opt-Out,Newsletter Opt-In,Book Club Opt-In,She Creates Change Opt-In,Solicitations Opt-In,Salesforce Opt-In Status,SMS Opt-In,' + String.join(headers, ',');
        
        String csvContent = '';
        List<String> processed = new List<String>();
        for (Account a : items) {
            for (Contact c : a.Contacts) {
                if (!String.isBlank(c.Email) && !processed.contains(c.Email)) {
                    String optIn = '';
                    String optOut = '';
                    String newsletter = '';
                    String bookClub = '';
                    String sheCreatesChange = '';
                    String solicitations = '';
                    String salesforceOptInStatus = '';
                    String smsOptIn = '';
                    if (c.Email_Opted_In__c == true) {optIn = 'Y';}
                    else {optIn = 'N';}
                    if (c.HasOptedOutOfEmail == true) {optOut = 'Y';}
                    else {optOut = 'N';}
                    if (c.HasOptedOutOfEmail == true || c.npsp__Do_Not_Contact__c  == true) {newsletter = 'N';}
                    else if (c.Is_Covered_By_GDPR__c == true && c.Email_Opted_In__c == false) {newsletter = 'N';}
                    else if (c.Is_Covered_By_GDPR__c == true && c.Email_Opted_In__c == true && c.Newsletter__c == true) {newsletter = 'Y';}
                    else if (c.Is_Covered_By_GDPR__c == false && c.Newsletter__c == true) {newsletter = 'Y';}
                    else {newsletter = 'N';}
                    if (c.Book_Club__c == true && c.HasOptedOutOfEmail == false && c.npsp__Do_Not_Contact__c  == false) {bookClub = 'Y';}
                    else {bookClub = 'N';}
                    if (c.She_Creates_Change__c == true && c.HasOptedOutOfEmail == false && c.npsp__Do_Not_Contact__c == false) {sheCreatesChange = 'Y';}
                    else {sheCreatesChange = 'N';}
                    if (c.Do_Not_Solicit__c == true || c.HasOptedOutOfEmail == true || c.npsp__Do_Not_Contact__c  == true) {solicitations = 'N';}
                    else if (c.Is_Covered_By_GDPR__c == true && c.Email_Opted_In__c == false) {solicitations = 'N';}
                    else if (c.Is_Covered_By_GDPR__c == false && c.Do_Not_Solicit__c == false) {solicitations = 'Y';}
                    if (c.EN_Salesforce_Opt_In_Status__c != 'Y' && c.EN_Salesforce_Opt_In_Status__c != 'N') {salesforceOptInStatus = '[CLEAR]';}
                    else {salesforceOptInStatus = c.EN_Salesforce_Opt_In_Status__c;}                   
                    if (c.SMS_Opt_IN__c == true) {smsOptIn = 'Y';}
                    else {smsOptIn = 'N';}
                    List<String> values = new List<String>();
                    for (EN_Contact_Push_Mapping__mdt m : mappings) {
                        String v = String.valueOf(a.get(m.SF_Field_API_Name__c));
                        if (v == null && !m.Currency_Field__c) {
                            v = '[CLEAR]';
                        }
                        else if (v == null && m.Currency_Field__c) {
                            v = '0';
                        }
                        v = v.replace('"', '').replace('\\', ''); // get rid of characters EN cannot import
                        if (m.Date_Field__c) { // format dates as YYYYMMDD, strip time component
                            v = v.replace('-', '');
                            v = v.left(8);
                        }
                        else if (m.Boolean_Field__c) { // format boolean as Y/N
                            if (v.toLowerCase() == 'true') {
                                v = 'true';
                            }
                            else {
                                v = 'false';
                            }
                        }
                        else if (m.Currency_Field__c) {
                            Decimal usdValue = Decimal.valueOf(v);
                            usdValue = usdValue.setScale(2);
                            v = String.valueOf(usdValue);
                        }
                        if (v.contains(',')) {  // add quotes if there's a comma in the value
                            v = '"' + v + '"';
                        }
                        values.add(v);
                    }
                    csvContent += '\r\n' + c.Email + ',Contact,' + c.Id + ',' + optIn + ',' + optOut + ',' + newsletter + ',' + bookClub + ',' + sheCreatesChange + ',' + solicitations + ',' + salesforceOptInStatus + ',' + smsOptIn + ',' + String.join(values,',');
                    processed.add(c.Email);
                }
                contactCount++;
            }
        }
        return csvHeader + csvContent;
    }
    
    global Boolean sendRequest(String csvContent) {
        String reference = String.valueOf(Date.today()).replace('-','') + '-' + calloutCount;
        String separator = '-----EN_SEP';
        String postData = '--' + separator
            + '\r\nContent-Disposition: form-data; name="token";'
            + '\r\n\r\n' + settings.Token__c
            + '\r\n--' + separator
            + '\r\nContent-Disposition: form-data; name="name";'
            + '\r\n\r\n' + 'DailyAccountSync-' + reference
            + '\r\n--' + separator
            + '\r\nContent-Disposition: form-data; name="formatName";'
            + '\r\n\r\n' + settings.Account_Import_Format_Name__c
            + '\r\n--' + separator
            + '\r\nContent-Disposition: form-data; name="upload"; filename="DailyAccountSync-' + reference + '.csv"'
            + '\r\nContent-Type: text/csv\r\n\r\n';
        String footer = '\r\n--' + separator + '--';
        String payload = postData + csvContent + footer;
        
        System.debug(payload);
                
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + separator);
        req.setHeader('Content-Length', String.valueof(payload.length()));
        req.setMethod('POST');
        req.setEndpoint(settings.Import_Endpoint__c);
        req.setBody(payload);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        calloutCount++;
        
        System.debug(res.getBody());

        /* use this to log the files that are being sent */
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
        conVer.PathOnClient = 'DailyAccountSync-' + reference + '.csv';
        conVer.Title = 'Account Sync Output Files ' + reference; // Display name of the files
        conVer.VersionData = Blob.valueOf(csvContent);
        insert conVer;
       
        if (res.getStatusCode() == 200 && res.getBody() != null
                && res.getBody().contains('Your file has been uploaded successfully and scheduled for import')) {
            return true;
        }
        else {
            enErrors.add('EN Response Code: ' + res.getStatusCode() + '\n' + 'EN Response Body: ' + res.getBody());
            return false;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if (failedBatches > 0) {
            // send email alert
            String emailBody = 'Failed Batches: ' + failedBatches
                + '\n\nThe nightly Account sync job (SF-to-EN) did not complete. Affected records will be '
                + 'reattempted during the next scheduled run.'
                + '\n\nThe following errors were returned from the Engaging Networks Import Service.\n';
            for (String msg : enErrors) {
                emailBody += '\n' + msg;
            }
            
            emailBody += '\n\nTotal Items: ' + contactCount;

            String[] toAddresses = settings.Notification_Emails__c.split(',');        
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject('Salesforce could not push updated Account data to Engaging Networks');
            mail.setPlainTextBody(emailBody);
            if (!Test.isRunningTest()) {Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });}
        }
    }
}