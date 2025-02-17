trigger PaymentTrigger on npe01__OppPayment__c (before insert, before update) {

    if (Trigger.isBefore) {
        List<npe01__OppPayment__c> pmtsRequiringConversion = new List<npe01__OppPayment__c>();
        Set<String> currencies = new Set<String>();
        Set<Id> oppIds = new Set<Id>();
        for (npe01__OppPayment__c pmt : Trigger.new) {
            if (Trigger.isInsert || (Trigger.isUpdate && (Trigger.oldMap.get(pmt.Id).npe01__Paid__c != pmt.npe01__Paid__c || Trigger.oldMap.get(pmt.Id).npe01__Scheduled_Date__c != pmt.npe01__Scheduled_Date__c || Trigger.oldMap.get(pmt.Id).npe01__Payment_Date__c != pmt.npe01__Payment_Date__c || Trigger.oldMap.get(pmt.Id).npe01__Payment_Amount__c != pmt.npe01__Payment_Amount__c || Trigger.oldMap.get(pmt.Id).CurrencyIsoCode != pmt.CurrencyIsoCode || (!Trigger.oldMap.get(pmt.Id).Recalculate_Converted_Amount__c && pmt.Recalculate_Converted_Amount__c)))) {
                pmtsRequiringConversion.add(pmt);
                currencies.add(pmt.CurrencyIsoCode);
                oppIds.add(pmt.npe01__Opportunity__c);
            }
        }
        // Create map of opps associated with payments requiring conversion
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([SELECT Id, RecordType.Name, CloseDate, AccountId, Account.CurrencyIsoCode
                                               					 FROM Opportunity 
                                               					 WHERE Id IN :oppIds]);
        // Create map of payment Ids to corresponding account currencies; add account currencies to set of
        // currencies for which to look up dated FX rates
        for (Id id : oppsMap.keySet()) {
            currencies.add(oppsMap.get(id).Account.CurrencyIsoCode);
        }
        if (!pmtsRequiringConversion.isEmpty()) {
            List<DatedConversionRate> DCRs = [SELECT IsoCode, StartDate, NextStartDate, ConversionRate
                                              FROM DatedConversionRate
                                              WHERE IsoCode IN :currencies
                                              ORDER BY IsoCode, StartDate DESC];
            Map<String, List<DatedConversionRate>> currencyToFXRates = new Map<String, List<DatedConversionRate>>();
            for (DatedConversionRate dcr : DCRs) {
                if (!currencyToFXRates.containsKey(dcr.IsoCode)) {
                    currencyToFXRates.put(dcr.IsoCode, new List<DatedConversionRate>{dcr});
                }
                else {
                    currencyToFXRates.get(dcr.IsoCode).add(dcr);
                }
            }
            for (npe01__OppPayment__c pmt : pmtsRequiringConversion) {
                Decimal conversionRate;
                List<DatedConversionRate> conversionRates = currencyToFXRates.get(pmt.CurrencyIsoCode);
                if (pmt.npe01__Paid__c && pmt.npe01__Payment_Date__c != null && pmt.CurrencyIsoCode != 'USD') {
                    for (DatedConversionRate dcr : conversionRates) {
                        if (dcr.StartDate <= pmt.npe01__Payment_Date__c && dcr.NextStartDate > pmt.npe01__Payment_Date__c) {
                            conversionRate = dcr.ConversionRate;
                            break;
                        }
                    }
                }
                else if (!pmt.npe01__Paid__c && oppsMap.get(pmt.npe01__Opportunity__c).RecordType.Name == 'Pledge' && pmt.CurrencyIsoCode != 'USD') {
                    for (DatedConversionRate dcr : conversionRates) {
                        if (dcr.StartDate <= oppsMap.get(pmt.npe01__Opportunity__c).CloseDate && dcr.NextStartDate > oppsMap.get(pmt.npe01__Opportunity__c).CloseDate) {
                            conversionRate = dcr.ConversionRate;
                            break;
                        }
                    }                    
                }
                else if (!pmt.npe01__Paid__c && pmt.npe01__Scheduled_Date__c != null && pmt.CurrencyIsoCode != 'USD') {
                    for (DatedConversionRate dcr : conversionRates) {
                        if (dcr.StartDate <= pmt.npe01__Scheduled_Date__c && dcr.NextStartDate > pmt.npe01__Scheduled_Date__c) {
                            conversionRate = dcr.ConversionRate;
                            break;
                        }
                    }                
                }
                else if (pmt.CurrencyIsoCode == 'USD') {conversionRate = 1.00;}
                if (pmt.npe01__Payment_Amount__c != null && conversionRate > 0) {
                    Decimal amtInUSD = pmt.npe01__Payment_Amount__c/conversionRate;
                	pmt.Converted_Amount_Dated__c = amtInUSD.setScale(2);
                }
                String acctCurrency = oppsMap.get(pmt.npe01__Opportunity__c).Account.CurrencyIsoCode;
				Decimal acctCurrencyConversionRate;
                if (acctCurrency == 'USD') {
                    pmt.Amount_in_Acct_Currency__c = pmt.Converted_Amount_Dated__c;
                }
                else if (acctCurrency == pmt.CurrencyIsoCode) {
                    pmt.Amount_in_Acct_Currency__c = pmt.npe01__Payment_Amount__c;
                }
                else if (acctCurrency != 'USD' && acctCurrency != pmt.CurrencyIsoCode) {
					List<DatedConversionRate> acctCurrencyConversionRates = currencyToFXRates.get(acctCurrency);
                    if (pmt.npe01__Paid__c && pmt.npe01__Payment_Date__c != null) {
                        for (DatedConversionRate dcr : acctCurrencyConversionRates) {
                            if (dcr.StartDate <= pmt.npe01__Payment_Date__c && dcr.NextStartDate > pmt.npe01__Payment_Date__c) {
                                acctCurrencyConversionRate = dcr.ConversionRate;
                                break;
                            }
                        }                        
                    }
                    else if (!pmt.npe01__Paid__c && pmt.npe01__Scheduled_Date__c != null) {
                        for (DatedConversionRate dcr : acctCurrencyConversionRates) {
                            if (dcr.StartDate <= pmt.npe01__Scheduled_Date__c && dcr.NextStartDate > pmt.npe01__Scheduled_Date__c) {
                                acctCurrencyConversionRate = dcr.ConversionRate;
                                break;
                            }
                        }                         
                    }
                    if (pmt.Converted_Amount_Dated__c != null && acctCurrencyConversionRate != null) {
                        Decimal amtInAcctCurrency = pmt.Converted_Amount_Dated__c*acctCurrencyConversionRate;
                        // If account currency is JPY, round converted amount to nearest integer
                        pmt.Amount_in_Acct_Currency__c = acctCurrency == 'JPY' ? amtInAcctCurrency.setScale(0) : amtInAcctCurrency.setScale(2);                    
                    } 
				}
                pmt.Recalculate_Converted_Amount__c = false;
        	}
        }
    }
    
}