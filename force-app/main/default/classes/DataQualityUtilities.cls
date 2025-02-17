public class DataQualityUtilities {

    public static String capitalizeFirstLetter(String s) {
        if (s==null) {return s;}
        String[] words = s.split('\\s',0);
        List<String> capitalizedWords = new List<String>();
        for (String w: words) {
        	//do not capitalize "and" or "of"
            if (w=='and') {
                capitalizedWords.add('and');
            }
            else if (w == 'of') {
                capitalizedWords.add('of');
            }
            else {
                w=capitalizeWord(w);
                capitalizedWords.add(w);
            }
        }
        return String.join(capitalizedWords, ' ');
    } 
    
    public static String capitalizeWord(String s) {
        String capitalized=s;
        if (s.length()>0)
            capitalized = s.substring(0,1).toUpperCase() + (s.length()>1?s.substring(1).toLowerCase():'');
        return capitalized;    
    }
    
    public static String formatPhoneNumber(String phoneNumber) {
        // Strips all non-numeric characters from string
        String strippedPhoneNumber = phoneNumber.replaceAll('[^0-9]', '');
		System.debug(strippedPhoneNumber);
        String formattedPhoneNumber;
        if (strippedPhoneNumber.length() == 10 && strippedPhoneNumber.substring(0,1) != '0') {
			// Reformats phone number as '(000) 000-0000'
            formattedPhoneNumber = '(' + strippedPhoneNumber.substring(0,3) + ') ' + strippedPhoneNumber.substring(3,6) + '-' + strippedPhoneNumber.substring(6);            
        }
        // If phone number is not 10 digits or starts with a zero, may be international; should be returned in original format
        else if (strippedPhoneNumber.length() != 10 || (strippedPhoneNumber.length() == 10 && strippedPhoneNumber.substring(0,1) == '0')) {formattedPhoneNumber = phoneNumber;}
        System.debug(formattedPhoneNumber);
        return formattedPhoneNumber;
    }
    
}