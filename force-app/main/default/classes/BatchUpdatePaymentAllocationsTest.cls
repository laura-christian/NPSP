@isTest
public class BatchUpdatePaymentAllocationsTest {

    @isTest(SeeAllData=true)
    public static void testBatchUpdatePaymentAllocation() {
        Test.startTest();
        Database.executeBatch(new BatchUpdatePaymentAllocations(),100);
        Test.stopTest();
    }
    
}