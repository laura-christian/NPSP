@isTest
public class DataQualityUtilitiesTest {
    
    @isTest
    public static void testTitleCase() {
        
      	String title = 'wallace and grommit OF WEST YORKSHIRE';
        String titleCaseString = DataQualityUtilities.capitalizeFirstLetter(title);
        
        System.assertEquals('Wallace and Grommit of West Yorkshire', titleCaseString);
        
    }
    
    @isTest
    public static void testUSPhoneNumberFormatting() {
        
        String phoneNum1 = '+ 1 999.999.9999';
        String phoneNum2 = '999/999-9999';
        String phoneNum3 = '(098) 765-4321';
        
        DataQualityUtilities.formatPhoneNumber(phoneNum1);
        DataQualityUtilities.formatPhoneNumber(phoneNum2);
        DataQualityUtilities.formatPhoneNumber(phoneNum3);
    }

}