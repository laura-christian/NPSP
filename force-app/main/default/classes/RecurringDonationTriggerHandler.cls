public class RecurringDonationTriggerHandler {

    public static List<User> rtrUser = [SELECT Id FROM User WHERE Name = 'Room to Read' LIMIT 1];	
    public static Map<String, String> currencySymbols = new Map<String, String>{
        'USD' => '$',
        'AUD' => 'A$',
        'CAD' => 'C$',
        'CHF' => 'CHF',
        'EUR' => '€',
        'GBP' => '£',
        'HKD' => 'HK$',
        'INR' => '₹',
        'JPY' => '¥',
        'SGD' => 'S$'
    };    
    
    public static void beforeInsertOrUpdate(List<npe03__Recurring_Donation__c> recurringDonations, Boolean isInsert) {

        if (isInsert) {
            for (npe03__Recurring_Donation__c recurringDonation : recurringDonations) {
                recurringDonation.OwnerId = !rtrUser.isEmpty() ? rtrUser[0].Id : UserInfo.getUserId();
            }
            Set<Id> acctIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            for (npe03__Recurring_Donation__c recurringDonation : recurringDonations) {
                acctIds.add(recurringDonation.npe03__Organization__c);
                contactIds.add(recurringDonation.npe03__Contact__c);
            }
            Map<Id, Account> acctsMap = new Map<Id, Account>([SELECT Id, Name FROM Account
                                                              WHERE Id IN :acctIds]);            
            Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, AccountId, Name FROM Contact WHERE Id IN :contactIds]);
            for (npe03__Recurring_Donation__c recurringDonation : recurringDonations) {
                String interval = !String.isBlank(recurringDonation.npe03__Installment_Period__c) ? recurringDonation.npe03__Installment_Period__c : 'Monthly';
                if (recurringDonation.npe03__Installment_Period__c == 'Yearly') {
                    interval = 'Annually';
                }
                if (recurringDonation.npsp__InstallmentFrequency__c == 3 && recurringDonation.npe03__Installment_Period__c == 'Monthly') {
                    interval = 'Quarterly';
                }
                else if (recurringDonation.npsp__InstallmentFrequency__c == 6 && recurringDonation.npe03__Installment_Period__c == 'Monthly') {
                    interval = 'Semi-Annually';
                }
                else if (recurringDonation.npsp__InstallmentFrequency__c == 2 && recurringDonation.npe03__Installment_Period__c == 'Weekly') {
                    interval = 'Bi-Weekly';
                } 
                else if (recurringDonation.npe03__Installment_Period__c == '1st and 15th') {
                    interval = 'Semi-Monthly';
                }
                String currencySymbol = currencySymbols.containsKey(recurringDonation.CurrencyIsoCode) ? currencySymbols.get(recurringDonation.CurrencyIsoCode) : '$';
                Decimal amount = recurringDonation.CurrencyIsoCode == 'JPY' ? recurringDonation.npe03__Amount__c.setScale(0) : recurringDonation.npe03__Amount__c.setScale(2);
                String donorName; 
                if (!String.isBlank(recurringDonation.npe03__Contact__c) && contactsMap.containsKey(recurringDonation.npe03__Contact__c)) {
                    donorName = contactsMap.get(recurringDonation.npe03__Contact__c).Name;
                }
                else if (!String.isBlank(recurringDonation.npe03__Organization__c) && acctsMap.containsKey(recurringDonation.npe03__Organization__c)) {
                    donorName = acctsMap.get(recurringDonation.npe03__Organization__c).Name;
                }
                recurringDonation.Name = donorName + ': Recurring Gift ' + String.valueOf(recurringDonation.npe03__Date_Established__c.year()) + ' ' + currencySymbol + String.valueOf(amount) + ' ' + interval;
            }            
        }    
    }
}