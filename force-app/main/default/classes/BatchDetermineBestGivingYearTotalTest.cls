@isTest
public class BatchDetermineBestGivingYearTotalTest {

    @isTest(SeeAllData=true)
    public static void testBatchClass() {
        
        List<Account> ballsWax = [SELECT Id FROM Account WHERE Id = '0018b00002BTGA7AAP'];
		
        Test.startTest();
        Database.executeBatch(new BatchDetermineBestGivingYearTotal(ballsWax), 1);
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    public static void testSchedulableClass() {
    
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second()+1);
        
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        ScheduleBatchDetermineBestGivingYear schedulable = new ScheduleBatchDetermineBestGivingYear(); 
        System.schedule('Scheduled Job', nextFireTime, schedulable);        
        
    }
    
}