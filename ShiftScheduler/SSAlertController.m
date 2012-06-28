//
//  SSAlertController.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSAlertController.h"
#import "OneJob.h"
#import "NSDateAdditions.h"

#define TIME_STR_ALARM_BEFORE_HOURS NSLocalizedString(@"will start in %d Hour", "will start in %d Hour")
#define TIME_STR_ALARM_BEFORE_MINITES NSLocalizedString(@"will start in %d Minutes", "will start in %d Minutes")
#define TIME_STR_ALARM_BEFORE_NOW NSLocalizedString(@"is start now", "is start now")
#define TIME_STR_ALARM_OFF_HOURS NSLocalizedString(@"will off in %d Hour", "will start in %d Hour")
#define TIME_STR_ALARM_OFF_MINITES NSLocalizedString(@"will off in %d Minutes", "will start in %d Minutes")
#define TIME_STR_ALARM_OFF_NOW NSLocalizedString(@"is off now", "is start now")

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
    [request setEntity:entity];
    request.sortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor
							    sortDescriptorWithKey: @"jobName"
									ascending:YES]];
    request.predicate = nil;
    // we want monitor all job 's change, if one change from disable
    // to enable, we should know this.
    request.fetchBatchSize = 20;
    
    self.frc = [[NSFetchedResultsController alloc]
                initWithFetchRequest:request managedObjectContext:self.managedcontext sectionNameKeyPath:nil cacheName:JOB_CACHE_INDEFITER];
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

    return self;
}

- (void) managedContextDataChanged:(NSNotification *) saveNotifaction
{
    [self setupAlarm:YES];   
}

- (NSArray *)jobArray
{
    if (jobArray == nil) {
        NSMutableArray *a = [[NSMutableArray alloc] init];
        NSError *error;
        [self.frc performFetch:&error];
        for (OneJob *j in self.frc.fetchedObjects)
            if ([j.jobEnable isEqualToNumber:[NSNumber numberWithBool:YES]])
                [a addObject:j];
        jobArray = a;
    }
    return jobArray;
}

- (BOOL) shouldAlertWithSound
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enableAlertSound"];
}

- (BOOL) shouldUseSystemSound
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"systemDefalutAlertSound"];
}

static void alertSoundPlayingCallback( SystemSoundID sound_id, void *user_data)
{
    AudioServicesDisposeSystemSoundID(sound_id);
}

- (void) playAlarmSound
{
    AudioServicesCreateSystemSoundID ((__bridge_retained CFURLRef)alert_sound_url,                                          &alertSoundID);
    AudioServicesAddSystemSoundCompletion(alertSoundID, NULL, NULL, alertSoundPlayingCallback, NULL);
    
    AudioServicesPlayAlertSound(alertSoundID);
}


- (BOOL)scheduleNotificationWithItem:(NSDate *)firetime withDaysLater:(int)daysInFurther 
                            interval:(int)timeIntervalBefore 
                           alarmBody: (NSString *) alarmBody 
                    alarmActionTitle: (NSString *) actionTitle
                           TimeAfter: (NSTimeInterval) after
                                 job: (OneJob *)job
                            isOffDay: (boolean_t) isOffday
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSCalendar *currentCal = [NSCalendar currentCalendar];
    
   [formatter setTimeStyle:NSDateFormatterMediumStyle];
   [formatter setDateStyle:NSDateFormatterMediumStyle];

   formatter.timeZone = [NSTimeZone defaultTimeZone];
    
    NSTimeInterval offset = [firetime timeIntervalSinceDate:[firetime cc_dateByMovingToBeginningOfDayWithCalender:currentCal]];
    
    NSDate *fireDate = [[[NSDate date] cc_dateByMovingToBeginningOfDay] dateByAddingTimeInterval:offset];
    
    fireDate = [fireDate cc_dateByMovingToNextOrBackwardsFewDays:daysInFurther withCalender:currentCal];
    
    NSDate *firedayWorkDate = [fireDate copy];
    
    // 工作时长， 这里加上, 为了解决隔夜工作的问题。
    fireDate = [fireDate dateByAddingTimeInterval:after];

    // 多少秒之前
    fireDate = [fireDate dateByAddingTimeInterval:-timeIntervalBefore];
    
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return NO;
    
    if (job.jobEnable.boolValue == NO)
        return NO;

    if ([fireDate timeIntervalSinceDate:[NSDate date]] < 0) {
        NSLog(@"drop a notify since it out of date: when:%@ now:%@", [formatter stringFromDate:fireDate], [formatter stringFromDate:[NSDate date]]);
        return NO;
    }
    
