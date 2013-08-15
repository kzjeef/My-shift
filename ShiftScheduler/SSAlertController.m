//  SSAlertController.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSAlertController.h"
#import "OneJob.h"
#import "NSDateAdditions.h"
#import "SSDefaultConfigName.h"


#define TIME_STR_ALARM_BEFORE_HOURS NSLocalizedString(@"will start in %d Hour", "will start in %d Hour")
#define TIME_STR_ALARM_BEFORE_MINITES NSLocalizedString(@"will start in %d Minutes", "will start in %d Minutes")
#define TIME_STR_ALARM_BEFORE_NOW NSLocalizedString(@"is start now", "is start now")
#define TIME_STR_ALARM_OFF_HOURS NSLocalizedString(@"will off in %d Hour", "will start in %d Hour")
#define TIME_STR_ALARM_OFF_MINITES NSLocalizedString(@"will off in %d Minutes", "will start in %d Minutes")
#define TIME_STR_ALARM_OFF_NOW NSLocalizedString(@"is off now", "is start now")

#define ALERT_USER_ENTER_APP NSLocalizedString(@"The alarm you setup in app is going to out of date, please enter the app to active the alarm again (only enter and exit is enough)", "alarm out of date notify body")


#define JOB_CACHE_INDEFITER @"JobNameCache"
@implementation SSAlertController

@synthesize managedcontext, jobArray, frc;

- (id) initWithManagedContext: (NSManagedObjectContext *)thecontext
{
    self = [super init];

    self.managedcontext = thecontext;

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"OneJob"
                                              inManagedObjectContext: self.managedcontext];
    
    farestAlarmDate = [NSDate date];
    [request setEntity:entity];
    request.sortDescriptors = @[[NSSortDescriptor
                                 sortDescriptorWithKey: @"jobName"
                                 ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"jobEnable == YES"];
    // we want monitor all job 's change, if one change from disable
    // to enable, we should know this.
    request.fetchBatchSize = 20;

    self.frc = [[NSFetchedResultsController alloc]
                initWithFetchRequest:request
                   managedObjectContext:self.managedcontext
                  sectionNameKeyPath:nil cacheName:JOB_CACHE_INDEFITER];

    NSError *error = 0;
    self.frc = frc;
    self.frc.delegate = self;
    [self.frc performFetch:&error];
    if (error)
        NSLog(@"fetch request error:%@", error.userInfo);

    alert_sound_url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                              pathForResource:@"notify" ofType:@"caf"]];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(managedContextDataChanged:)
                name:NSManagedObjectContextDidSaveNotification
              object:self.managedcontext];
    [dnc addObserver:self selector:@selector(alarmSoundChange:)
                name:@"ALARM_SOUND_CHANGED" object:nil];

    return self;
}

- (void) managedContextDataChanged:(NSNotification *) saveNotifaction
{
    NSError *error;
    [self.frc performFetch:&error];
    if (error)
        NSLog(@"SSAlertController: fetch error: %@", [error userInfo]);

    [self setupAlarm:YES];
}

- (void) alarmSoundChange:(NSNotification *) noti
{
    NSLog(@"resetup alarm because the alarm sound changed");
    [self setupAlarm:YES];
}

- (NSArray *)jobArray
{
    return self.frc.fetchedObjects;
}

- (BOOL) shouldAlertWithSound
{
    return [[NSUserDefaults standardUserDefaults]
            boolForKey:USER_CONFIG_ENABLE_ALERT_SOUND];
}

- (BOOL) shouldUseSystemSound
{
    return [[NSUserDefaults standardUserDefaults]
            boolForKey:USER_CONFIG_USE_SYS_DEFAULT_ALERT_SOUND];
}

static void alertSoundPlayingCallback( SystemSoundID sound_id, void *user_data)
{
    AudioServicesDisposeSystemSoundID(sound_id);
}

- (void) playAlarmSound
{
    AudioServicesCreateSystemSoundID ((__bridge_retained CFURLRef)alert_sound_url,
                                      &alertSoundID);
    AudioServicesAddSystemSoundCompletion(alertSoundID,
                                          NULL, NULL,
                                          alertSoundPlayingCallback,
                                          NULL);

    AudioServicesPlayAlertSound(alertSoundID);
}

