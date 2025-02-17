public class NewContactExt { 

    public Contact con { get; set; }     
    public npe5__Affiliation__c affiliation { get; set; }
       
    public NewContactExt(ApexPages.StandardSetController ssc) {
        con = new Contact();
        affiliation = new npe5__Affiliation__c();
    }     
    
    public PageReference saveContact() {   
        try {
            insert con;
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }
        if (!String.isBlank(affiliation.Type__c) && !String.isBlank(affiliation.npe5__Organization__c)) {
            affiliation.npe5__Contact__c = con.Id;
            insert affiliation;
            List<Account> affiliateOrg = [SELECT Id, npe01__One2OneContact__c FROM Account WHERE Id = :affiliation.npe5__Organization__c LIMIT 1];
            if (!affiliateOrg.isEmpty() && String.isBlank(affiliateOrg[0].npe01__One2OneContact__c)) {
                affiliateOrg[0].npe01__One2OneContact__c = con.Id;
                update affiliateOrg;
            }
        }
        PageReference pageRef = new PageReference('/' + con.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public PageReference cancel() {
        PageReference pageRef = new PageReference('/003/o');
        pageRef.setRedirect(true);
        return pageRef;
    }
}