//    因为下班的时间的那天并不上班， 所以隔天会提醒可能会被取消， 这样可以避免这个问题。
//  因为过夜的工作完全有可能是到了第二天， 而这一天也不工作，所以必须查看开始工作的那一天是否是工作日。
    
    if (isOffday) {
        if (![job isDayWorkingDay:firedayWorkDate]) {
            NSLog(@"drop a notify since it was not %@ 's working day: %@",job.jobName, [formatter stringFromDate:fireDate]);
            return NO;
        } 
    } else {
        if (![job isDayWorkingDay:fireDate]) {
            NSLog(@"drop a notify since it was not %@ 's working day: %@",job.jobName, [formatter stringFromDate:fireDate]);
            return NO;
        }
    }
    
    NSLog(@"add one local notify for:%@ firedate: %@",job.jobName, [formatter stringFromDate:fireDate]);
    
    localNotif.fireDate = fireDate;
    localNotif.timeZone = [NSTimeZone systemTimeZone];
    localNotif.hasAction = YES;
    localNotif.alertBody = alarmBody;
    localNotif.alertAction = actionTitle;
    
    if ([self shouldAlertWithSound]) {
        if ([self shouldUseSystemSound])
            localNotif.soundName = UILocalNotificationDefaultSoundName;
        else
            localNotif.soundName = @"notify.caf";
    }
    localNotif.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    return YES;
}


- (void) clearBadgeNumber
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}


- (int) setupAlarmForJob: (OneJob *) job daysLater:(int) daysLater
{
    NSString *timestr;
    NSString *defaultActionTitle = NSLocalizedString(@"I Know", "I Know");
    int alarmCount = 0;
    BOOL ret;
 
    if (job.jobRemindBeforeWork && job.jobRemindBeforeWork.intValue != -1) {
        
        if (job.jobRemindBeforeWork.intValue > 60*60)
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_BEFORE_HOURS, job.jobRemindBeforeWork.intValue / 60 / 60];
        else
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_BEFORE_MINITES, job.jobRemindBeforeWork.intValue / 60];
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
					isOffDay:NO];
        if (ret) alarmCount ++;
    }
    
    if (job.jobRemindBeforeOff && job.jobRemindBeforeOff.intValue != -1) {
        
        
        if (job.jobRemindBeforeOff.intValue > 60*60)
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_OFF_HOURS, job.jobRemindBeforeOff.intValue / 60 / 60];
        else
            timestr = [NSString stringWithFormat:TIME_STR_ALARM_OFF_MINITES, job.jobRemindBeforeOff.intValue / 60];
        
        if (job.jobRemindBeforeOff.intValue == 0)
            timestr = TIME_STR_ALARM_OFF_NOW;
        NSString *offRemindString = [NSString stringWithFormat:@"%@ %@.", job.jobName, timestr]; 
        
        ret = [self scheduleNotificationWithItem:[job getJobEverydayStartTime]
				   withDaysLater:daysLater
					interval:job.jobRemindBeforeOff.intValue
				       alarmBody:offRemindString
				alarmActionTitle:defaultActionTitle
				       TimeAfter:[job getJobEveryDayLengthSec].intValue
					     job:job
					isOffDay:YES];
        if (ret) alarmCount += 1;
    }
    return alarmCount;
}



- (void) setupAlarm: (BOOL)isShort
{
    
    // clear the alarm set before.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
#define MAX_NOTIFY_COUNT 24
    if (self.jobArray.count <= 0)
        return;
    
   
    
    if (isShort) {
        // if short, only update today's 
        for (OneJob *j in self.jobArray) {
            [self setupAlarmForJob:j daysLater:0];
            [self setupAlarmForJob:j daysLater:1];
        }
    } else {
        int max_notify = ((self.jobArray.count * 7) > MAX_NOTIFY_COUNT) ? MAX_NOTIFY_COUNT : self.jobArray.count * 7;
        int used = 0;
        // try our best to eat all the notify
        // and only set 7 days laters for each job.
        for (int i = 0; i < max_notify; i++) {
            if (used > max_notify)
                break;
            for (OneJob *j in self.jobArray)
                used += [self setupAlarmForJob:j daysLater:i];
        }
    }
}

#pragma mark - FetchedResultController 

/**
 Delegate methods of NSFetchedResultsController to respond to
 additions, removals and so on.
 */

// - (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
// 	// The fetch controller is about to start sending change
// 	// notifications, so prepare the table view for updates.
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
