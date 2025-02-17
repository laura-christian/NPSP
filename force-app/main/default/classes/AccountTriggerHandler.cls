public class AccountTriggerHandler {      

    public static List<User> rtrUser = [SELECT Id FROM User WHERE Name = 'Room to Read' LIMIT 1];
    
    public static void beforeInsert(List<Account> accts) {
        // Record owner always defaults to generic Room to Read user 
        for (Account a : accts) {
            if (a.RecordTypeId == '0128b000000XLonAAG' && String.isBlank(a.BillingCountry)) {
                a.addError('You must include an address when creating a new organizational account.');
            }
            a.OwnerId = !rtrUser.isEmpty() ? rtrUser[0].Id : UserInfo.getUserId();
        }
    }

	public static void beforeUpdate(List<Account> accts, Map<Id, Account> acctsOldMap, Map<Id, Account> acctsNewMap) {    

        // "HPC" stands for "Highest Previous Contribution."
        // This code block checks to see whether the largest gift amount for an account has changed;
        // if it has, it runs through all the previous gifts made by that donor to determine which gift
        // represented the HPC, and inserts the amount of the gift as well as its original currency 
        // in two separate fields        
        Set<Id> acctIdsChangeOfHPC = new Set<Id>();
        for (Account a : accts) {
            if (a.npo02__LargestAmount__c != acctsOldMap.get(a.Id).npo02__LargestAmount__c && a.npo02__LargestAmount__c > 0) {
                acctIdsChangeOfHPC.add(a.Id);
            }
        }
        List<Opportunity> previousGifts = [SELECT Id, AccountId, Amount, convertCurrency(Amount) amtInUSD, Amount_in_Acct_Currency__c, CurrencyIsoCode, CloseDate FROM Opportunity WHERE AccountId IN :acctIdsChangeOfHPC AND ForecastCategory = 'Closed' AND Amount != null ORDER BY AccountId];
        Map<Id, Decimal> acctIdToAmtInUSD = new Map<Id, Decimal>();
        Map<Id, Decimal> acctIdToAmtInAcctCurrency = new Map<Id, Decimal>();        
        Map<Id, Decimal> acctIdToHPCOriginalCurrency = new Map<Id, Decimal>();
        Map<Id, String> acctIdToOriginalCurrency = new Map<Id, String>();
        for (Opportunity opp : previousGifts) {
            if (!acctIdToAmtInUSD.containsKey(opp.AccountId)) {
                acctIdToAmtInUSD.put(opp.AccountId, (Decimal)opp.get('amtInUSD'));
                acctIdToAmtInAcctCurrency.put(opp.AccountId, opp.Amount_in_Acct_Currency__c);                
                acctIdToHPCOriginalCurrency.put(opp.AccountId, opp.Amount);
                acctIdToOriginalCurrency.put(opp.AccountId, opp.CurrencyIsoCode);
            }
            else if ((Decimal)opp.get('amtInUSD') > acctIdToAmtInUSD.get(opp.AccountId)) {
                acctIdToAmtInUSD.put(opp.AccountId, (Decimal)opp.get('amtInUSD'));
                acctIdToAmtInAcctCurrency.put(opp.AccountId, opp.Amount_in_Acct_Currency__c);                
                acctIdToHPCOriginalCurrency.put(opp.AccountId, opp.Amount);
                acctIdToOriginalCurrency.put(opp.AccountId, opp.CurrencyIsoCode);
            }
        }
        for (Account a : accts) {
            if (acctIdToHPCOriginalCurrency.containsKey(a.Id) && acctIdToOriginalCurrency.containsKey(a.Id) && acctIdToAmtInAcctCurrency.containsKey(a.Id)) {
                a.HPC_Value__c = acctIdToHPCOriginalCurrency.get(a.Id);
                a.HPC_Currency__c = acctIdToOriginalCurrency.get(a.Id);
                a.npo02__LargestAmount__c = acctIdToAmtInAcctCurrency.get(a.Id);
            }           
        }

        // Validation rules to prevent manual change of Current Relationship Manager or account owner
        // or overwrite of rollup summary fields by native NPSP rollup function
		Set<Id> acctIdsChangeOfRM = new Set<Id>();
        Set<Id> acctIdsChangeOwner = new Set<Id>();
        for (Account a : accts) {
            if (a.Updated_Via_Apex_Trigger__c==false && a.Current_Relationship_Manager__c!=acctsOldMap.get(a.Id).Current_Relationship_Manager__c) {
				a.addError('You cannot update this field directly; instead, you should create an account team member record for the RM and this field will be updated automatically.');                
            }
            else if (a.Updated_Via_Apex_Trigger__c==false && a.OwnerId!=acctsOldMap.get(a.Id).OwnerId) {
                a.addError('You cannot change the owner of an account directly. Instead, you should create an account team member record for the RM, and they will automatically be made the owner; or, retire the current RM and let ownership of the account revert to the Room to Read user.');
            }
			else if (a.Updated_Via_Apex_Trigger__c==false && (a.npo02__Best_Gift_Year__c!=acctsOldMap.get(a.Id).npo02__Best_Gift_Year__c || a.npo02__Best_Gift_Year_Total__c!=acctsOldMap.get(a.Id).npo02__Best_Gift_Year_Total__c || a.First_Gift_Amount__c!=acctsOldMap.get(a.Id).First_Gift_Amount__c || a.npo02__LastOppAmount__c!=acctsOldMap.get(a.Id).npo02__LastOppAmount__c)) {
                a.npo02__Best_Gift_Year__c = acctsOldMap.get(a.Id).npo02__Best_Gift_Year__c;
                a.npo02__Best_Gift_Year_Total__c = acctsOldMap.get(a.Id).npo02__Best_Gift_Year_Total__c;
            	a.First_Gift_Amount__c = acctsOldMap.get(a.Id).First_Gift_Amount__c;
                a.npo02__LastOppAmount__c = acctsOldMap.get(a.Id).npo02__LastOppAmount__c;
            }
            // If changes are in context of addition of very first account team member(s), allow 
            // ATM trigger to handle (in cart-before-horse fashion, user must be owner of account
            // before they can be added to account team). Code below is only meant to handle changes
            // to current RM or account owner that take place *after* addition of first ATM. 
            else if (a.Updated_Via_Apex_Trigger__c==true && a.Count_of_Acct_Team_Members__c>0) {
                if (a.Current_Relationship_Manager__c!=acctsOldMap.get(a.Id).Current_Relationship_Manager__c) {
                    acctIdsChangeOfRM.add(a.Id);
                }
                // If account owner is being changed by admin (who knows to check the Updated Via Apex Trigger box to avoid error),
                // need to ensure that change will be processed via SOAP callout in queueable class that preserves 
                // historical ATM records -- otherwise, ATM records will be erased, and no trace will be left of them!!!
                /*if (a.OwnerId!=acctsOldMap.get(a.Id).OwnerId && !System.isQueueable()) {
                    // Do not commit change of owner to database for now -- instead, submit to queueable class to determine who owner should be
                    a.OwnerId = acctsOldMap.get(a.Id).OwnerId;
                    acctIdsChangeOwner.add(a.Id);
                }*/
            }
        }
		List<AccountTeamMember> RMs = [SELECT Id, AccountId, UserId 
                                       FROM AccountTeamMember 
                                       WHERE TeamMemberRole = 'Relationship Manager' AND (End_Date__c = null OR End_Date__c > TODAY)
                                       AND AccountId IN :acctIdsChangeOfRM
                                       ORDER BY AccountId, Start_Date__c DESC];
        Map<Id, Id> acctToRMUserId = new Map<Id, Id>();
        for (AccountTeamMember atm : RMs) {
            if (!acctToRMUserId.containsKey(atm.AccountId)) {
               acctToRMUserId.put(atm.AccountId, atm.UserId);
            }
        }
        for (Id acctId : acctIdsChangeOfRM) {
            if (acctToRMUserId.containsKey(acctId)) {
                acctsNewMap.get(acctId).Current_Relationship_Manager__c = acctToRMUserId.get(acctId);
                if (acctsNewMap.get(acctId).OwnerId!=acctsNewMap.get(acctId).Current_Relationship_Manager__c) {
                    // Keep old owner and let queueable class determine who new owner should be
                    acctsNewMap.get(acctId).OwnerId = acctsOldMap.get(acctId).OwnerId;
                    acctIdsChangeOwner.add(acctId);
                }
            }
            else if (!acctToRMUserId.containsKey(acctId)) {
                acctsNewMap.get(acctId).Current_Relationship_Manager__c = null;
                if (!rtrUser.isEmpty() && acctsNewMap.get(acctId).OwnerId!=rtrUser[0].Id) {
                    // Keep old owner and let queueable class revert ownership to RtR user
                    acctsNewMap.get(acctId).OwnerId = acctsOldMap.get(acctId).OwnerId;
                    acctIdsChangeOwner.add(acctId);
                }
            }
        }
        if (!acctIdsChangeOwner.isEmpty() && Limits.getQueueableJobs()==0) {
            System.enqueueJob(new QueueableChangeAcctOwnerKeepAcctTeam(acctIdsChangeOwner));
        }
		        
    }
    
	public static void afterUpdate(List<Account> accts, Map<Id, Account> acctsOldMap, Map<Id, Account> acctsNewMap) {
		// Update contacts with account currency code when the latter changes, or when new household member is added
        Set<Id> acctsWCurrencyISOCodeChanges = new Set<Id>();
        Set<Id> acctsWCurrencyISOCodeChangesOrNewMembers = new Set<Id>();
        Set<Id> acctsWCurrencyISOCodeOrGeolocationChanges = new Set<Id>();
        for (Account a : accts) {
            if (a.CurrencyIsoCode != acctsOldMap.get(a.Id).CurrencyIsoCode) {
                acctsWCurrencyISOCodeChanges.add(a.Id);
                acctsWCurrencyISOCodeChangesOrNewMembers.add(a.Id);
                if (!a.IsExcludedFromRealign) {
                	acctsWCurrencyISOCodeOrGeolocationChanges.add(a.Id);
                }
            }
            if (a.npsp__Number_of_Household_Members__c  != acctsOldMap.get(a.Id).npsp__Number_of_Household_Members__c) {
                acctsWCurrencyISOCodeChangesOrNewMembers.add(a.Id);
            }
            if (a.BillingCountry != acctsOldMap.get(a.Id).BillingCountry && !a.IsExcludedFromRealign) {
                acctsWCurrencyISOCodeOrGeolocationChanges.add(a.Id);
            }
        }
		List<Contact> contactsToUpdate = new List<Contact>(); 
		Set<Id> contactIds = new Set<Id>();        
        if (!acctsWCurrencyISOCodeChangesOrNewMembers.isEmpty()) {
            List<Contact> contactsWAcctCurrCodeChanges = [SELECT Id, AccountId, Name FROM Contact WHERE AccountId IN :acctsWCurrencyISOCodeChangesOrNewMembers];
            for (Contact c : contactsWAcctCurrCodeChanges) {
                c.CurrencyIsoCode = acctsNewMap.get(c.AccountId).CurrencyIsoCode;
                contactIds.add(c.Id);
                contactsToUpdate.add(c);
            }
        }
        
        // Flags contacts for re-sync to EN when accounts have been marked for push
		Set<Id> acctIdsMarkedForENPush = new Set<Id>();
        for (Account a : accts) {
            if (a.EN_Push__c == true && acctsOldMap.get(a.Id).EN_Push__c == false) {
                acctIdsMarkedForENPush.add(a.Id);
            }
        }
        if (!acctIdsMarkedForENPush.isEmpty()) { 
            List<Contact> contactsWAcctsMarkedForENPush = 
                [SELECT Id, Name, AccountId, Email, engaging__EN_Last_Modified_Date__c
                 FROM Contact
                 WHERE AccountId IN :acctIdsMarkedForENPush
                 ORDER BY AccountId];         
            for (Contact c : contactsWAcctsMarkedForENPush) {
                // Make sure contact record has not already been added to list of contacts to be updated (otherwise will throw error)
                Datetime now = System.now();
				Datetime localNow = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());
                if (!String.isBlank(c.Email) && !contactIds.contains(c.Id) && (c.engaging__EN_Last_Modified_Date__c == null || c.engaging__EN_Last_Modified_Date__c < localNow.addMinutes(-1))) {
                    c.engaging__EN_Last_Modified_Date__c = localNow;
                    contactsToUpdate.add(c);
                }
            }
        }
        if (!contactsToUpdate.isEmpty()) {
        	Database.update(contactsToUpdate, false);
        }
        if (!acctsWCurrencyISOCodeOrGeolocationChanges.isEmpty()) {
            if (!Test.isRunningTest() && Limits.getQueueableJobs()==0) {System.enqueueJob(new QueueableRunTerritoryAssignmentRules(acctsWCurrencyISOCodeOrGeolocationChanges, acctsWCurrencyISOCodeChanges));}
            else {
                Datetime now = Datetime.now();
                Datetime fiveSecondsFromNow = now.addSeconds(5);
                String hour = String.valueOf(fiveSecondsFromNow.hour());
                String min = String.valueOf(fiveSecondsFromNow.minute()); 
                String ss = String.valueOf(fiveSecondsFromNow.second());
                // Concatenate strings to cron expression
                String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
                System.schedule('ScheduledJob ' + String.valueOf(Math.random()), nextFireTime, new ScheduleEnqueueJob(acctsWCurrencyISOCodeOrGeolocationChanges, acctsWCurrencyISOCodeChanges));                
            }
        }
    }
    
}