@isTest
public class RHX_TEST_AccountTeamMember {
 
    static testMethod void RHX_Testmethod() {
     
     	Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User rtrUser = new User(
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
     	insert rtrUser;
     
		Account a = new Account(
        Name = 'Test Foundation',
        Type = 'Foundation',
        Count_of_Acct_Team_Members__c = 0);
        insert a;
     
        AccountTeamMember teamMember = new AccountTeamMember(
        	AccountId = a.Id,
            UserId = rtrUser.Id,
            TeamMemberRole = 'Team Member',
            Start_Date__c = System.today()-7,
            End_Date__c = null
        );
		insert teamMember;     
     
     	List<sObject> sourceList = new List<sObject>{teamMember};
            
       	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}