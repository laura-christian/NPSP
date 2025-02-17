public class BatchAssignTerritoriesToOpps implements Database.Batchable<sObject> {

    
    public Database.QueryLocator start(Database.BatchableContext bc) {
		String query = 'SELECT Id, Name, AccountId, IsExcludedFromTerritory2Filter ' + 
            		   'FROM Opportunity WHERE Territory2Id = null';  
        return Database.getQueryLocator(query);
    }    


    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
		Set<Id> acctIds = new Set<Id>();
        for (Opportunity o : scope) {
            acctIds.add(o.AccountId);
        }
        List<ObjectTerritory2Association> territoryAssignments = [SELECT Id, ObjectId, Territory2Id, Territory2.Name
                                                                  FROM ObjectTerritory2Association
                                                                  WHERE ObjectId IN :acctIds];
        Map<Id, ObjectTerritory2Association> acctIdToOT2AMap = new Map<Id, ObjectTerritory2Association>();
        for (ObjectTerritory2Association OT2A : territoryAssignments) {
            acctIdToOT2AMap.put(OT2A.ObjectId, OT2A);
        }
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Opportunity o : scope) {
            if (acctIdToOT2AMap.containsKey(o.AccountId)) {
                o.Territory2Id = acctIdToOT2AMap.get(o.AccountId).Territory2Id;
                opportunitiesToUpdate.add(o);
            }
        }
        if (!opportunitiesToUpdate.isEmpty()) {Database.update(opportunitiesToUpdate, false);}
        

    }
    
  	public void finish(Database.BatchableContext bc) { 
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job: ' + job.Status);
    }    
    
}