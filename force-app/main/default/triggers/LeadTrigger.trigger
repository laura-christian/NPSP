trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    
    public static List<User> rtrUser = [SELECT Id FROM User WHERE Name = 'Room to Read' LIMIT 1];    

    if (Trigger.isBefore) {
        ContactAndLeadTriggerHandler.isBeforeLead(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
        for (Lead l : Trigger.new) {
            l.OwnerId = !rtrUser.isEmpty() ? rtrUser[0].Id : UserInfo.getUserId();  
            if ((!String.isBlank(l.Street) || !String.isBlank(l.City) || !String.isBlank(l.State) || !String.isBlank(l.PostalCode)) && String.isBlank(l.Country)) {
                l.addError('If you are going to enter any part of an address for this lead, you must also enter the country');
            }
        } 
    }
    else if (Trigger.isAfter) {
        ContactAndLeadTriggerHandler.isAfterLead(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
    }    

}