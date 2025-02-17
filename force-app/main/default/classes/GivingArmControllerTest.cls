@isTest
public class GivingArmControllerTest {
    
    @isTest
    public static void testGivingArmController() {
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'RtR Standard User'];        
        
		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertToHex(b);
		String uid = h.SubString(0,8);        
		User runningUser = new User(
            Alias = uid,
            Email = uid + '@roomtoread.org', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Running', 
            LastName='User', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = prof.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName = uid + '@roomtoread.org'            
        );
		insert runningUser;        
        
        Account household = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household');
        insert household;
        
        household.Current_Relationship_Manager__c = runningUser.Id;
        household.Updated_Via_Apex_Trigger__c = true;
        update household;
        
        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = household.Id);
        insert c;
        
        Account famFoundation = new Account(
        Name = 'Suzie Q Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation',
        BillingCountry = 'United Kingdom');
        insert famFoundation;
        
        npe5__Affiliation__c affiliation = new npe5__Affiliation__c(
        npe5__Contact__c = c.Id,
        npe5__Organization__c = famFoundation.Id,
        Type__c = 'Giving Arm');
        insert affiliation;
        
        Opportunity o = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = famFoundation.Id,
        Amount = 10000,
        CurrencyIsoCode = 'GBP',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert o;

        Test.startTest();
        GivingArmController.getGivingArmDetails(household.Id);
        GivingArmController.getGivingArmHouseholdDetails(famFoundation.Id);
        Test.stopTest();
        
    }
    
    

}