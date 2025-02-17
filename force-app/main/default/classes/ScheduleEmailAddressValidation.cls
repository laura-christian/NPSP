public class ScheduleEmailAddressValidation Implements Schedulable {

    public void execute(SchedulableContext sc) {
        
        List<Lead> leads = [SELECT Id, Name, Email FROM Lead WHERE Email != null AND (Email_ZeroBounce_Status__c = null OR Email_ZeroBounce_Substatus__c = 'possible_typo') AND EN_Salesforce_Opt_In_Status__c = 'Y' AND (LeadSource != 'Raisers Edge' OR (LeadSource = 'Raisers Edge' AND GDPR_Consent_Date__c != null))];
        List<Contact> contacts = [SELECT Id, Name, Email FROM Contact WHERE Email != null AND (Email_ZeroBounce_Status__c = null OR Email_ZeroBounce_Substatus__c = 'possible_typo') AND EN_Salesforce_Opt_In_Status__c = 'Y'];
        Set<String> emailAddresses = new Set<String>();
        Integer i;
        if (!leads.isEmpty()) {
            for (i=0; i<leads.size() && emailAddresses.size()<250; i++) {
                emailAddresses.add(leads[i].Email);
            }
        }
        if (!contacts.isEmpty()) {
            for (i=0; i<contacts.size() && emailAddresses.size()<250; i++) {
                emailAddresses.add(contacts[i].Email);
            }
        }
        if (!emailAddresses.isEmpty()) {
            List<String> emailAddressesList = new List<String>();
            emailAddressesList.addAll(emailAddresses);
            if (!Test.isRunningTest()) {Database.executeBatch(new BatchValidateEmails(emailAddressesList), 50);}
        }
		
    }
    
    
}