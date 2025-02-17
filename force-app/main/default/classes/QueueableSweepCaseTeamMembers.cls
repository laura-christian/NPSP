public class QueueableSweepCaseTeamMembers implements Queueable {

    List<Case> cases;
    
    public QueueableSweepCaseTeamMembers(List<Case> cases) {
        this.cases = cases;
    }
    
    public void execute(QueueableContext context) {
        
        // Organize cases into map
    	Map<Id, Case> casesMap = new Map<Id, Case>();
        for (Case c : cases) {
            casesMap.put(c.Id, c);
        }
        List<CaseTeamMember> teamMembersToDelete = new List<CaseTeamMember>();
        // Query all case team members associated with cases in map
        List<CaseTeamMember> caseTeamMembers = [SELECT Id, ParentId, MemberId, TeamRole.Name
                                                FROM CaseTeamMember
                                                WHERE ParentId IN :casesMap.keySet()];
        // Loop over CTMs; check to see if there are any records that should be deleted, either because
        // a) the case owner has changed, or b) they are for a different role formerly held by the
        // new case owner
        for (CaseTeamMember ctm : caseTeamMembers) {
            if (casesMap.containsKey(ctm.ParentId) && ((ctm.TeamRole.Name == 'Owner' && ctm.MemberId != casesMap.get(ctm.ParentId).OwnerId) || (ctm.TeamRole.Name != 'Owner' && casesMap.get(ctm.ParentId).OwnerId == ctm.MemberId))) {
                teamMembersToDelete.add(ctm);
            }
        }
        if (!teamMembersToDelete.isEmpty()) {delete teamMembersToDelete;}
    }
    
}