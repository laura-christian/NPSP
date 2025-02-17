public class BatchRecalcConvertedOppAmts implements Database.Batchable<sObject> {

    public List<DatedConversionRate> DCRs = new List<DatedConversionRate>();
    
    public BatchRecalcConvertedOppAmts(List<DatedConversionRate> DCRs) {
        this.DCRs = DCRs;
    }
    
	public Database.QueryLocator start(Database.BatchableContext bc) {
    	System.debug('>>>> Init batch recalculation of converted opp amounts (dated)');
        List<String> queryTargetsByIsoCode = new List<String>();
        for (DatedConversionRate dcr : DCRs) {
            String criterion = '(CurrencyIsoCode = \'' + dcr.isoCode + '\' AND CloseDate >= ' + String.valueOf(dcr.StartDate) + 
                ' AND CloseDate < ' + String.valueOf(dcr.nextStartDate) + ')';
            queryTargetsByIsoCode.add(criterion);
        }
        String queryCriteria = String.join(queryTargetsByIsoCode, ' OR ');
        String stringQuery = 'SELECT Id, CurrencyIsoCode, Account.CurrencyIsoCode, Amount, CloseDate FROM Opportunity WHERE (' + queryCriteria + ') AND RecordTypeId NOT IN (\'0128b000000XLooAAG\', \'0128b000000XLopAAG\') AND ForecastCategory != \'Closed\' AND Amount > 0 AND npe01__Number_of_Payments__c = 0';
        if (Test.isRunningTest()) {stringQuery = stringQuery.replaceAll(' AND npe01__Number_of_Payments__c = 0', '');}
        return Database.getQueryLocator(stringQuery);
    }   
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Set<String> currencies = new Set<String>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity o : scope) {
            currencies.add(o.CurrencyIsoCode);
            currencies.add(o.Account.CurrencyIsoCode);
        }
        Map<String, List<DatedConversionRate>> currencyToFXRates = HardAndSoftCreditTriggerHandler.getDatedConversionRates(currencies);
        for (Opportunity o : scope) {
            Decimal conversionRate;
            if (o.CurrencyIsoCode == 'USD') {
                conversionRate = 1.00;
            }
            else {
                List<DatedConversionRate> conversionRates = currencyToFXRates.get(o.CurrencyIsoCode);
                for (DatedConversionRate dcr : conversionRates) {
                    if (dcr.StartDate <= o.CloseDate && dcr.NextStartDate > o.CloseDate) {
                        conversionRate = dcr.ConversionRate;
                        break;
                    }
                }
            }
            if (conversionRate > 0) {
                Decimal amtInUSD = o.Amount/conversionRate;
                o.Amount_in_USD_Dated__c = amtInUSD.setScale(2);
            }            
            String acctCurrency = o.Account.CurrencyIsoCode;
            if (acctCurrency == 'USD') {
                o.Amount_in_Acct_Currency__c = o.Amount_in_USD_Dated__c;
            }
            else if (acctCurrency == o.CurrencyIsoCode) {
                o.Amount_in_Acct_Currency__c = o.Amount;
            }
            else if (acctCurrency != 'USD' && acctCurrency != o.CurrencyIsoCode) {
				List<DatedConversionRate> acctCurrencyConversionRates = currencyToFXRates.get(o.CurrencyIsoCode);
                for (DatedConversionRate dcr : acctCurrencyConversionRates) {
                    if (dcr.StartDate <= o.CloseDate && dcr.NextStartDate > o.CloseDate) {
                        Decimal acctCurrencyConversionRate = dcr.ConversionRate;
                        Decimal amtInAcctCurrency = o.Amount_in_USD_Dated__c*acctCurrencyConversionRate;
                        o.Amount_in_Acct_Currency__c = acctCurrency == 'JPY' ? amtInAcctCurrency.setScale(0) : amtInAcctCurrency.setScale(2);
                    }
                }
            }
            o.Recalculate_Converted_Amount__c = false;
            oppsToUpdate.add(o);
        }
        Database.update(oppsToUpdate, false);
    }
    
	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
		System.debug('>>>> Status of batch job recalculating converted opportunity amounts: ' + job.Status);
    }       
}