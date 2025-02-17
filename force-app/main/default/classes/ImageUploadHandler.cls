public class ImageUploadHandler { 
    
    @AuraEnabled(cacheable=true)
    public static String fetchPhotoURL(Id recordId) {
        
        String photoURL = '';
        
        if (recordId.getSObjectType().getDescribe().getName() == 'Contact') {
			Contact c = [SELECT Id, Name, Photo_URL__c FROM Contact WHERE Id = :recordId LIMIT 1]; 
            photoURL = c.Photo_URL__c;
        }        
        else if (recordId.getSObjectType().getDescribe().getName() == 'Lead') {
            Lead l = [SELECT Id, Name, Photo_URL__c FROM Lead WHERE Id = :recordId LIMIT 1]; 
            photoURL = l.Photo_URL__c;
        }        
        return photoURL;
    }
    
    
    @AuraEnabled
    public static void generateLink(Id recordId, Id contentVersionId) {

		Boolean isContact = false;
		Boolean isLead = false;
        Contact c;
        Lead l;
        String photoName = '';
        
        if (recordId.getSObjectType().getDescribe().getName() == 'Contact') {
            isContact = true;
			c = [SELECT Id, Name FROM Contact WHERE Id = :recordId LIMIT 1]; 
            photoName = c.Name + ' Profile Photo';
        }        
        else if (recordId.getSObjectType().getDescribe().getName() == 'Lead') {
            isLead = true;
            l = [SELECT Id, Name FROM Lead WHERE Id = :recordId LIMIT 1]; 
            photoName = l.Name + ' Profile Photo';
        }
        
        ContentVersion cv = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion WHERE Id = :contentVersionId];
        
        Document doc = new Document(
            Name = photoName,
            IsPublic = true,
            ContentType = 'image/jpeg',
            Type = 'jpeg',
            Body = cv.VersionData,
            FolderId = [SELECT Id FROM Folder WHERE Name = 'Profile Photos'].Id
        );                        
        insert doc;
        
        if (isContact) {
            c.Public_Photo_Link__c = 'https://roomtoread3.file.force.com/servlet/servlet.ImageServer?id=' + doc.Id + '&oid=00D8b00000168vo';        
            c.Photo_URL__c = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB240BY180&versionId=' + cv.Id +
                '&operationContext=CHATTER&contentId=' + cv.ContentDocumentId;        
            update c;            
        }     
        else if (isLead) {
            l.Public_Photo_Link__c = 'https://roomtoread3.file.force.com/servlet/servlet.ImageServer?id=' + doc.Id + '&oid=00D8b00000168vo';
            l.Photo_URL__c = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB240BY180&versionId=' + cv.Id +
                '&operationContext=CHATTER&contentId=' + cv.ContentDocumentId;
            update l;
        }        
    }

	@AuraEnabled
    public static void deletePhoto(Id recordId) {
        
        Id docId;
        Id contentDocId;
        
        if (recordId.getSObjectType().getDescribe().getName() == 'Contact') {
			Contact c = [SELECT Id, Name, Photo_URL__c, Public_Photo_Link__c FROM Contact WHERE Id = :recordId LIMIT 1]; 
        	docId = c.Public_Photo_Link__c.substringBetween('?id=', '&oid');
        	contentDocId = c.Photo_URL__c.substringAfter('contentId=');
            c.Photo_URL__c = null;
            c.Public_Photo_Link__c = null;
            update c;
        }        
        else if (recordId.getSObjectType().getDescribe().getName() == 'Lead') {
            Lead l = [SELECT Id, Name, Photo_URL__c, Public_Photo_Link__c FROM Lead WHERE Id = :recordId LIMIT 1]; 
        	docId = l.Public_Photo_Link__c.substringBetween('?id=', '&oid');
        	contentDocId = l.Photo_URL__c.substringAfter('contentId=');
            l.Photo_URL__c = null;
            l.Public_Photo_Link__c = null;
            update l;
        }             
        
        delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocId];
        delete [SELECT Id FROM Document WHERE Id = :docId];
        
    }    
 }