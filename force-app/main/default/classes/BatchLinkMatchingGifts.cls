public class BatchLinkMatchingGifts implements Database.Batchable<AggregateResult> {

    @InvocableMethod
    public static void linkMatchingGifts() {
        Id jobId = Database.executeBatch(new BatchLinkMatchingGifts());
    }    
    
    public AggregateResult[] start(Database.BatchableContext bc) {
		return [SELECT Count(Id), Benevity_Transaction_Id__c  
				FROM Opportunity
				WHERE Benevity_Transaction_Id__c != null AND npsp__Matching_Gift__c = null	
                GROUP BY Benevity_Transaction_Id__c
                HAVING Count(Id) = 2];
    }    


    public void execute(Database.BatchableContext bc, List<AggregateResult> scope) {
		Set<String> benevityTxnIds = new Set<String>();
        for (AggregateResult aggRes : scope) {
            benevityTxnIds.add((String)aggRes.get('Benevity_Transaction_Id__c'));
        }
        List<Opportunity> opps = [SELECT Id, Name, RecordType.Name, AccountId, Account.Name, Account.RecordType.Name, Benevity_Transaction_Id__c
                                  FROM Opportunity
                                  WHERE Benevity_Transaction_Id__c IN :benevityTxnIds
                                  ORDER BY Benevity_Transaction_Id__c, Account.RecordType.Name];
        Map<String, List<Opportunity>> benevityTxnIdToOpps = new Map<String, List<Opportunity>>();
        for (Opportunity o : opps) {
            if (!benevityTxnIdToOpps.containsKey(o.Benevity_Transaction_Id__c)) {
                benevityTxnIdToOpps.put(o.Benevity_Transaction_Id__c, new List<Opportunity>{o});
            }
            else {benevityTxnIdToOpps.get(o.Benevity_Transaction_Id__c).add(o);}
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (String benevityTxnId : benevityTxnIdToOpps.keySet()) {
            Opportunity employeeGift = benevityTxnIdToOpps.get(benevityTxnId)[0];
            Opportunity employerMatch = benevityTxnIdToOpps.get(benevityTxnId)[1];
            if (employeeGift.Account.RecordType.Name == 'Household Account' && employerMatch.Account.RecordType.Name == 'Organization') {
                employeeGift.npsp__Matching_Gift__c = employerMatch.Id;
                employeeGift.npsp__Matching_Gift_Account__c = employerMatch.AccountId;
                employeeGift.npsp__Matching_Gift_Employer__c = employerMatch.Account.Name;
                employeeGift.npsp__Matching_Gift_Status__c = 'Received';
                oppsToUpdate.add(employeeGift);
                /*if (employerMatch.RecordType.Name == 'Donation') {
                    employerMatch.RecordTypeId = '0128b000000XLoq';
                    employerMatch.Name = employerMatch.Name.replaceAll('Donation', 'Matching Gift');
                    oppsToUpdate.add(employerMatch);
                }*/
            }
        }
        Database.saveResult[] saveResults = Database.update(oppsToUpdate, false);
        for (Integer i=0;i<saveResults.size();i++) {
            if (saveResults.get(i).isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully linked employee gift to employer match. Employee gift Id: ' + saveResults.get(i).getId());
            }
            else {
                System.debug('The following error has occurred:');                    
                Database.Error error = saveResults.get(i).getErrors().get(0);
                System.debug(error.getMessage());
                System.debug('Id of record that failed to update: ' + oppsToUpdate[i].Id);
            }
        }
    }
    
  	public void finish(Database.BatchableContext bc) {
        /*List<Opportunity> matchingOppsNoMatch = [SELECT Id, Name FROM Opportunity WHERE Benevity_Transaction_Id__c != null AND Account.RecordType.Name = 'Organization' AND RecordType.Name != 'Matching Gift'];
        for (Opportunity o : matchingOppsNoMatch) {
            o.RecordTypeId = '0128b000000XLoq';
            o.Name = o.Name.replaceAll('Donation', 'Matching Gift');
        }
        if (!matchingOppsNoMatch.isEmpty()) {Database.update(matchingOppsNoMatch, false);*/
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job: ' + job.Status);
    }    
    
}