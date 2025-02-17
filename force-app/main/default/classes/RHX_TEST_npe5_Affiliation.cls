@isTest(SeeAllData=true)
public class RHX_TEST_npe5_Affiliation {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM npe5__Affiliation__c ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new npe5__Affiliation__c()
            );
        }
    	

       rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}