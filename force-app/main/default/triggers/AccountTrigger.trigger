trigger AccountTrigger on Account (before insert, before update, after update) {
    
    if (Trigger.isBefore) {                
        if (Trigger.isInsert) {
            AccountTriggerHandler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AccountTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
        }        
        for (Account a : Trigger.new) {
            if (a.RecordTypeId == '0128b000000XLonAAG' && (((!String.isBlank(a.BillingStreet) || !String.isBlank(a.BillingCity) || !String.isBlank(a.BillingState) || !String.isBlank(a.BillingPostalCode)) && String.isBlank(a.BillingCountry)) || ((!String.isBlank(a.ShippingStreet) || !String.isBlank(a.ShippingCity) || !String.isBlank(a.ShippingState) || !String.isBlank(a.ShippingPostalCode)) && String.isBlank(a.ShippingCountry)))) {
                a.addError('If you are going to enter any part of an address for this account, you must also enter the country');
            }
        }        
    }
    else if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
    } 
    
}