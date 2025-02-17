trigger CaseTrigger on Case (after insert, after update) {
    
    List<CaseTeamRole> ownerRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'Owner' LIMIT 1];
    
    List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
    List<Case> changedOwners = new List<Case>();
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            // When new case inserted, create case team member record for owner unless the owner is
            // the generic Room to Read user (who is the default assigned owner for email-to-case)
            for (Case c : Trigger.new) {
                if (c.OwnerId != '0058b00000Gl4U9') {
                    if (!ownerRole.isEmpty()) {
                        CaseTeamMember ctm = new CaseTeamMember(
                        ParentId = c.Id,
                        MemberId = c.OwnerId,
                        TeamRoleId = ownerRole[0].Id);
                        caseTeamMembers.add(ctm);
                    }
                }
            }
        }
        else if (Trigger.isUpdate) {
            for (Case c : Trigger.new) {
                // If the owner changes, i.e., if the case is reassigned, a new case team member record
                // with a role of "Owner" will be created
                if (Trigger.oldMap.get(c.Id).OwnerId != c.OwnerId) {
                    changedOwners.add(c);
                    if (!ownerRole.isEmpty()) {
                        CaseTeamMember ctm = new CaseTeamMember(
                        ParentId = c.Id,
                        MemberId = c.OwnerId,
                        TeamRoleId = ownerRole[0].Id);
                        caseTeamMembers.add(ctm);                        
                    }
                }
            }
        }
        // Insert case team member records
        if (!caseTeamMembers.isEmpty()) {
            Database.saveResult[] saveResults = Database.insert(caseTeamMembers, false);
            for (Integer i=0; i<caseTeamMembers.size(); i++) {
                if (saveResults.get(i).isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted case team member record. Record Id: ' + saveResults.get(i).getId());
                }
                else {
                    System.debug('The following error has occurred:');                    
                    Database.Error error = saveResults.get(i).getErrors().get(0);
                    System.debug(error.getMessage());
                }                
            }
        }
        // Finally, pass list of cases that have changed owners to queueable class so that
        // case team member records for former owners can be deleted (this is to avoid having more than
        // one owner of a case on the case team)
        if (!changedOwners.isEmpty() && Limits.getQueueableJobs()<2) {System.enqueueJob(new QueueableSweepCaseTeamMembers(changedOwners));}
    }

}