- (BOOL)scheduleNotificationWithItem:(NSDate *)firetime
                       withDaysLater:(int)daysInFurther
                            interval:(int)timeIntervalBefore
                           alarmBody: (NSString *) alarmBody
                    alarmActionTitle: (NSString *) actionTitle
                           TimeAfter: (NSTimeInterval) after
                                 job: (OneJob *)job
                         isBeforeOff: (boolean_t) isBeforeOff
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSCalendar *currentCal = [NSCalendar currentCalendar];
    NSDate *fireDateEndWork;
    NSDate *fireDateBegingWork;

    if (job.jobEnable.boolValue == NO)
        return NO;

    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    formatter.timeZone = [NSTimeZone defaultTimeZone];

    // firetime = everyday work start time
    // offset = firetime  - firetime's beginning.
    // fireDate = today's beginning + offset
    // firedate move to days later.

    NSTimeInterval offset = [firetime timeIntervalSinceDate:
                                          [firetime cc_dateByMovingToBeginningOfDayWithCalender:currentCal]];

    fireDateBegingWork = [[[NSDate date] cc_dateByMovingToBeginningOfDay]
                             dateByAddingTimeInterval:offset];

    fireDateBegingWork = [fireDateBegingWork
                           cc_dateByMovingToNextOrBackwardsFewDays:daysInFurther
                                                      withCalender:currentCal];

    BOOL isWorkDayOfBeginAlarm = [job isDayWorkingDay:fireDateBegingWork];

    // After add this length,
    // the fireDate become the end of that's day's work.
    fireDateEndWork = [[fireDateBegingWork dateByAddingTimeInterval:after] copy];

    // Note:
    // If the start time was 0:00, the days later should be -1,
    // like, alarm 1 hour before 0:00 of Jul.2, should be alarm at
    // Jul.1 's 23:00

    NSDate *finalFireDate;
    if (isBeforeOff)
        finalFireDate = fireDateEndWork;
    else
        finalFireDate = fireDateBegingWork;

    finalFireDate = [finalFireDate dateByAddingTimeInterval: -timeIntervalBefore];

    if ([finalFireDate timeIntervalSinceDate:[NSDate date]] < 0) {
        NSLog(@"drop a notify since it out of date: when:%@ now:%@",
              [formatter stringFromDate:finalFireDate],
              [formatter stringFromDate:[NSDate date]]);
        return NO;
    }

    if (!isWorkDayOfBeginAlarm) {
        NSLog(@"drop notify: begin:%d job: %@ working day: %@",
              isBeforeOff,
              job.jobName,
              [formatter stringFromDate:finalFireDate]);
        return NO;
    }

    NSString *alarmSoundFile = [[NSUserDefaults standardUserDefaults] stringForKey:USER_CONFIG_APP_DEFAULT_ALERT_SOUND];
    
    if ([finalFireDate timeIntervalSinceDate:farestAlarmDate] > 0)
        farestAlarmDate = finalFireDate;

    NSLog(@"setup local notify job: %@ firedate: %@ sound:%@ badge: %d",
          job.jobName,
          [formatter stringFromDate:finalFireDate], alarmSoundFile, badgeNumber + 1);

    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return NO;
    localNotif.fireDate = finalFireDate;
    localNotif.timeZone = [NSTimeZone systemTimeZone];
    localNotif.hasAction = YES;
    localNotif.alertBody = alarmBody;
    localNotif.alertAction = actionTitle;

    if ([self shouldAlertWithSound]) {
        localNotif.soundName = alarmSoundFile;
    }
    localNotif.applicationIconBadgeNumber = ++badgeNumber;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    return YES;
}


- (void) setupWarnningUserNotifyForDate: (NSDate *) date
{
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    localNotif.fireDate = date;
    localNotif.timeZone = [NSTimeZone systemTimeZone];
    localNotif.hasAction = YES;
    localNotif.alertBody = ALERT_USER_ENTER_APP;
    localNotif.alertAction = NSLocalizedString(@"I Know", "I Know");

    if ([self shouldAlertWithSound])
        localNotif.soundName = UILocalNotificationDefaultSoundName;

    localNotif.applicationIconBadgeNumber = 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}


- (void) clearBadgeNumber
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;

    badgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber;
}


