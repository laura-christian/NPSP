@isTest(SeeAllData=true)
public class RHX_TEST_CaseComment {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM CaseComment ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new CaseComment()
            );
        }
    	

       rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}