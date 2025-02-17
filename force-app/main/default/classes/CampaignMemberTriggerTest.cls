@isTest
public class CampaignMemberTriggerTest {
    
    @isTest
    public static void testCampaignMemberTrigger(){
		
        Campaign chapterEvt = new Campaign(
        RecordTypeId = '0128b000000XLosAAG',
        Name = 'Hong Kong - Changemakers Lunch',
        StartDate = Date.newInstance(2023, 3, 21),
        Type = 'Chapter Event',
        Lead_Sub_Source__c = '2023 HK Changemakers Lunch');
        insert chapterEvt;
        
        Lead l = new Lead(
        FirstName = 'Suzy',
        LastName = 'Q',
        Company = 'Suzy Q Household',
        Email = 'suzy.q@test.com',
        LeadSource = '',
        Lead_Sub_Source__c = '');
		insert l;
        
        Test.startTest();
        CampaignMember cm = new CampaignMember(
        LeadId = l.Id,
        CampaignId = chapterEvt.Id,
        Status = 'Registered');
        insert cm;
        Test.stopTest();
        
        System.assertEquals('2023 HK Changemakers Lunch', [SELECT Id, Lead_Sub_Source__c FROM Lead WHERE Id = :l.Id][0].Lead_Sub_Source__c);
		
    }

}