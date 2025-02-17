@isTest
public class BatchDetermineAcctCurrencyTest {

	@isTest(SeeAllData=true)
    public static void testBatchClass() {       
        
		Test.startTest();
        Database.executeBatch(new BatchDetermineAcctCurrency('SELECT Id, CurrencyIsoCode FROM Account WHERE Name = \'Lizzie and John Ridding Household\''), 1);
		Test.stopTest();        
                
    }    
    
}