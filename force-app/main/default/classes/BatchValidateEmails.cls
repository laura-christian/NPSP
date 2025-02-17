public class BatchValidateEmails Implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    public List<String> emailAddresses = new List<String>();
    public Set<String> suggestedFixesToCheck = new Set<String>();

    public BatchValidateEmails(List<String> emailAddresses) {
        this.emailAddresses = emailAddresses;
    }
    
	public List<String> start(Database.BatchableContext bc) {
    	System.debug('>>>> Init batch validation of email addresses');
        return emailAddresses;
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
		
        String endpoint = 'https://bulkapi.zerobounce.net/v2/validatebatch';
        String payload = '{' +
            '"api_key":"45f8651eb44a4520b3ad4d6b86f19a78",' +
            '"email_batch":[';
        
        List<String> emailBatchObjects = new List<String>();
        for (String emailAddress : scope) {
            emailBatchObjects.add('{"email_address":"' + emailAddress + '","ip_address":null}');
        }
        payload += String.join(emailBatchObjects, ',');
        payload += ']}';
		System.debug(payload);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json'); 
        request.setMethod('POST');        
        request.setEndpoint(endpoint);
        request.setBody(payload);
        request.setTimeout(75000);
        
        HttpResponse response = http.send(request);
        Map<String, Map<String, String>> emailValidationResults = new Map<String, Map<String, String>>();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            System.debug('HTTP request was successful');
            String jsonResponse = response.getBody(); 
            Map<String, Object> mappedJSON = (Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
            List<Object> emailBatch = (List<Object>)mappedJSON.get('email_batch');
            if (!emailBatch.isEmpty()) {
                for (Object o : emailBatch) {
                    Map<String, Object> individualEmailResults = (Map<String, Object>)o;
                    String email = (String)individualEmailResults.get('address');
                    System.debug('Email for which results are being parsed: ' + email);
                    Map<String, String> emailStatus = new Map<String, String>{
                        'address' => email,
                        'status' => (String)individualEmailResults.get('status'),
                        'sub_status' => (String)individualEmailResults.get('sub_status'),
                        'gender' => (String)individualEmailResults.get('gender'),
                        'did_you_mean' => (String)individualEmailResults.get('did_you_mean')
                    };
					emailValidationResults.put(email, emailStatus);
                }
            }
        }
        
        List<String> allValidatedEmails = new List<String>();
        allValidatedEmails.addAll(emailValidationResults.keySet());
        String query = String.join(allValidatedEmails, ' OR ');
        System.debug(query);
        if (query.length() > 0) {        
            List<List<sObject>> emailSearch = [FIND :query IN EMAIL FIELDS
                                               RETURNING Lead(Id,Email),Contact(Id,Email,npe01__HomeEmail__c,npe01__WorkEmail__c,npe01__AlternateEmail__c)];
            Lead[] leadsReturned = (Lead[])emailSearch[0];
            System.debug('Number of leads returned: ' + leadsReturned.size());
            Contact[] contactsReturned = (Contact[])emailSearch[1];
            System.debug('Number of contacts returned: ' + contactsReturned.size());
            
            List<Lead> leadsToUpdate = new List<Lead>();
            List<Contact> contactsToUpdate = new List<Contact>();
    
            for (Lead l : leadsReturned) {
                if (emailValidationResults.containsKey(l.Email)) {
                    System.debug('SOSL query returned the lead with Id ' + l.Id + ' and the email address ' + l.Email);
                    String status = (String)emailValidationResults.get(l.Email).get('status');
                    System.debug('The status of the lead\'s email address is: ' + status);
                    if (status == 'valid') {
                        l.Validated_Email__c = l.Email;
                        l.Email_ZeroBounce_Status__c = 'valid';
                        l.Email_ZeroBounce_Substatus__c = '';
                        if (!String.isBlank((String)emailValidationResults.get(l.Email).get('gender'))) {
                            l.Gender__c = DataQualityUtilities.capitalizeFirstLetter((String)emailValidationResults.get(l.Email).get('gender'));
                        }                        
                    }
                    else {
                        l.Rejected_Email__c = l.Email;
                        l.Email_ZeroBounce_Status__c = status;
                        l.Email_ZeroBounce_Substatus__c = (String)emailValidationResults.get(l.Email).get('sub_status');
                        if ((String)emailValidationResults.get(l.Email).get('did_you_mean') != null) {
                            l.Email = (String)emailValidationResults.get(l.Email).get('did_you_mean');
                            suggestedFixesToCheck.add(l.Email);
                        }                    
                    }
                    leadsToUpdate.add(l);
                }
            }
            for (Contact c : contactsReturned) {
                if (emailValidationResults.containsKey(c.Email)) {
                    System.debug('SOSL query returned the contact with Id ' + c.Id + ' and the email address ' + c.Email);
                    String status = (String)emailValidationResults.get(c.Email).get('status');
                    System.debug('The status of the contact\'s email address is: ' + status);
                    if (status == 'valid') {
                        c.Validated_Email__c = c.Email;
                        c.Email_ZeroBounce_Status__c = 'valid';
                        c.Email_ZeroBounce_Substatus__c = '';
						if (!String.isBlank((String)emailValidationResults.get(c.Email).get('gender'))) {
                            c.Gender__c = DataQualityUtilities.capitalizeFirstLetter((String)emailValidationResults.get(c.Email).get('gender'));
                        }                        
                    }
                    else {
                        c.Rejected_Email__c = c.Email;
                        c.Email_ZeroBounce_Status__c = status;
                        c.Email_ZeroBounce_Substatus__c = (String)emailValidationResults.get(c.Email).get('sub_status');
                        if (emailValidationResults.get(c.Email).get('did_you_mean') != null) {
                            String suggestedFix = (String)emailValidationResults.get(c.Email).get('did_you_mean');
                            if (c.npe01__HomeEmail__c == c.Email) {c.npe01__HomeEmail__c = suggestedFix;}
                            else if (c.npe01__WorkEmail__c == c.Email) {c.npe01__WorkEmail__c = suggestedFix;}
                            else if (c.npe01__AlternateEmail__c == c.Email) {c.npe01__AlternateEmail__c = suggestedFix;}
                            suggestedFixesToCheck.add(suggestedFix);
                        }
                    }
                    contactsToUpdate.add(c);
                }                
            }
            if (!leadsToUpdate.isEmpty()) {Database.update(leadsToUpdate, false);}
            if (!contactsToUpdate.isEmpty()) {Database.update(contactsToUpdate, false);}
        }

    }
	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job verifying addresses: ' + job.Status);
        // Reason the second email validation is scheduled for five minutes from the completion of the first job
        // is that during testing, the second API call was happening so fast, DML operations did not have a chance
        // to finish before new results were returned, and updated records could not be found as they were still
        // being processed. The five-minute delay should be adequate for allowing the results of the first round 
        // of validations to be committed to the database before the second API call is made.
        if (!suggestedFixesToCheck.isEmpty()) {
        	List<String> suggestedFixesList = new List<String>();
            suggestedFixesList.addAll(suggestedFixesToCheck);
            Datetime now = Datetime.now();
            Datetime fiveMinutesFromNow = now.addMinutes(5);
            String hour = String.valueOf(fiveMinutesFromNow.hour());
            String min = String.valueOf(fiveMinutesFromNow.minute()); 
            String ss = String.valueOf(fiveMinutesFromNow.second());
            // Concatenate strings to cron expression
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
            if (!Test.isRunningTest()) {System.schedule('Scheduled Job ' + String.valueOf(Math.random()), nextFireTime, new ScheduleSecondEmailAddressValidation(suggestedFixesList));}
        }
    }
    
}