trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    
    public static List<User> rtrUser = [SELECT Id FROM User WHERE Name = 'Room to Read' LIMIT 1];    
    
    if (Trigger.isBefore) {
        ContactAndLeadTriggerHandler.isBeforeContact(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
        for (Contact c : Trigger.new) {
            c.OwnerId = !rtrUser.isEmpty() ? rtrUser[0].Id : UserInfo.getUserId();
            if ((!String.isBlank(c.MailingStreet) || !String.isBlank(c.MailingCity) || !String.isBlank(c.MailingState) || !String.isBlank(c.MailingPostalCode)) && String.isBlank(c.MailingCountry)) {
                c.addError('If you are going to enter any part of an address for this contact, you must also enter the country');
            }
		}
    }

    else if (Trigger.isAfter) {
        ContactAndLeadTriggerHandler.isAfterContact(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
	}
    
}