- (int) setupAlarmForJob: (OneJob *) job daysLater:(int) daysLater
{
    NSString *timestr;
    NSString *defaultActionTitle = NSLocalizedString(@"I Know", "I Know");
    int alarmCount = 0;
    BOOL ret;

    if (job.jobRemindBeforeWork && job.jobRemindBeforeWork.intValue != -1) {
        // user have setup alarm for this shift.
        // setup for Work Alarm

        if (job.jobRemindBeforeWork.intValue > 60*60)
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_BEFORE_HOURS,
                                job.jobRemindBeforeWork.intValue / 60 / 60];
        else
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_BEFORE_MINITES,
                                job.jobRemindBeforeWork.intValue / 60];
        if (job.jobRemindBeforeWork.intValue == 0)
            timestr = TIME_STR_ALARM_BEFORE_NOW;
        NSString *workRemindString = [NSString stringWithFormat:@"%@ %@.", job.jobName, timestr];


        ret = [self scheduleNotificationWithItem:[job getJobEverydayStartTime]
                                   withDaysLater:daysLater
                                        interval:job.jobRemindBeforeWork.intValue
                                       alarmBody:workRemindString
                                alarmActionTitle:defaultActionTitle
                                       TimeAfter:0
                                             job:job
                                     isBeforeOff:NO];
        if (ret) alarmCount ++;
    }

    if (job.jobRemindBeforeOff && job.jobRemindBeforeOff.intValue != -1) {


        if (job.jobRemindBeforeOff.intValue > 60*60)
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_OFF_HOURS,
                                job.jobRemindBeforeOff.intValue / 60 / 60];
        else
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_OFF_MINITES,
                                job.jobRemindBeforeOff.intValue / 60];

        if (job.jobRemindBeforeOff.intValue == 0)
            timestr = TIME_STR_ALARM_OFF_NOW;
        NSString *offRemindString = [NSString stringWithFormat:@"%@ %@.",
                                              job.jobName, timestr];

        ret = [self scheduleNotificationWithItem:[job getJobEverydayStartTime]
                                   withDaysLater:daysLater
                                        interval:job.jobRemindBeforeOff.intValue
                                       alarmBody:offRemindString
                                alarmActionTitle:defaultActionTitle
                                       TimeAfter:[job getJobEveryDayLengthSec].intValue
                                             job:job
                                     isBeforeOff:YES];
        if (ret) alarmCount += 1;
    }
    return alarmCount;
}



- (void) setupAlarm: (BOOL)isShort
{

    // clear the alarm set before.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    badgeNumber = 0;

#define MAX_NOTIFY_COUNT 24
    if (self.jobArray.count <= 0)
        return;

    if (isShort) {
        // if short, only update today's
        for (OneJob *j in self.jobArray) {
            [self setupAlarmForJob:j daysLater:0];
            [self setupAlarmForJob:j daysLater:1];
            [self setupAlarmForJob:j daysLater:2];

        }
    } else {
        int max_notify = MIN(self.jobArray.count * 7, MAX_NOTIFY_COUNT);
        int used = 0;
        int days = 0;
        // try our best to eat all the notify
        // and only set 7 days laters for each job.
        for (int i = 0; i < max_notify; i++) {
            if (used > max_notify)
                break;
            days = i;
            for (OneJob *j in self.jobArray)
                used += [self setupAlarmForJob:j daysLater:i];
        }

        // at the date by days - 1, setup an alarm for user to enter the app
        // to active the alarm.

        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        formatter.timeZone = [NSTimeZone defaultTimeZone];
        
        NSDate *d = [farestAlarmDate cc_dateByMovingToNextOrBackwardsFewDays:-1 withCalender:[NSCalendar currentCalendar]];

        NSLog(@"schedule a alerm at :%@", [formatter stringFromDate:d]);
        if([d timeIntervalSinceDate:[NSDate date]] > 0)
            [self setupWarnningUserNotifyForDate:d];
    }
}

#pragma mark - FetchedResultController

/**
 Delegate methods of NSFetchedResultsController to respond to
 additions, removals and so on.
 */

// - (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//      // The fetch controller is about to start sending change
//      // notifications, so prepare the table view for updates.
// }


// - (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
// }

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
        // The fetch controller has sent all current change
        // notifications, so tell the table view to process all
        // updates.
    [NSFetchedResultsController deleteCacheWithName:JOB_CACHE_INDEFITER];
    self.jobArray = nil;

}

@end