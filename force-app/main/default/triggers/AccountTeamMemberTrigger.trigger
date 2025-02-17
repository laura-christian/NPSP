trigger AccountTeamMemberTrigger on AccountTeamMember (before insert, before update, after insert, after update, after delete) {
    
    // Unit test for this trigger included with tests for queueable class (QueueableChangeAcctOwnerKeepAcctTeam)
    
    public static List<User> rtrUser = [SELECT Id FROM User WHERE Name = 'Room to Read' LIMIT 1];    

    // User must be owner of account before she can be added as an account team member -- hence this
    // very odd trigger that updates the related account *before* inserting a new account team member record
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Map<Id, List<AccountTeamMember>> acctToATMs = new Map<Id, List<AccountTeamMember>>();
            for (AccountTeamMember atm : Trigger.new) {
                if (!acctToATMs.containsKey(atm.AccountId)) {
                    acctToATMs.put(atm.AccountId, new List<AccountTeamMember>{atm});
                }
                else {acctToATMs.get(atm.AccountId).add(atm);}
            }
            List<Account> accts = [SELECT Id, Count_of_Acct_Team_Members__c FROM Account WHERE Id IN :acctToATMs.keySet()];
            List<Account> acctsToUpdate = new List<Account>();
            for (Account a : accts) {
                Boolean insertIncludesCurrentRM = false;
                if (a.Count_of_Acct_Team_Members__c == 0) {
                    a.Updated_Via_Apex_Trigger__c = true;
                    for (AccountTeamMember atm : acctToATMs.get(a.Id)) {
                        if (atm.TeamMemberRole == 'Relationship Manager' && (atm.End_Date__c == null || atm.End_Date__c > System.today())) {
                            insertIncludesCurrentRM = true;
                            a.OwnerId = atm.UserId; 
                            a.Current_Relationship_Manager__c = atm.UserId;
                            break;
                        }
                        else if (!insertIncludesCurrentRM) {a.OwnerId = atm.UserId;}                   
                    }
                    acctsToUpdate.add(a);
                }          
            }
            if (!acctsToUpdate.isEmpty()) {Database.update(acctsToUpdate);}
        }
        /*else if (Trigger.isUpdate) {
            for (AccountTeamMember atm : Trigger.new) {
                if (Trigger.oldMap.get(atm.Id).TeamMemberRole!=atm.TeamMemberRole && Trigger.oldMap.get(atm.Id).Start_Date__c==atm.Start_Date__c) {
                    atm.Start_Date__c = System.today();
                }
            }
        }*/
    }
    
    // If the an ATM has been made the owner of the account to facilitate insertion of their ATM record, but should
    // not actually be the owner; or, if the just-inserted RM is no longer current or an end date has been entered on
    // an existing RM's ATM record; *or* if an ATM record has just been deleted, reevaluate all ATM records and 
    // determine whether there is still an active RM on the account
    else if (Trigger.isAfter) {
        Set<Id> acctIds = new Set<Id>();
		List<AccountTeamMember> ATMs = Trigger.isDelete ? Trigger.old : Trigger.new;        
        for (AccountTeamMember atm : ATMs) {
			acctIds.add(atm.AccountId);
        }
        List<AccountTeamMember> RMs = [SELECT UserId, AccountId, TeamMemberRole, Start_Date__c, End_Date__c, Status__c
                                       FROM AccountTeamMember
                                       WHERE TeamMemberRole = 'Relationship Manager' AND (End_Date__c = null OR End_Date__c > TODAY)
                                       AND AccountId IN :acctIds
                                       ORDER BY AccountId, Start_Date__c DESC];
        List<Account> accts = [SELECT Id, OwnerId, Current_Relationship_Manager__c FROM Account WHERE Id IN :acctIds];
        Map<Id, Id> acctToCurrentRMUserId = new Map<Id, Id>();
        for (AccountTeamMember atm : RMs) {
            // There may be multiple ATMs on the account with a role of RM and no end date: if that is the case,
            // then only the most recently-appointed RM will be included in the acctToCurrentRMUserId map (SOQL query is sorted
            // by start date to allow for this)
            if (!acctToCurrentRMUserId.containsKey(atm.AccountId)) {            
        		acctToCurrentRMUserId.put(atm.AccountId, atm.UserId);
            }
        }
        List<Account> acctsToUpdate = new List<Account>();
        Set<Id> acctIdsChangeOwner = new Set<Id>();
        for (Account a : accts) {
            a.Updated_Via_Apex_Trigger__c = true;
            if (acctToCurrentRMUserId.containsKey(a.Id) && a.Current_Relationship_Manager__c!=acctToCurrentRMUserId.get(a.Id)) {
                a.Current_Relationship_Manager__c = acctToCurrentRMUserId.get(a.Id);
                if (a.OwnerId!=a.Current_Relationship_Manager__c) {
                    acctIdsChangeOwner.add(a.Id);
                }
                acctsToUpdate.add(a);
            }
            else if (!acctToCurrentRMUserId.containsKey(a.Id)) {
                a.Current_Relationship_Manager__c = null;
                if (!rtrUser.isEmpty() && a.OwnerId!=rtrUser[0].Id) {
                	acctIdsChangeOwner.add(a.Id);
                }
                acctsToUpdate.add(a);
            }          
        }
        if (!acctsToUpdate.isEmpty()) {Database.update(acctsToUpdate, false);}
        if (!acctIdsChangeOwner.isEmpty() && Limits.getQueueableJobs()==0) {
            System.enqueueJob(new QueueableChangeAcctOwnerKeepAcctTeam(acctIdsChangeOwner));
        }
        
        List<Account_Team_Member_History__c> logsToInsert = new List<Account_Team_Member_History__c>();
        if (Trigger.isInsert) {
            for (AccountTeamMember atm : Trigger.new) {
                Account_Team_Member_History__c ATMHist = new Account_Team_Member_History__c(
                Account__c = atm.AccountId,
                TeamMember__c = atm.UserId,
                New_Role__c = atm.TeamMemberRole,
                New_Start_Date__c = atm.Start_Date__c,
                New_End_Date__c = atm.End_Date__c);
                logsToInsert.add(ATMHist);
            } 
        }
        else if (Trigger.isUpdate) {
            for (AccountTeamMember atm : Trigger.new) {
                Account_Team_Member_History__c ATMHist = new Account_Team_Member_History__c(
                Account__c = atm.AccountId,
                TeamMember__c = atm.UserId,
                Previous_Role__c = Trigger.oldMap.get(atm.Id).TeamMemberRole,
                New_Role__c = atm.TeamMemberRole,
                Previous_Start_Date__c = Trigger.oldMap.get(atm.Id).Start_Date__c,
                New_Start_Date__c = atm.Start_Date__c,
                Previous_End_Date__c = Trigger.oldMap.get(atm.Id).TeamMemberRole!=atm.TeamMemberRole && Trigger.oldMap.get(atm.Id).Start_Date__c!=atm.Start_Date__c && Trigger.oldMap.get(atm.Id).End_Date__c==null ? atm.Start_Date__c.addDays(-1) : System.today().addDays(-1),
                New_End_Date__c = atm.End_Date__c);
                logsToInsert.add(ATMHist);
            }
        }
        if (!logsToInsert.isEmpty()) {Database.insert(logsToInsert);}
    }
    
    
}