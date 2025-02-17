public without sharing class OpportunityTeamMemberController {
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityTeamMember> getOppTeamMembers(Id oppId) {
        return [SELECT Id, UserId, User.Name, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :oppId ORDER BY TeamMemberRole];
    }
    
    @AuraEnabled
    public static OpportunityTeamMember insertOppTeamMember(Id oppId, Id userId, String role) {
        OpportunityTeamMember otm = new OpportunityTeamMember(
        OpportunityId = oppId,
        UserId = userId,
        TeamMemberRole = role);
        insert otm;
        return otm;
    }
    
}