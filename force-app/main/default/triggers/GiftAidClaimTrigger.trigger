trigger GiftAidClaimTrigger on gcga__Gift_Aid_Claim__c (after update) {

    public static Account hmrc = [SELECT Id FROM Account WHERE Name = 'HM Revenue & Customs' LIMIT 1];
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        Set<Id> processedClaimIds = new Set<Id>();
        for (gcga__Gift_Aid_Claim__c claim : Trigger.new) {
            if (Trigger.oldMap.get(claim.Id).gcga__Claim_Stage__c != 'Reclaimed' && claim.gcga__Claim_Stage__c == 'Reclaimed') {
                processedClaimIds.add(claim.Id);
            }    
        }
        List<Opportunity> opps = [SELECT Id, Name, CurrencyIsoCode, Amount, gcga__Gift_Aid_Amount__c, 
                                  CloseDate, npsp__Primary_Contact__c, AccountId, CampaignId,
                                  gcga__Gift_Aid_Claim__c, gcga__Gift_Aid_Claim__r.gcga__Date_of_Reclaim__c
                                  FROM Opportunity
                                  WHERE gcga__Gift_Aid_Claim__c IN :processedClaimIds AND gcga__Gift_Aid_Invalid__c = false AND gcga__Is_Gift_Aid_Excluded__c = false];
        List<Opportunity> hmrcCreditsToInsert = new List<Opportunity>();
        for (Opportunity o : opps) {
            Opportunity hmrcCred = new Opportunity(
            Name = 'Donation',
            AccountId = hmrc.Id,
            CurrencyIsoCode = 'GBP',
            Amount = o.gcga__Gift_Aid_Amount__c,
            StageName = 'Closed Won',
            CloseDate = o.gcga__Gift_Aid_Claim__r.gcga__Date_of_Reclaim__c != null ? o.gcga__Gift_Aid_Claim__r.gcga__Date_of_Reclaim__c : System.today(),
            CampaignId = o.CampaignId);
            hmrcCreditsToInsert.add(hmrcCred);
        }
        List<OpportunityContactRole> OCRs = new List<OpportunityContactRole>();
        List<npsp__Account_Soft_Credit__c> acctSoftCredits = new List<npsp__Account_Soft_Credit__c>();
        if (!hmrcCreditsToInsert.isEmpty()) {
        	Database.SaveResult[] saveResults = Database.insert(hmrcCreditsToInsert, false);
            for (Integer i=0; i<saveResults.size(); i++) {
                if (saveResults.get(i).isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted opportunity record. Opportunity Id: ' + saveResults.get(i).getId());
                    if (!String.isBlank(opps[i].npsp__Primary_Contact__c)) {
                        OpportunityContactRole ocr = new OpportunityContactRole(
                        OpportunityId = saveResults.get(i).getId(),
                        ContactId = opps[i].npsp__Primary_Contact__c,
                        Role = 'Soft Credit',
                        Soft_Credit_Percent__c = 100);
                        OCRs.add(ocr);
                    }
                    else {
                        npsp__Account_Soft_Credit__c acctSoftCred = new npsp__Account_Soft_Credit__c(
                        npsp__Opportunity__c = saveResults.get(i).getId(),
                        npsp__Account__c = opps[i].AccountId,
                        npsp__Role__c = 'Soft Credit',
                        Percent__c = 100);
                        acctSoftCredits.add(acctSoftCred);
                    }
                }
                else {
                    System.debug('The following error has occurred:');                    
                    Database.Error error = saveResults.get(i).getErrors().get(0);
                    System.debug(error.getMessage());
                }
            }
            if (!OCRs.isEmpty()) {Database.insert(OCRs, false);}
            if (!acctSoftCredits.isEmpty()) {Database.insert(acctSoftCredits, false);}
        }
    }
}