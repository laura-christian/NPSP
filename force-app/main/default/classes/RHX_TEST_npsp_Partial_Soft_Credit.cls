@isTest(SeeAllData=true)
public class RHX_TEST_npsp_Partial_Soft_Credit {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM npsp__Partial_Soft_Credit__c ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new npsp__Partial_Soft_Credit__c()
            );
        }
    	

       rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}