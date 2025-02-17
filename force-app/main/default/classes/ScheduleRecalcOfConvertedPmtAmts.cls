public class ScheduleRecalcOfConvertedPmtAmts implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Datetime scheduledStart = Test.isRunningTest() ? Datetime.newInstance(2022, 12, 2) : System.now();
        Datetime oneDayAgo = scheduledStart - 1;
        List<DatedConversionRate> DCRs = [SELECT IsoCode, StartDate, NextStartDate 
										  FROM DatedConversionRate
										  WHERE IsoCode!='USD' AND LastModifiedDate < :scheduledStart AND 
                                          LastModifiedDate >= :oneDayAgo];
        if (!DCRs.isEmpty()) {
            if (!Test.isRunningTest()) {Database.executeBatch(new BatchRecalcConvertedPmtAmts(DCRs), 20);}
        }
    }

}