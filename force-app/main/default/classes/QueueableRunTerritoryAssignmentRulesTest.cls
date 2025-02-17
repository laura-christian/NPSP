@isTest
public class QueueableRunTerritoryAssignmentRulesTest {
    

    public static SingleRequestMock generateMock() {  
        SingleRequestMock soapAPIResponse = new SingleRequestMock(200, 'OK',
        '<?xml version="1.0" encoding="UTF-8"?>' +
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com">' +
        '    <soapenv:Header>' +
        '        <LimitInfoHeader>' +
        '            <limitInfo>' +
        '                <current>180</current>' +
        '                <limit>5000000</limit>' +
        '                <type>API REQUESTS</type>' +
        '            </limitInfo>' +
        '        </LimitInfoHeader>' +
        '    </soapenv:Header>' +
        '    <soapenv:Body>' +
        '        <updateResponse>' +
        '            <result>' +
        '                <id>001PB00000341K0YAI</id>' +
        '                <success>true</success>' +
        '            </result>' +
        '        </updateResponse>' +
        '    </soapenv:Body>' +
        '</soapenv:Envelope>', null);
 		return soapAPIResponse;       
    }
    
    @isTest
    public static void testChangeOfCurrencyIsoCodeOrGeolocation() {

		SingleRequestMock soapAPIResponse = generateMock();
        Test.setMock(HTTPCalloutMock.class, soapAPIResponse);         
        
        Account a = new Account(
        Name = 'Test Foundation',
        Type = 'Foundation',
        BillingCountry = 'United Kingdom',
        CurrencyIsoCode = 'GBP',
        IsExcludedFromRealign = false);
        insert a;

		a.BillingCountry = 'Hong Kong';
        a.CurrencyIsoCode = 'HKD';
		update a;

        Test.startTest();
        System.enqueueJob(new QueueableRunTerritoryAssignmentRules(new Set<Id>{a.Id}, new Set<Id>{a.Id}));
		Test.stopTest();
        
    } 
    
}