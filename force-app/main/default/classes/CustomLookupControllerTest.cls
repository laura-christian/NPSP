@isTest
public class CustomLookupControllerTest {
    
    @isTest(SeeAllData=true)
    public static void testFetchRecords() {
        CustomLookupController.fetchRecords('Will', 'Account', 'BillingCountry', 'Type', 'Household');
        CustomLookupController.fetchRecentlyViewed('Account', 'BillingCountry', 'Type', 'Household');
    }

}