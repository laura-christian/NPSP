@isTest
public class ConvertLeadControllerTest {
    
    @isTest
    public static void testCreateNewContactPlusAffiliation() {
        
		Lead lead = new Lead(
        FirstName = 'Suzie',
        LastName = 'Q',
        Company = 'Suzie Q Household',
        Email = 'testemail@test.com',
        Street = '123 Main Street',
        City = 'Anytown',
        State = 'CA',
        PostalCode = '99999',    
        Country = 'United States',            
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today()-7,
        LeadSource = 'Website',
        Lead_Sub_Source__c = 'Book Club Sign Up Form',
        Newsletter__c = true,
        Book_Club__c = true,
        She_Creates_Change__c = true,
        Do_Not_Solicit__c = true,
        Volunteer__c = true,
        Forms_Filled_Out__c = 'Book Club Sign Up Form;International Literacy Day Childrens Book List Download;International Literacy Day Global Book Collection Download');
        insert lead;
        
        Account organization = new Account(
        Name = 'Suzie Q Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United States');
        insert organization;        

		Test.startTest();
		ConvertLeadController.convertLead(lead.Id, '', '', organization.Id, 'Giving Arm', true);
		Test.stopTest();

		System.assert([SELECT Id FROM Contact].size()==1);        
        
    }
    
    @isTest
    public static void testMergeIntoExistingContact() {
        
        Lead lead = new Lead(
        FirstName = 'Suzie',
        LastName = 'Q',
        Company = 'Suzie Q Household',
        Description = 'Suzie Q is the President and CEO of Acme Corp.',
        Email = 'testemail@test.com',
        Street = '123 Main Street',
        City = 'Anytown',
        State = 'CA',
        PostalCode = '99999',    
        Country = 'United States',            
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today()-7,
        LeadSource = 'Website',
        Lead_Sub_Source__c = 'Book Club Sign Up Form',
        Newsletter__c = true,
        Book_Club__c = true,
        She_Creates_Change__c = true,
        Do_Not_Solicit__c = true,
        SMS_Opt_In__c = false,
        SMS_Consent_Date__c = System.today()-365,
        SMS_Decline_Date__c = System.today(),
        Volunteer__c = false,
        Forms_Filled_Out__c = 'Book Club Sign Up Form;International Literacy Day Childrens Book List Download;International Literacy Day Global Book Collection Download');
        insert lead;

        Campaign camp = new Campaign(
        Name = 'In Class with Room to Read',
        Status = 'Active',
        StartDate = System.today()+21,
        EndDate = System.today()+21);
        insert camp;
        
        CampaignMember cm = new CampaignMember(
        CampaignId = camp.Id,
        LeadId = lead.Id,
        Status = 'Responded');
        insert cm;        

        Contact con = new Contact(
        FirstName = 'Susanne',
        LastName = 'Q',
        npe01__Preferred_Email__c = 'Personal',
        npe01__HomeEmail__c = 'testemail@test.com',
		Newsletter__c = true,
        Book_Club__c = false,
        She_Creates_Change__c = false,
		Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        SMS_Opt_In__c = true,
        Volunteer__c = true,
        SMS_Consent_Date__c = System.today()-14,
        Forms_Filled_Out__c = 'Hindi Storybook Collection Download');
		insert con; 
        
		Test.startTest();
		ConvertLeadController.convertLead(lead.Id, con.Id, '', '', '', false);
		Test.stopTest();

		System.assert([SELECT Id, Forms_Filled_Out__c FROM Contact WHERE Forms_Filled_Out__c INCLUDES ('International Literacy Day Global Book Collection Download')].size()==1);        
        
    }

}