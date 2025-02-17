public class GivingSummary {

    //Wrapper class for lightning web component "Giving Summary in USD" (dated conversion rates)
    @AuraEnabled public Decimal totalCredits { get; set; }
    @AuraEnabled public Decimal creditsThisYear { get; set; }
    @AuraEnabled public Decimal creditsLastYear { get; set; }
    @AuraEnabled public Decimal creditsTwoYearsAgo { get; set; }
    @AuraEnabled public Decimal totalGifts { get; set; }
    @AuraEnabled public Decimal giftsThisYear { get; set; }
    @AuraEnabled public Decimal giftsLastYear { get; set; }
    @AuraEnabled public Decimal giftsTwoYearsAgo { get; set; }
    @AuraEnabled public Decimal totalSoftCredits { get; set; }
    @AuraEnabled public Decimal totalP2PSoftCredits { get; set; }
    @AuraEnabled public Decimal softCreditsThisYear { get; set; }
    @AuraEnabled public Decimal softCreditsLastYear { get; set; }
    @AuraEnabled public Decimal softCreditsTwoYearsAgo { get; set; }
    
    public GivingSummary(Decimal totalCredits, Decimal creditsThisYear, Decimal creditsLastYear, Decimal creditsTwoYearsAgo, Decimal totalGifts, Decimal giftsThisYear, Decimal giftsLastYear, Decimal giftsTwoYearsAgo,
                         Decimal totalSoftCredits, Decimal totalP2PSoftCredits, Decimal softCreditsThisYear, Decimal softCreditsLastYear, Decimal softCreditsTwoYearsAgo) {
                             this.totalCredits = totalCredits;
                             this.creditsThisYear = creditsThisYear;
                             this.creditsLastYear = creditsLastYear;
                             this.creditsTwoYearsAgo = creditsTwoYearsAgo;
                             this.totalGifts = totalGifts;
                             this.giftsThisYear = giftsThisYear;
                             this.giftsLastYear = giftsLastYear;
                             this.giftsTwoYearsAgo = giftsTwoYearsAgo;
                             this.totalSoftCredits = totalSoftCredits;
                             this.totalP2PSoftCredits = totalP2PSoftCredits;
                             this.softCreditsThisYear = softCreditsThisYear;
                             this.softCreditsLastYear = softCreditsLastYear;
                             this.softCreditsTwoYearsAgo = softCreditsTwoYearsAgo;      
                         }
}