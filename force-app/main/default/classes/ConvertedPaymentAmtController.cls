public class ConvertedPaymentAmtController {
    
    @AuraEnabled(cacheable=true)
    public static Decimal getPmtAmtInUSD(Id pmtId) {
        npe01__OppPayment__c pmt = [SELECT Id, CurrencyIsoCode, npe01__Payment_Amount__c, 
                                    npe01__Payment_Date__c, npe01__Scheduled_Date__c, npe01__Paid__c
                                    FROM npe01__OppPayment__c
                                    WHERE Id = :pmtId LIMIT 1];
        Decimal conversionRate;
        if (pmt.npe01__Paid__c && pmt.npe01__Payment_Date__c != null && pmt.CurrencyIsoCode != 'USD') {
            DatedConversionRate dcr = [SELECT IsoCode, StartDate, NextStartDate, ConversionRate
                                       FROM DatedConversionRate
                                       WHERE IsoCode = :pmt.CurrencyIsoCode AND StartDate <= :pmt.npe01__Payment_Date__c AND NextStartDate > :pmt.npe01__Payment_Date__c
                                       LIMIT 1];
            conversionRate = dcr.ConversionRate;
        }
        else if (!pmt.npe01__Paid__c && pmt.npe01__Scheduled_Date__c != null && pmt.CurrencyIsoCode != 'USD') {
            DatedConversionRate dcr = [SELECT IsoCode, StartDate, NextStartDate, ConversionRate
                                       FROM DatedConversionRate
                                       WHERE IsoCode = :pmt.CurrencyIsoCode AND StartDate <= :pmt.npe01__Scheduled_Date__c AND NextStartDate > :pmt.npe01__Scheduled_Date__c
                                       LIMIT 1];
            conversionRate = dcr.ConversionRate;
        }
        else if (pmt.CurrencyIsoCode == 'USD') {
            conversionRate = 1.00;
        }
        Decimal amtInUSD = pmt.npe01__Payment_Amount__c/conversionRate;
        amtInUSD = amtInUSD.setScale(2);
        return amtInUSD;
    }

}