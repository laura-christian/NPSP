@isTest
public class ConvertedPaymentAmtControllerTest {

    @isTest
    public static void testDatedConversionController() {
        
        Opportunity o = new Opportunity(
        Name = 'Donation',
        CurrencyIsoCode = 'GBP',
        Amount = 100,
        CloseDate = System.today()-30,
        StageName = 'Open');
        insert o;
        
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
        npe01__Scheduled_Date__c = System.today()-30,
        npe01__Paid__c = false,
        CurrencyIsoCode = 'GBP',
        npe01__Payment_Amount__c = 100,
        npe01__Opportunity__c = o.Id);
        insert pmt;
        
        Decimal amtInUSDToday = ConvertedPaymentAmtController.getPmtAmtInUSD(pmt.Id);
        o.StageName = 'Closed Won';
        o.CloseDate = System.today()-15;
        update o;
        pmt.npe01__Payment_Date__c = System.today()-15;
        pmt.npe01__Paid__c = true;
        update pmt;
        Decimal amtInUSDAsOfClose = ConvertedPaymentAmtController.getPmtAmtInUSD(pmt.Id);

    }
    
}