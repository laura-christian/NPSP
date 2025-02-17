@isTest
public class DuplicateRecordItemTriggerTest {

    public static final Id dupeLeadRuleId = 
        [SELECT Id 
		 FROM DuplicateRule 
		 WHERE MasterLabel = 'Standard Rule for New Leads with Duplicate Leads'][0].Id;
    
    public static final Id contactDupeLeadRuleId = 
          [SELECT Id 
		   FROM DuplicateRule 
		   WHERE MasterLabel = 'Standard Rule for New Contacts with Duplicate Leads'][0].Id;

    public static final Id leadMatchOnContactEmailOnly = 
		[SELECT Id 
		 FROM DuplicateRule 
		 WHERE MasterLabel = 'Rule for New Leads Having Contacts with Matching Email (Only)'][0].Id;

    public static final Id dupeContactRuleId = 
          [SELECT Id 
		   FROM DuplicateRule 
		   WHERE MasterLabel = 'Standard Rule for New Contacts with Duplicate Contacts'][0].Id;    
    
    public static final Id contactWithLeadHavingMatchingEmailOnly = 
		[SELECT Id 
		 FROM DuplicateRule 
		 WHERE MasterLabel = 'Rule for New Contacts Having Leads with Matching Email (Only)'][0].Id;
 
