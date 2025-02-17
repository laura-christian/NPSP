public class GivingArmController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getGivingArmDetails(Id acctId) {
        
        List<npe5__Affiliation__c> affiliations = [SELECT Id, npe5__Contact__c, npe5__Contact__r.AccountId,
                                                   npe5__Organization__c, Type__c
                                                   FROM npe5__Affiliation__c
                                                   WHERE npe5__Contact__r.AccountId = :acctId AND
                                                   Type__c = 'Giving Arm'];
        Set<Id> givingArmIds = new Set<Id>();
        for (npe5__Affiliation__c affil : affiliations) {
            givingArmIds.add(affil.npe5__Organization__c);
        }        
        return [SELECT Id, Name, CurrencyIsoCode, npo02__TotalOppAmount__c, 
                (SELECT Id, Name, CurrencyIsoCode, Amount, CloseDate, Probability, OwnerId, Owner.Name 
				 FROM Opportunities WHERE CloseDate >= LAST_YEAR
                 ORDER BY CloseDate DESC LIMIT 3) 
				 FROM Account WHERE Id IN :givingArmIds];
    } 
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getGivingArmHouseholdDetails(Id acctId) {
        
        List<npe5__Affiliation__c> affiliations = [SELECT Id, npe5__Contact__c, npe5__Contact__r.AccountId,
                                                   npe5__Organization__c, Type__c
                                                   FROM npe5__Affiliation__c
                                                   WHERE npe5__Organization__c = :acctId AND
                                                   Type__c = 'Giving Arm'];
        Set<Id> householdIds = new Set<Id>();
        for (npe5__Affiliation__c affil : affiliations) {
            householdIds.add(affil.npe5__Contact__r.AccountId);
        }        
        return [SELECT Id, Name, Current_Relationship_Manager__c, Current_Relationship_Manager__r.Name, CurrencyIsoCode, Total_Credits__c
                FROM Account
                WHERE Id IN :householdIds];
    }      
    
}