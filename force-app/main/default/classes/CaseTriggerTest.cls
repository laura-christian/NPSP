@isTest
public class CaseTriggerTest {

    @isTest
    public static void testCaseTrigger() {
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		
		User caseOwner1 = new User(
			Alias = 'rtrUser', 
            Email='generic.rtr.user@roomtoread.org', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Room to', 
            LastName='Read', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = prof.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='generic.rtr.user@roomtoread.org'       
        );

		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertToHex(b);
		String uid = h.SubString(0,8);        
		User caseOwner2 = new User(
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

        List<User> users = new List<User>{caseOwner1, caseOwner2};
        insert users;        
        
        Test.startTest();
        
        Case c = new Case(
        Subject = 'This is a test',
        OwnerId = caseOwner1.Id,
        Status = 'New',
        Origin = 'Email',
        Priority = 'Medium',
        Due_Date__c = System.today()+30);
        insert c;
        
        c.OwnerId = caseOwner2.Id;
        update c;
        
        Test.stopTest();
        
        System.assertEquals([SELECT Id FROM CaseTeamMember WHERE ParentId = :c.Id].size(), 1);
        
        
        
    }
    
}