    @isTest
    public static void testDedupeLeads() {

        Lead lead = new Lead(
        FirstName = 'Jane',
        LastName = 'Maiden-Name',
        Company = 'Jane Maiden-Name Household', 
        Street = '123 Main Street',
        City = 'Anywhere',
        State = 'CA',
        PostalCode = '99999',
        Country = 'United States',
        Newsletter__c = false,
        Book_Club__c = false,
        She_Creates_Change__c = false,
        Do_Not_Solicit__c = true,
		Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today()-14,
        HasOptedOutOfEmail = true,
        GDPR_Decline_Date__c = System.today()-7,
        Forms_Filled_Out__c = 'Book Club Sign Up Form;Hindi Storybook Collection Download',
        SMS_Opt_In__c = true,
        SMS_Consent_Date__c = System.today()-28,
        MobilePhone = '+19999999999');
        insert lead;
        
        Lead dupeLead = new Lead(
        FirstName = 'Jane',
        LastName = 'Married-Name',
        Company = 'Jane Married-Name Household',
        Email = 'testemail@test.com',
        Description = 'Jane Married-Name is CEO of Acme Corporation',
        Description_Last_Updated__c = System.today(),
        Newsletter__c = true,
        Book_Club__c = true,
        She_Creates_Change__c = true,
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        SMS_Opt_In__c = false,
        SMS_Consent_Date__c = null,
        SMS_Decline_Date__c = null,
        Forms_Filled_Out__c = 'Book Club Sign Up Form');
        insert dupeLead;

        Campaign camp = new Campaign(
        Name = 'In Class with Room to Read',
        Status = 'Active',
        StartDate = System.today()+21,
        EndDate = System.today()+21);
        insert camp;
        
        CampaignMember cm = new CampaignMember(
        CampaignId = camp.Id,
        LeadId = dupeLead.Id,
        Status = 'Responded');
        insert cm;

        DuplicateRecordSet drs = new DuplicateRecordSet(
        DuplicateRuleId = dupeLeadRuleId);
        insert drs;
        
        DuplicateRecordItem firstLead = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = lead.Id);
        DuplicateRecordItem duplicateLead = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = dupeLead.Id);
        List<DuplicateRecordItem> driList = new List<DuplicateRecordItem>{firstLead, duplicateLead};
        insert driList;
        
    }
    
    @isTest
    public static void testLeadConversionAutomation()  {
        
        Lead lead = new Lead(
        FirstName = 'Suzie',
        LastName = 'Q',
        Company = 'Suzie Q Household',
        Email = 'testemail@test.com',
        Description = 'Suzie Q is Vice President of Acme Corporation',
        Description_Last_Updated__c = System.today(),
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
		Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        SMS_Opt_In__c = true,
        SMS_Consent_Date__c = System.today(),
        SMS_Decline_Date__c = null,
        Forms_Filled_Out__c = 'Hindi Storybook Collection Download');
		insert con;

        DuplicateRecordSet drs = new DuplicateRecordSet(
        DuplicateRuleId = contactDupeLeadRuleId);
        insert drs;
        
        DuplicateRecordItem leadDRI = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = lead.Id);
        DuplicateRecordItem dupeContact = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = con.Id);
        List<DuplicateRecordItem> driList = new List<DuplicateRecordItem>{leadDRI, dupeContact};
        insert driList;  
    }
    
    @isTest
    public static void testDupeLeadExistingContact() {

        Contact con = new Contact(
        FirstName = 'Susanne',
        LastName = 'Q',
        npe01__Preferred_Email__c = 'Personal',
        npe01__HomeEmail__c = 'suzie_q@test.com',
		Newsletter__c = true,
        Book_Club__c = false,
        She_Creates_Change__c = false,
		Email_Opted_In__c = false,
        GDPR_Consent_Date__c = null,
        Forms_Filled_Out__c = 'Hindi Storybook Collection Download');
		insert con;        
        
        Lead lead = new Lead(
        FirstName = 'Susanne',
        LastName = 'Married-Name',
        Company = 'Susanne Married-Name Household',
        Email = 'suzie_q@test.com',            
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today(),
        LeadSource = 'Website',
        Lead_Sub_Source__c = 'International Literacy Day Childrens Book List Download',
        Newsletter__c = true,
        Book_Club__c = false,
        She_Creates_Change__c = true,
        Forms_Filled_Out__c = 'International Literacy Day Childrens Book List Download;She Creates Change Email Sign Up Form');
        insert lead;

        DuplicateRecordSet drs = new DuplicateRecordSet(
        DuplicateRuleId = leadMatchOnContactEmailOnly);
        insert drs;
        
        DuplicateRecordItem leadDRI = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = lead.Id);
        DuplicateRecordItem dupeContact = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = con.Id);
        List<DuplicateRecordItem> driList = new List<DuplicateRecordItem>{leadDRI, dupeContact};
        insert driList; 
        
    }
    
    @isTest
    public static void testMarkDupeContactsForReview() {
        
        Contact con1 = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        Email = 'suzie@me.com');
        insert con1;
        
        Contact con2 = new Contact(
        FirstName = 'Susanna',
        LastName = 'Q',
        Email = 'suzie@me.com');
        insert con2;
        
        DuplicateRecordSet drs = new DuplicateRecordSet(
        DuplicateRuleId = dupeContactRuleId);
        insert drs;
        
        DuplicateRecordItem contact = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = con1.Id);
        DuplicateRecordItem dupeContact = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = con2.Id);
        List<DuplicateRecordItem> driList = new List<DuplicateRecordItem>{contact, dupeContact};
        
        Test.startTest();  
        insert driList;  
        delete [SELECT Id FROM DuplicateRecordItem WHERE Id = :dupeContact.Id];
        Test.stopTest();
        
    }
    
    @isTest
    public static void testContactMatchingEmailOnly() {
        
        Lead lead = new Lead(
        FirstName = 'Hubby',
        LastName = 'Q',
        Company = 'Hubby Q Household',
        Email = 'the_qs@testemail.com',            
        Email_Opted_In__c = true,
        GDPR_Consent_Date__c = System.today()-30,
        LeadSource = 'Website',
        Lead_Sub_Source__c = 'International Literacy Day Childrens Book List Download',
        Newsletter__c = true,
        Book_Club__c = false,
        She_Creates_Change__c = true,
        Forms_Filled_Out__c = 'International Literacy Day Childrens Book List Download;She Creates Change Email Sign Up Form');
        insert lead;        

        Contact con = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        npe01__Preferred_Email__c = 'Personal',
        npe01__HomeEmail__c = 'the_qs@testemail.com',
		Newsletter__c = true,
        Book_Club__c = false,
        She_Creates_Change__c = false,
		Email_Opted_In__c = false,
        GDPR_Consent_Date__c = null);
		insert con;        

        DuplicateRecordSet drs = new DuplicateRecordSet(
        DuplicateRuleId = contactWithLeadHavingMatchingEmailOnly);
        insert drs;
        
        DuplicateRecordItem leadDRI = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = lead.Id);
        DuplicateRecordItem dupeContact = new DuplicateRecordItem(
        DuplicateRecordSetId = drs.Id,
        RecordId = con.Id);
        List<DuplicateRecordItem> driList = new List<DuplicateRecordItem>{leadDRI, dupeContact};
        insert driList; 
    }
    
}