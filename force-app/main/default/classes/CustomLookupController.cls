public with sharing class CustomLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchRecords(String searchKey, String sObjectApiName, String otherFieldApiName, String filterField, String filterValue) {    
        List<ResultWrapper> resultsList = new List<ResultWrapper>();
        String sWildCardText = '%' + searchKey + '%';
        String otherField = !String.isBlank(otherFieldApiName) ? ', ' + otherFieldApiName : '';
        String sQuery = 'SELECT Id, Name' + otherField + ' FROM ' + sObjectApiName + ' WHERE Name LIKE :sWildCardText ';
        if (!String.isBlank(filterField) && !String.isBlank(filterValue)){
			sQuery += 'AND ' + filterField + ' = \'' + filterValue + '\' ';
        }        
        sQuery += 'ORDER BY CreatedDate LIMIT 5';
        System.debug(sQuery);
        for (sObject obj: Database.query(sQuery)) {
            ResultWrapper wrappedResult = new ResultWrapper();
            wrappedResult.name = (String)obj.get('Name');
            wrappedResult.detail = (String)obj.get(otherFieldApiName);
            wrappedResult.id = (String)obj.get('Id');
            resultsList.add(wrappedResult);
        }
        return resultsList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchRecentlyViewed(String sObjectApiName, String otherFieldApiName, String filterField, String filterValue) {    
        List<ResultWrapper> resultsList = new List<ResultWrapper> ();
        String otherField = !String.isBlank(otherFieldApiName) ? ', ' + otherFieldApiName : '';
        String sQuery = 'SELECT Id, Name' + otherField + ' FROM ' + sObjectApiName + ' WHERE LastViewedDate != null ';
        if (!String.isBlank(filterField) && !String.isBlank(filterValue)){
			sQuery += 'AND ' + filterField + ' = \'' + filterValue + '\' ';
        }        
        sQuery += 'ORDER BY LastViewedDate DESC LIMIT 5';        
        for (sObject obj: Database.query(sQuery)) {
            ResultWrapper wrappedResult = new ResultWrapper();
            wrappedResult.name = (String)obj.get('Name');
            wrappedResult.detail = (String)obj.get(otherFieldApiName);
            wrappedResult.id = (String)obj.get('Id');
            resultsList.add(wrappedResult);
        }
        return resultsList;
    }
    
    
    public class ResultWrapper{
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String detail {get; set;}
        @AuraEnabled public String id {get; set;}
    }    

}