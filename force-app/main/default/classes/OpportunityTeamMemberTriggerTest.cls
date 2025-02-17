@isTest
public class OpportunityTeamMemberTriggerTest {

    @isTest(SeeAllData=true)
    public static void testAfterOTMDelete() {
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertToHex(b);
		String uid = h.SubString(0,8);        
		User rm = new User(
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
		insert rm;

        Account a = new Account(
        Name = 'Test Foundation',
		RecordTypeId = '0128b000000XLonAAG',            
        Type = 'Foundation',
        BillingCountry = 'United Kingdom');
        insert a;		        
        
        Opportunity o = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = a.Id,
        Amount = 100,
        CurrencyIsoCode = 'GBP',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert o;
        
        OpportunityTeamMember otm = new OpportunityTeamMember(
        OpportunityId = o.Id,
        UserId = rm.Id,
        TeamMemberRole = 'Relationship Manager');
        insert otm;
        
        Test.startTest();
        delete otm;
        Test.stopTest();
        
        System.assert([SELECT Id, OwnerId FROM Opportunity WHERE Id = :o.Id][0].OwnerId == '0058b00000Gl4U9');
        
    }
    
}