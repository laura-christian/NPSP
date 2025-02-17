public class ScheduleSecondEmailAddressValidation implements Schedulable {
    
    List<String> suggestedFixes;
    
    public void execute(SchedulableContext sc) {
        validateSuggestedFixes(suggestedFixes);
		System.abortJob(sc.getTriggerId());        
    }
    
    public void validateSuggestedFixes(List<String> typoFixSuggestions) {
        Database.executeBatch(new BatchValidateEmails(typoFixSuggestions));
    }
    
    public ScheduleSecondEmailAddressValidation(List<String> suggestedFixes) {
		this.suggestedFixes = suggestedFixes;	
    }

}