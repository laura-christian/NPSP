public class GivingSummaryInUSDController {

    @AuraEnabled(cacheable=true)
    public static GivingSummary getGivingSummary(Id acctId) {
        
        List<Opportunity> opps = [SELECT Id, convertCurrency(Amount) convertedAmt, CloseDate
                                  FROM Opportunity 
                                  WHERE ForecastCategory = 'Closed' AND AccountId = :acctId
                                  ORDER BY CloseDate DESC];
        Decimal totalGifts = 0;
        Decimal giftsThisYear = 0;
        Decimal giftsLastYear = 0;
        Decimal giftsTwoYearsAgo = 0;
        for (Opportunity o : opps) {
            Decimal convertedAmt = (Decimal)o.get('convertedAmt');
            totalGifts += convertedAmt;
            if (o.CloseDate.year() == System.today().year()) {
                giftsThisYear += convertedAmt;
            }
            else if (o.CloseDate.year() == System.today().year()-1) {
                giftsLastYear += convertedAmt;
            }
            else if (o.CloseDate.year() == System.today().year()-2) {
                giftsTwoYearsAgo += convertedAmt;
            }
        }
        List<npsp__Account_Soft_Credit__c> acctSoftCredits = [SELECT Id, CurrencyIsoCode, npsp__Amount__c, npsp__Opportunity__r.CloseDate,
                                                              npsp__Opportunity__r.Is_P2P_Gift__c
                                                              FROM npsp__Account_Soft_Credit__c
                                                              WHERE npsp__Account__c = :acctId
                                                              AND npsp__Opportunity__r.ForecastCategory = 'Closed'];
        List<npsp__Partial_Soft_Credit__c> partialSoftCredits = [SELECT Id, CurrencyIsoCode, npsp__Amount__c,
                                                                 npsp__Opportunity__r.CloseDate, npsp__Opportunity__r.Is_P2P_Gift__c
                                                                 FROM npsp__Partial_Soft_Credit__c
                                                                 WHERE npsp__Contact__r.AccountId = :acctId 
                                                                 AND npsp__Opportunity__r.ForecastCategory = 'Closed'];
        Decimal totalSoftCredits = 0;
        Decimal totalP2PSoftCredits = 0;
        Decimal softCreditsThisYear = 0;
        Decimal softCreditsLastYear = 0;
        Decimal softCreditsTwoYearsAgo = 0;
		Set<String> softCreditCurrencies = new Set<String>();
        for (npsp__Account_Soft_Credit__c acctSoftCred : acctSoftCredits) {
            if (acctSoftCred.CurrencyIsoCode != 'USD') {
            	softCreditCurrencies.add(acctSoftCred.CurrencyIsoCode);
            }
        }
        for (npsp__Partial_Soft_Credit__c partialSoftCred : partialSoftCredits) {
            if (partialSoftCred.CurrencyIsoCode != 'USD') {
            	softCreditCurrencies.add(partialSoftCred.CurrencyIsoCode);
            }
        }
        List<DatedConversionRate> DCRs = [SELECT Id, IsoCode, StartDate, NextStartDate, ConversionRate
                                          FROM DatedConversionRate
                                          WHERE IsoCode IN :softCreditCurrencies
                                          ORDER BY StartDate DESC];
        Map<String, List<DatedConversionRate>> mapCurrencyToDatedConversionRates = new Map<String, List<DatedConversionRate>>();
        for (DatedConversionRate DCR : DCRs) {
            if (!mapCurrencyToDatedConversionRates.containsKey(DCR.IsoCode) && DCR.IsoCode != 'USD') {
                mapCurrencyToDatedConversionRates.put(DCR.IsoCode, new List<DatedConversionRate>{DCR});
            }
            else {mapCurrencyToDatedConversionRates.get(DCR.IsoCode).add(DCR);}
        }
        for (npsp__Account_Soft_Credit__c acctSoftCred : acctSoftCredits) {
            String currencyCode = acctSoftCred.CurrencyIsoCode;
            Decimal amt = acctSoftCred.npsp__Amount__c;
            Date oppCloseDate = acctSoftCred.npsp__Opportunity__r.CloseDate;
            Decimal conversionRate;
            Decimal convertedAmt;
            if (acctSoftCred.CurrencyIsoCode == 'USD') {
                convertedAmt = amt;
            }
            else {
            	List<DatedConversionRate> conversionRates = mapCurrencyToDatedConversionRates.get(currencyCode);
                for (DatedConversionRate rate : conversionRates) {
                    if (rate.StartDate <= oppCloseDate && rate.NextStartDate > oppCloseDate) {
                        conversionRate = rate.ConversionRate;
                        convertedAmt = amt/conversionRate;
                        break;
                    }
                }
            }
            if (!acctSoftCred.npsp__Opportunity__r.Is_P2P_Gift__c) {
                totalSoftCredits += convertedAmt;
                if (acctSoftCred.npsp__Opportunity__r.CloseDate.year() == System.today().year()) {
                    softCreditsThisYear += convertedAmt;
                }
                else if (acctSoftCred.npsp__Opportunity__r.CloseDate.year() == System.today().year()-1) {
                    softCreditsLastYear += convertedAmt;
                }
                else if (acctSoftCred.npsp__Opportunity__r.CloseDate.year() == System.today().year()-2) {
                    softCreditsTwoYearsAgo += convertedAmt;
                }
            }
            else {totalP2PSoftCredits += convertedAmt;}
        }
        for (npsp__Partial_Soft_Credit__c partialSoftCred : partialSoftCredits) {
            String currencyCode = partialSoftCred.CurrencyIsoCode;
            Decimal amt = partialSoftCred.npsp__Amount__c;
            Date oppCloseDate = partialSoftCred.npsp__Opportunity__r.CloseDate;
            Decimal conversionRate;
            Decimal convertedAmt;
            if (partialSoftCred.CurrencyIsoCode == 'USD') {
                convertedAmt = amt;
            }
            else {
            	List<DatedConversionRate> conversionRates = mapCurrencyToDatedConversionRates.get(currencyCode);
                for (DatedConversionRate rate : conversionRates) {
                    if (rate.StartDate <= oppCloseDate && rate.NextStartDate > oppCloseDate) {
                        conversionRate = rate.ConversionRate;
                        convertedAmt = amt/conversionRate;
                        break;
                    }
                }
            }
            if (!partialSoftCred.npsp__Opportunity__r.Is_P2P_Gift__c) {
                totalSoftCredits += convertedAmt;
                if (partialSoftCred.npsp__Opportunity__r.CloseDate.year() == System.today().year()) {
                    softCreditsThisYear += convertedAmt;
                }
                else if (partialSoftCred.npsp__Opportunity__r.CloseDate.year() == System.today().year()-1) {
                    softCreditsLastYear += convertedAmt;
                }
                else if (partialSoftCred.npsp__Opportunity__r.CloseDate.year() == System.today().year()-2) {
                    softCreditsTwoYearsAgo += convertedAmt;
                }
            }
            else {totalP2PSoftCredits += convertedAmt;}
        }
        Decimal totalCredits = totalGifts + totalSoftCredits;
        Decimal creditsThisYear = giftsThisYear + softCreditsThisYear;
        Decimal creditsLastYear = giftsLastYear + softCreditsLastYear;
        Decimal creditsTwoYearsAgo = giftsTwoYearsAgo + softCreditsTwoYearsAgo;
        return new GivingSummary(totalCredits, creditsThisYear, creditsLastYear, creditsTwoYearsAgo,
                                totalGifts, giftsThisYear, giftsLastYear, giftsTwoYearsAgo,
                                totalSoftCredits, totalP2PSoftCredits, softCreditsThisYear, softCreditsLastYear,
                                softCreditsTwoYearsAgo);
    }    
}