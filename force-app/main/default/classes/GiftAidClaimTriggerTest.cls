@isTest
public class GiftAidClaimTriggerTest {
    
    @isTest
    public static void testClaimProcessed() {
        
        Account household = new Account(
        Name = 'Suzie Q Household',
        RecordTypeId = '0128b000000XLomAAG',            
        Type = 'Household',
        BillingStreet = '117 Gloucester Terrace',
        BillingCity = 'London',
        BillingPostalCode = 'W2 3HB',
        BillingCountry = 'United Kingdom');
        insert household;
        
        Account famFoundation = new Account(
        Name = 'Suzie Q Family Foundation',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Family Foundation');
        insert famFoundation;        
        
		Account hmrc = new Account(
        Name = 'HM Revenue & Customs',
        RecordTypeId = '0128b000000XLonAAG',
        Type = 'Organization');
        insert hmrc;
        
        Contact c = new Contact(
        FirstName = 'Suzie',
        LastName = 'Q',
        AccountId = household.Id);
        insert c;
        
        Campaign camp = new Campaign(
        Name = 'Online Donations');
        insert camp;
        
        Opportunity o = new Opportunity(
        Name = 'Donation',
		RecordTypeId = '0128b000000XLooAAG',            
        npsp__Primary_Contact__c = c.Id,
        CurrencyIsoCode = 'GBP',
        Amount = 100,
        StageName = 'Closed Won',
        CloseDate = System.today(),
        CampaignId = camp.Id);
        insert o;
        
        Opportunity majorGift = new Opportunity(
        Name = 'Major Gift',
        RecordTypeId = '0128b000000XLokAAG',
        AccountId = famFoundation.Id,
        Amount = 10000,
        CurrencyIsoCode = 'GBP',
        StageName = 'Closed Won',
        CloseDate = System.today());
        insert majorGift;        
        
        gcga__Gift_Aid_Declaration__c declaration = new gcga__Gift_Aid_Declaration__c(
        gcga__Contact__c = c.Id,
        gcga__Method__c = 'Electronic',
        gcga__Scope__c = 'One-off',
        gcga__Declaration_Date__c = System.today(),
        gcga__Donation__c = o.Id);
        insert declaration;
        
        gcga__Gift_Aid_Declaration__c declaration2 = new gcga__Gift_Aid_Declaration__c(
        gcga__Contact__c = c.Id,
        gcga__Method__c = 'Electronic',
        gcga__Scope__c = 'One-off',
        gcga__Declaration_Date__c = System.today(),
        gcga__Donation__c = majorGift.Id);
        insert declaration2;        
        
        
        o.gcga__Gift_Aid_Declaration__c = declaration.Id;
        update o;
        majorGift.gcga__Gift_Aid_Declaration__c = declaration2.Id;
        update majorGift;        
        
        gcga__Gift_Aid_Claim__c claim = new gcga__Gift_Aid_Claim__c(
        gcga__Accounting_Period__c = '12/31',
        gcga__Claim_Address__c = 'Bracken House, 1 Friday Street',
        gcga__Claim_Contact__c = 'Dean Chan',
        gcga__Claim_Contact_Phone__c = '07980 765098',
        gcga__Claim_Stage__c = 'Draft',
        gcga__Date_of_Claim__c = System.today(),
        gcga__Date_of_Reclaim__c = System.today(),
        gcga__HMRC_Reference__c = 'XR73286',
        gcga__Declaration__c = true);
        insert claim;
        
        o.gcga__Gift_Aid_Claim__c = claim.Id;
        update o;
        majorGift.gcga__Gift_Aid_Claim__c = claim.Id;
        update majorGift;
        
        Test.startTest();
        claim.gcga__Claim_Status__c = 'Completed';
        claim.gcga__Claim_Stage__c = 'Reclaimed';
        update claim;
        Test.stopTest();
        
    }

}