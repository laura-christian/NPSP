public class ScheduleOppTerrAssignment implements Schedulable {

    public void execute(SchedulableContext sc) {
		Database.executeBatch(new BatchAssignTerritoriesToOpps(), 20);	        
    }    
    
}