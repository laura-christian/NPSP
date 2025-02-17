@isTest
public class ImageUploadHandlerTest {
    
    @isTest
    public static void testImageUploadHandlerContact() {
        
        Account a = new Account(
        Name = 'Household',
		RecordTypeId = '0128b000000XLomAAG',             
        Type = 'Household');
        insert a;
        
        Contact c = new Contact(
        AccountId = a.Id,
        Salutation = 'Ms.',
        FirstName = 'Suzie',
        LastName = 'Q',
        Email = 'suzie.q@myemail.com');
        insert c;
        
        Blob photoBlob = Blob.valueOf('Photo for test class');

		ContentVersion cv = new ContentVersion(
        Title = 'Profile Photo',
        PathOnClient = 'Photo.jpg',
        VersionData = photoBlob);
		insert cv;

		ImageUploadHandler.generateLink(c.Id, cv.Id);
        ImageUploadHandler.deletePhoto(c.Id);
		        
    }
    
    @isTest
    public static void testImageUploadHandlerLead() {
        
		Lead l = new Lead(
        FirstName = 'Suzie',
        LastName = 'Q',
        Company = 'Household',
        Email = 'suzie.q@myemail.com');
        insert l;
        
        Blob photoBlob = Blob.valueOf('Photo for test class');

		ContentVersion cv = new ContentVersion(
        Title = 'Profile Photo',
        PathOnClient = 'Photo.jpg',
        VersionData = photoBlob);
		insert cv;

		ImageUploadHandler.generateLink(l.Id, cv.Id);
        ImageUploadHandler.deletePhoto(l.Id);
		        
    }    

}