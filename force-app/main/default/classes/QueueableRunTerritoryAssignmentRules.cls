public class QueueableRunTerritoryAssignmentRules implements Queueable, Database.AllowsCallouts  {

    Set<Id> acctsWCurrencyISOCodeOrGeolocationChanges;
    Set<Id> acctsWCurrencyISOCodeChanges;
    
    public QueueableRunTerritoryAssignmentRules(Set<Id> acctsWCurrencyISOCodeOrGeolocationChanges, Set<Id> acctsWCurrencyISOCodeChanges) {
        this.acctsWCurrencyISOCodeOrGeolocationChanges = acctsWCurrencyISOCodeOrGeolocationChanges;
        this.acctsWCurrencyISOCodeChanges = acctsWCurrencyISOCodeChanges;
    }
       
    public void execute(QueueableContext context) {
             
        String accountTag = '<urn:sObjects xsi:type="urn1:Account" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> ' +
            '<urn1:Id>{acctId}</urn1:Id> ' +
            '</urn:sObjects>' ;    
        String soapBody = 
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:urn="urn:partner.soap.sforce.com" '+
            'xmlns:urn1="urn:sobject.partner.soap.sforce.com"> '+
            '<soapenv:Header> ' +
            '<urn:AssignmentRuleHeader> ' + 
            '<urn:useDefaultRule>true</urn:useDefaultRule> ' +
            '<urn:assignmentRuleId></urn:assignmentRuleId> ' +
            '</urn:AssignmentRuleHeader> ' +
            '<urn:SessionHeader> ' +
            '<urn:sessionId>' + UserInfo.getSessionId() + '</urn:sessionId> ' +
            '</urn:SessionHeader> ' +
            '</soapenv:Header> ' +
            '<soapenv:Body> ' +
            '<urn:update> ' +
            '{acctList} ' + 
            '</urn:update> ' +
            '</soapenv:Body> ' +
            '</soapenv:Envelope>';             
        
        List<String> accts = new List<String>();
        for (Id acctId : acctsWCurrencyISOCodeOrGeolocationChanges){
            accts.add(accountTag.replace('{acctId}', acctId)); 
        }
        soapBody = soapBody.replace('{acctList}', String.join(accts, ' ')) ;             
        
        HttpRequest request = new HttpRequest();
        request.setTimeout(60000);            
        request.setMethod('POST');
        request.setEndpoint(System.URL.getSalesforceBaseUrl().toExternalForm()+'/services/Soap/u/41.0/'+UserInfo.getOrganizationId());
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setHeader('SOAPAction', '""'); 
        request.setBody(soapBody);
        Http updateHttp = new Http();
        HttpResponse response = updateHttp.send(request);
		System.debug(response.getStatusCode());                                        
		System.debug(response.getBody());       
        if (!Test.isRunningTest() && !acctsWCurrencyISOCodeChanges.isEmpty()) {
            Database.executeBatch(new BatchRecalcAcctHardSoftCreditAmts(acctsWCurrencyISOCodeChanges, ''), 5);
        }
    }        
}