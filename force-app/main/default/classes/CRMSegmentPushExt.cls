public class CRMSegmentPushExt { 

    public Campaign cmpn { get; set; }             
       
    public CRMSegmentPushExt(ApexPages.StandardController controller) {     
        cmpn =  (Campaign)controller.getRecord();
    }     
    
    //Method that can be called from Visualforce page action attribute (custom button)
    public PageReference sendCRMSegmentToEN() {
		cmpn = [SELECT Id, Name FROM Campaign WHERE Id = :cmpn.Id];
        Database.executeBatch(new MS_ContactSyncSendCRMSegmentToEN(cmpn), 2000);
        PageReference pageRef = new PageReference('/' + cmpn.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
}