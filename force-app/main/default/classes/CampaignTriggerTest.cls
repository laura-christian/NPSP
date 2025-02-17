@isTest
public class CampaignTriggerTest {

    public static Id evtRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Event').getRecordTypeId();
    public static Id fundraisingRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Fundraising').getRecordTypeId();
    public static Id trekRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Stakeholder Engagement').getRecordTypeId();
    public static Id p2pRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Peer to Peer').getRecordTypeId();
    
    @isTest
    public static void testCampaignMemberStatusCreation() {
        
        Campaign evt = new Campaign(
        Name = 'Event',
        RecordTypeId = evtRecordTypeId,
        StartDate = System.today()+30,
        IsActive = true);
        insert evt;
        
    }
    
    @isTest
    public static void testLeadSubSourceUpdate() {
        
        Campaign evt = new Campaign(
        Name = 'International Women\'s Day Leadership Discussion',
        RecordTypeId = evtRecordTypeId,
        Type = 'Virtual Event',
        StartDate = System.today()+30,
        IsActive = true);
        insert evt;

		Lead lead = new Lead(
        FirstName = 'Suzie',
        LastName = 'Queue',
        Company = 'Suzie Queue Household',
        Email = 'suzie.q@email.com',
        LeadSource = 'Virtual Event');
		insert lead;

		CampaignMember cm = new CampaignMember(
        LeadId = lead.Id,
        CampaignId = evt.Id,
        Status = 'Registered');
        insert cm;
        
        evt.Lead_Sub_Source__c = '2021 International Womens Day Leadership Discussion';
        update evt;
        
        System.assertEquals('2021 International Womens Day Leadership Discussion', [SELECT Id, Lead_Sub_Source__c FROM Lead WHERE Id = :lead.Id][0].Lead_Sub_Source__c);
        
    }
    
}