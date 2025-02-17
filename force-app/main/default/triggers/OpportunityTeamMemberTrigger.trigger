trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (after delete) {

    List<User> rtr = [SELECT Id FROM User WHERE Name = 'Room to Read'];
    
    Set<Id> oppIds = new Set<Id>();
    for (OpportunityTeamMember OTM : Trigger.old) {
        oppIds.add(OTM.OpportunityId);
    }
    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id IN :oppIds AND Id NOT IN (SELECT OpportunityId FROM OpportunityTeamMember WHERE TeamMemberRole = 'Relationship Manager')];
    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    if (!rtr.isEmpty()) {
        for (Opportunity o : opps) {
            o.Updated_Via_Trigger__c = true;
            o.OwnerId = rtr[0].Id;
            oppsToUpdate.add(o);
        }
    }
    Database.update(oppsToUpdate, false);
    
}