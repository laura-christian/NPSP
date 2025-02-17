@isTest
public class OppTerrAssignDefaultLogicFilterTest {
    
    @isTest
    public static void testOppTerr2AssignmentFilter() {
        
        Account a = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household',
        BillingCountry = 'Australia',
        CurrencyIsoCode = 'AUD');
        insert a;
        
        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = a.Id);
        insert c;

        Opportunity o = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = a.Id,
        Amount = 100,
        CurrencyIsoCode = 'AUD',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert o; 
    	
		OppTerrAssignDefaultLogicFilter filter = new OppTerrAssignDefaultLogicFilter();
		Id activeModelId = filter.getActiveModelId();        
        
		List<Territory2> terr2 = [SELECT Id, Territory2TypeId, Territory2ModelId FROM Territory2 WHERE Name = 'Australia'];

        ObjectTerritory2Association objTerr2Association = new ObjectTerritory2Association(
        ObjectId = a.Id,
        Territory2Id=terr2[0].Id,
        AssociationCause='Territory2Manual');
        insert objTerr2Association;
        
        Test.startTest();
        
        filter.getOpportunityTerritory2Assignments(new List<Id>{o.Id});
        Map<Id, Id> resultMap = filter.getOpportunityTerritory2Assignments(new List<Id>{o.Id});
        filter.getAccountMaxPriorityTerritory(activeModelId, new Set<Id>{a.Id});
        
        Test.stopTest(); 
    }
    
    @isTest
    public static void testBatchAssignTerritoriesToOpps() {
        
        Account a = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household',
        BillingCountry = 'Australia',
        CurrencyIsoCode = 'AUD');
        insert a;
        
        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = a.Id);
        insert c;

        Opportunity o = new Opportunity(
        Name = 'Donation',
        RecordTypeId = '0128b000000XLooAAG',
        AccountId = a.Id,
        Amount = 100,
        CurrencyIsoCode = 'AUD',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert o; 
    	
		OppTerrAssignDefaultLogicFilter filter = new OppTerrAssignDefaultLogicFilter();
		Id activeModelId = filter.getActiveModelId();        
        
		List<Territory2> terr2 = [SELECT Id, Territory2TypeId, Territory2ModelId FROM Territory2 WHERE Name = 'Australia'];

        ObjectTerritory2Association objTerr2Association = new ObjectTerritory2Association(
        ObjectId = a.Id,
        Territory2Id=terr2[0].Id,
        AssociationCause='Territory2Manual');
        insert objTerr2Association;
        
        Test.startTest();
        
		Database.executeBatch(new BatchAssignTerritoriesToOpps(), 100);
        
        Test.stopTest(); 
    } 
    
    @isTest
    public static void testScheduleOppTerrAssignment() {
		String jobId = System.schedule('Scheduled Job', '0 45 * * * ?', new ScheduleOppTerrAssignment());
    }    
        
        
}