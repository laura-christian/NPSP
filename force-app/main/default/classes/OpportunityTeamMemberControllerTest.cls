@isTest
public class OpportunityTeamMemberControllerTest {
    
    @isTest
    public static void testGetOTMMethod() {
        
        Opportunity o = new Opportunity(
        RecordTypeId = '0128b000000XLokAAG',
        Name = 'Major Gift',
        Amount = 10000,
        CurrencyIsoCode = 'GBP',
        CloseDate = Date.newInstance(System.today().year(), 12, 31),
        StageName = 'Cultivation/Ask Prep');
        insert o;
        
		Profile prof = [SELECT Id FROM Profile WHERE Name = 'RtR Standard User'];        
        
		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertToHex(b);
		String uid = h.SubString(0,8);        
		User relationshipManager = new User(
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
		insert relationshipManager;        
        
        OpportunityTeamMemberController.insertOppTeamMember(o.Id, relationshipManager.Id, 'Relationship Manager');
        
        List<OpportunityTeamMember> oppTeamMembers = OpportunityTeamMemberController.getOppTeamMembers(o.Id);
        
        System.assertEquals(1, oppTeamMembers.size());
        
    }

}