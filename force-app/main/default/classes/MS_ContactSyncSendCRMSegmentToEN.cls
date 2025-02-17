global class MS_ContactSyncSendCRMSegmentToEN implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global final EN_Dataservice_Settings__mdt settings;
    global Integer failedBatches = 0;
    global Integer supporterCount = 0;
    global Integer calloutCount = 0;
    global String[] enErrors = new String[]{};
    global Campaign cmpn;
    
    global MS_ContactSyncSendCRMSegmentToEN(Campaign cmpn) {
        settings = [SELECT Import_Endpoint__c, Token__c, CRM_Segment_Format_Name__c, Notification_Emails__c
            FROM EN_Dataservice_Settings__mdt
            WHERE DeveloperName = 'settings'];
        this.cmpn = cmpn;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id cmpnId = cmpn.Id;
        String query = 'SELECT Id, LeadId, ContactId, ' +
            'Lead.FirstName, Lead.LastName, Lead.Email, ' + 
            'Contact.FirstName, Contact.LastName, Contact.Email ' +
            'FROM CampaignMember ' +
            'WHERE CampaignId = :cmpnId';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<CampaignMember> campMems) {        
        String csvContent = buildRequest(campMems);
        Boolean success = sendRequest(csvContent);
        Set<Id> leadIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        List<Lead> leads;
        List<Contact> contacts;
        List<Lead> leadsToUpdate = new List<Lead>();
        List<Contact> contactsToUpdate = new List<Contact>();

        if (success) {
            for (CampaignMember cm : campMems) {
                if (!String.isBlank(cm.LeadId)) {
                    leadIds.add(cm.LeadId);
                }
                else if (!String.isBlank(cm.ContactId)) {
                    contactIds.add(cm.ContactId);
                }
            }
            leads = [SELECT Id FROM Lead WHERE Id IN :leadIds];
            contacts = [SELECT Id FROM Contact WHERE Id IN :contactIds];
            for (Lead l : leads) {
                l.EN_Push__c = true;
                leadsToUpdate.add(l);
            }
            for (Contact c : contacts) {
                c.engaging__EN_Last_Modified_Date__c = System.now();
                contactsToUpdate.add(c);
            }
            if (!leadsToUpdate.isEmpty()) {Database.update(leadsToUpdate, false);}
            if (!contactsToUpdate.isEmpty()) {Database.update(contactsToUpdate, false);}
        }
        else {
            failedBatches++;
        }
    }

    global String buildRequest(List<CampaignMember> campMems) {       
        String csvHeader = 'Email Address,Salesforce Type,First Name,Last Name,Lead Id,Contact Id from Account Sync';
        String csvContent = '';
        List<String> processed = new List<String>();
        for (CampaignMember cm : campMems) {
            if (!String.isBlank(cm.LeadId) && !String.isBlank(cm.Lead.Email) && !processed.contains(cm.Lead.Email)) {
                csvContent += '\r\n' + cm.Lead.Email + ',Lead,' + cm.Lead.FirstName + ',' + cm.Lead.LastName + ',' + cm.LeadId + ',[CLEAR]';
            	processed.add(cm.Lead.Email);
            }
            else if (!String.isBlank(cm.ContactId) && !String.isBlank(cm.Contact.Email) && !processed.contains(cm.Contact.Email)) {
                csvContent += '\r\n' + cm.Contact.Email + ',Contact,' + cm.Contact.FirstName + ',' + cm.Contact.LastName + ',[CLEAR],' + cm.ContactId;   
                processed.add(cm.Contact.Email);
            }   
            supporterCount++;
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
            + '\r\n\r\n' + 'CRMSegmentSync-' + reference
            + '\r\n--' + separator
            + '\r\nContent-Disposition: form-data; name="formatName";'
            + '\r\n\r\n' + settings.CRM_Segment_Format_Name__c
            + '\r\n--' + separator
            + '\r\nContent-Disposition: form-data; name="segmentId";'
            + '\r\n\r\n' + cmpn.Id
            + '\r\n--' + separator  
            + '\r\nContent-Disposition: form-data; name="segmentName";'
            + '\r\n\r\n' + cmpn.Name
            + '\r\n--' + separator              
            + '\r\nContent-Disposition: form-data; name="upload"; filename="CRMSegmentSync-' + reference + '.csv"'
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
        conVer.PathOnClient = 'CRMSegmentSync-' + reference + '.csv';
        conVer.Title = 'CRM Segment Sync Output Files ' + reference; // Display name of the files
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
                + '\n\nThe sync job pushing members of the campaign known as ' + cmpn.Name
                + ' into EN did not complete. Affected records will be '
                + 'reattempted during the next scheduled run.'
                + '\n\nThe following errors were returned from the Engaging Networks Import Service:\n';
            for (String msg : enErrors) {
                emailBody += '\n' + msg;
            }
            
            emailBody += '\n\nTotal Items: ' + supporterCount;

            String[] toAddresses = settings.Notification_Emails__c.split(',');        
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject('Salesforce could not push members of the ' + cmpn.Name + ' campaign into Engaging Networks');
            mail.setPlainTextBody(emailBody);
            if (!Test.isRunningTest()) {Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });}           
        }
        if (!Test.isRunningTest()) {Database.executeBatch(new MS_ContactSyncSendAccountsToEN());}
        if (!Test.isRunningTest()) {Database.executeBatch(new MS_ContactSyncSendLeadsToEN());}         
    }
}