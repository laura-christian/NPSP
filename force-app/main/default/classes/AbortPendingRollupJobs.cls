public class AbortPendingRollupJobs {
    
    @InvocableMethod(label='Abort Rollup Jobs' description='Aborts customizable rollup jobs in case they have inadvertently scheduled via NPSP settings')
    public static void abortRollupJobs() {
        List<CronTrigger> cronJobs = [SELECT Id FROM CronTrigger WHERE State = 'WAITING' AND CronJobDetail.Name LIKE 'NPSP 0%' AND (NOT CronJobDetail.Name LIKE 'NPSP 05%') AND (NOT CronJobDetail.Name LIKE 'NPSP 06%')];
        for (CronTrigger job : cronJobs) {System.abortJob(job.Id);}
    }
}