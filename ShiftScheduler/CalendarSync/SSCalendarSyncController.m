//
//  SSCalendarSyncController.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-2-23.
//
//

#import "SSCalendarSyncController.h"
#import <EventKit/EventKit.h>
#import "OneJob.h"
#import "SyncEvent.h"
#import "NSDateAdditions.h"
#import "math.h"

/** 
 *    This class is the sync controller to iOS part of shfit event,
 * 
 *   It mainly have two part:
 *    1. Observer of setting change for Calendar of systme calendar
 *    2. When Setting changed, reflect such change, sync the calendar event.
 *
 *   The main algorithm will be like this:
 *   - Find the latest shift which in the calendar, calc the current date + length if <= latest event,
 *   - if needs sync, sync to latest,
 *   - if current event is too far away, delete the further events.
 *
 *   Event / Changes:
 *   - if shift 's setting changed, check such shift 's events and eventEnable parameter align,
 *       delete shift 's events and re-generate them.
 *   - if the sync setting changed, just delete all the events, and also delete the database SyncEvent
 *   - if alarm configure changed, go through all events and do the alarm change, not re-generate
 *     the EKEvent and SyncEvent
 *   - if the length of sync change, if longer, just let the extent the events.
 *     sorter, just delete the events which is no need to appear.   
 *
 *  For simple design, first keep all operation block operation, change to async if there is
 *     a performance issue.
 
        TODO. Find a good place to add event, not good in init function.
 */
@interface SSCalendarSyncController()

@property (nonatomic, strong) NSManagedObjectContext *managedContext;

/// fetched result controller for the job.
@property (nonatomic, strong)  NSFetchedResultsController *jobFetchedRequestController;

/// fetched result controller for the event.
@property (nonatomic, strong)  NSFetchedResultsController *eventFetchedRequestController;

@property bool cachedConfigAlarmOn;
@property bool cachedConfigAutoSyncOn;
@property int  cachedConfigSyncDays;

@property (nonatomic, strong)  EKEventStore *eventStore;
@property (nonatomic, strong)  EKCalendar   *ekEventCalendar;

@property (nonatomic, strong) NSCalendar *calendar;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property bool canAccessCalendar;

@end

@implementation SSCalendarSyncController

//#define kJobCacheIdentifier              @"SSCalendarSyncJobNameCache"
//#define kEventCacheIdentifier            @"SSCalendarSyncEventCache"

#define kEventCacheIdentifier            nil
#define kJobCacheIdentifier              nil

- (id) initWithManagedContext: (NSManagedObjectContext *) context {

    self = [super init];
    if (self) {
        self.canAccessCalendar = false;
        self.managedContext = context;
        NSFetchRequest *jobrequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob"
                                                  inManagedObjectContext: self.managedContext];
        [jobrequest setEntity:entity];
        jobrequest.sortDescriptors = @[[NSSortDescriptor
                                       sortDescriptorWithKey: @"jobName"
                                                   ascending: YES]];
        // No predicate, fetch all job for select the calendar sync.
        
        self.jobFetchedRequestController = [[NSFetchedResultsController alloc] 
                                               initWithFetchRequest: jobrequest
                                               managedObjectContext: self.managedContext
                                                 sectionNameKeyPath:nil
                                                 cacheName: kJobCacheIdentifier];
        self.jobFetchedRequestController.delegate = self;

        [self fetchTiming:self.jobFetchedRequestController];

        // Next init is event 's fetch.

        NSEntityDescription *ee = [NSEntityDescription entityForName:@"SyncEvent"
                            inManagedObjectContext: self.managedContext];
        NSFetchRequest *er = [[NSFetchRequest alloc] init];
        [er setEntity:ee];
        er.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startDate"
                                   ascending: NO]];
        self.eventFetchedRequestController = [[NSFetchedResultsController alloc] initWithFetchRequest:er
                                        managedObjectContext:self.managedContext sectionNameKeyPath:nil
                                        cacheName:kEventCacheIdentifier];
        self.eventFetchedRequestController.delegate = self;
        [self fetchTiming:self.eventFetchedRequestController];

        [SSCalendarSyncController initDefaults];
        self.cachedConfigAutoSyncOn = [SSCalendarSyncController getAutoSyncSetting];
        self.cachedConfigAlarmOn = [SSCalendarSyncController getAlarmSyncSetting];
        self.cachedConfigSyncDays = [SSCalendarSyncController getSyncLengthSetting];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(withAlarmSettingChanged)
                                                     name: kSSCalendarWithAlarmSettingChangedNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(autoSyncSettingChanged)
                                                     name: kSSCalendarAutoSyncSettingChangedNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(syncLengthSettingChanged)
                                                     name: kSSCalendarSyncLengthSettingChangedNotification
                                                   object:nil];
        
        
        // try the permission.
        self.eventStore = [[EKEventStore alloc] init];
        
        __block SSCalendarSyncController *theself;

        [self.eventStore  requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (!granted) return;
            if (!_eventStore.defaultCalendarForNewEvents.allowsContentModifications) return;

            _canAccessCalendar = YES;
            if (_cachedConfigAutoSyncOn) {
                [theself setupAllEKEvent];
                
                
            }
        }];
    }

    return self;
}

#pragma mark setting related functions.

+ (void) initDefaults {
    // Setup calendar sync related defaults and fetch the latest value in cached value.
    [[NSUserDefaults standardUserDefaults] registerDefaults: @{
                                                               kSSCalendarAutoSyncSetting: @1, // default should false
                                                               kSSCalendarWithAlarmSetting: @1,
                                                               kSSCalendarSyncLengthSetting: @7}];
}

+ (int) getAutoSyncSetting {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kSSCalendarAutoSyncSetting];
}

+ (int) getAlarmSyncSetting {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kSSCalendarWithAlarmSetting];
}

+ (int) getSyncLengthSetting {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kSSCalendarSyncLengthSetting];
}

- (NSCalendar *) calendar {
    if (_calendar == nil)
        _calendar = [NSCalendar currentCalendar];
    return _calendar;
}

- (NSDateFormatter *) formatter {
    if (_formatter == nil) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateStyle:NSDateFormatterShortStyle];
        [_formatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return _formatter;
}

- (EKCalendar *) ekEventCalendar {
    if (_ekEventCalendar == nil)
        _ekEventCalendar = [_eventStore defaultCalendarForNewEvents];
    return _ekEventCalendar;
}

- (void) fetchTiming: (NSFetchedResultsController *) controller
{
    NSDate *start;
    NSError *error = NULL;
    NSTimeInterval interval;
    NSString *name;
    start = [NSDate date];
    name = controller.fetchRequest.entityName;
    [controller performFetch:&error];
    interval = [start timeIntervalSinceNow];
    if (error) {
        NSLog(@"Error when fetching %@", name);
    } else {
        NSLog(@"Timing: fetch %lu object from %@ cost %g seconds.", (unsigned long)controller.fetchedObjects.count, name, interval);
    }
}

#pragma mark SSCalendar core function

- (int) setupAllEKEvent {
    BOOL alarmOn = [SSCalendarSyncController getAlarmSyncSetting];
    int days = [SSCalendarSyncController getSyncLengthSetting];
    int count = 0;

    _canAccessCalendar = YES;

    if (_cachedConfigAutoSyncOn) {
        for (OneJob *job in [self.jobFetchedRequestController fetchedObjects]) {
            count += [self setupEKEventWithAlarm:job alarm:alarmOn furtherLength:days];
        }
    }
    return count;
}
/**
   setup EKEvent on the target device for the shift with some settings.
 */
- (int) setupEKEventWithAlarm: (OneJob *) shift alarm: (BOOL) alarmOn furtherLength:(int)days
{
    NSError *error;
    int counter = 0;
    int daysNeedSync = self.cachedConfigSyncDays;

    if (!self.canAccessCalendar)
        return counter;
    
    // first need to figure out when is lastest synced event.
    
    NSDate *latestDate;
    NSDate *installDate;

    if (shift.syncEnableEKEvent.intValue != YES)
        return 0;

    if (shift.syncevents.count > 0) {
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
        NSArray *sortedEvents = [shift.syncevents sortedArrayUsingDescriptors:@[sort]];
        SyncEvent *last = [sortedEvents lastObject];
        latestDate = last.startDate;
    }
    
    // if not setup before, you need setup today's event also...
    if (latestDate == nil) {
        installDate = [NSDate date];
    } else {
        // check if need to sync more events.
        NSDate *upper = [[NSDate date] cc_dateByMovingToNextOrBackwardsFewDays:self.cachedConfigSyncDays withCalender:self.calendar];
        installDate = [latestDate cc_dateByMovingToNextDayWithCalender:self.calendar];

        NSDateComponents *difference = [self.calendar components:NSDayCalendarUnit
                                                       fromDate:installDate toDate:upper options:0];
        daysNeedSync = MIN(difference.day, 93);  // safe ground, too many event makes iOS crash.
    }
    
    if (daysNeedSync <= 0)
        return 0;
    
    for (int i = 0; i < daysNeedSync; i++) {
        NSDate *startDate, *endDate;
        installDate = [installDate cc_dateByMovingToNextOrBackwardsFewDays:1 withCalender:self.calendar];
        startDate = [installDate cc_dateBySetTimePart:[shift getJobEverydayStartTime]  withCalendar:self.calendar];
        endDate = [installDate cc_dateBySetTimePart:[shift getJobEverydayEndTime]  withCalendar:self.calendar];

        if (![shift isDayWorkingDay:startDate])
            continue;
 
        SyncEvent *syncevent = [NSEntityDescription insertNewObjectForEntityForName:@"SyncEvent" inManagedObjectContext:self.managedContext];
        syncevent.title = shift.jobName;
        syncevent.startDate = startDate;
        syncevent.endDate = endDate;
        
        EKEvent *event = [EKEvent eventWithEventStore:self.eventStore];
        event.title = syncevent.title;
        event.startDate = syncevent.startDate;
        event.endDate = syncevent.endDate;
        event.calendar = self.ekEventCalendar;
        event.notes = NSLocalizedString(@"Calendar Event is Created by Shift Scheduler, download via: http://itunes.apple.com/en/app//id482061308?mt=8", "");

        if (alarmOn) {
            // Note: the seconds of alarm is "seconds" before the on and off time.
            // -1 means the alert is disabled.
            syncevent.alarmOne = shift.jobRemindBeforeWork;
            syncevent.alarmTwo = shift.jobRemindBeforeOff;
            
            NSMutableArray *array = [[NSMutableArray alloc] init];
            if (syncevent.alarmOne && syncevent.alarmOne.intValue != -1)
                [array addObject: [EKAlarm alarmWithRelativeOffset:syncevent.alarmOne.intValue * -1]];
            
            if (syncevent.alarmTwo && syncevent.alarmTwo.intValue != -1) {
                int n = syncevent.alarmTwo.intValue * -1 + [shift  getJobEveryDayLengthSec].intValue;
                [array addObject: [EKAlarm alarmWithRelativeOffset:n]];
            }
            
            if (array.count > 0)
                event.alarms = array;
        }
        
    
        error = NULL;
        BOOL result = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
        if (!result) {
            NSLog(@"save failed for event: %@  with error:%@", event, error.userInfo);
        }
        syncevent.ekId = event.eventIdentifier;
        [shift addSynceventsObject:syncevent];
        NSLog(@"Setup calendar eventID: %@ by : %@",event.eventIdentifier , [self.formatter stringFromDate:startDate]);
        counter++;
    }
    
    error = NULL;
    [self.eventStore commit:&error];
    if (error) {
        NSLog(@"eventStore commit failed:%@", error.userInfo);
    }

    [self.managedContext save:&error];
    if (error) {
        NSLog(@"managedContext save in setup ek event failed:%@", error.userInfo);
    }

    return counter;
}


- (int) deleteEKEventForShift: (OneJob *)shift {
    NSError *error;
    int count = 0;
    for (SyncEvent *event in shift.syncevents) {
        if (self.canAccessCalendar) {
            NSLog(@"Delete calendar eventID: %@ by : %@", event.ekId, [self.formatter stringFromDate:event.startDate]);
            EKEvent *e = [self.eventStore eventWithIdentifier:event.ekId];
            [self.eventStore removeEvent:e span:EKSpanThisEvent commit:NO error:&error];
            count++;
            if (error) {
                NSLog(@"remove event failed:%@", error.userInfo);
            }
        }
        
        [self.managedContext deleteObject:event];
    }
    if (self.canAccessCalendar)
        [self.eventStore commit:&error];

    if (error) {
        NSLog(@"Error on commit eventStore");
    }

    [self.managedContext save:&error];
    if (error) {
        NSLog(@"Remove EK Event failed: %@", error.userInfo);
    }
    return count;
}

- (int) deleteAllEKEvents {
    int count = 0;
    // FIXME: don't fetch every time, this want to refresh the cache.
    [self.jobFetchedRequestController performFetch:NULL];
    
    for (OneJob *job in [self.jobFetchedRequestController fetchedObjects]) {
        count += [self deleteEKEventForShift:job];
    }
    return count;
}

#pragma mark - FetchedResultControllerDelegate
/**
 Delegate methods of NSFetchedResultsController to respond to
 additions, removals and so on.
 */


// TODO: use below code to get a better performance if it's a issue.
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (controller == self.eventFetchedRequestController)
        return;

    switch(type) {
        case NSFetchedResultsChangeInsert:
            break;
            
        case NSFetchedResultsChangeDelete:
            break;
            
        case NSFetchedResultsChangeUpdate:
            break;
            
        case NSFetchedResultsChangeMove:
            break;
    }
 }

- (void) startOrStopAutoSync {
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
        // The fetch controller has sent all current change
        // notifications, so tell the table view to process all
        // updates.
}

- (void) autoSyncSettingChanged {
    int n = [SSCalendarSyncController getAutoSyncSetting];

    // so if user want to stop or start the auto sync, stop notification for some time well...
    if (n == self.cachedConfigAutoSyncOn)
        return;

    self.cachedConfigAutoSyncOn = n;
    [self startOrStopAutoSync];
}



/// If length becoming bigger, just do the resync.
/// if length become sort, delete events and resync.
- (void) syncLengthSettingChanged {
    int n = [SSCalendarSyncController getSyncLengthSetting];

    if (n > self.cachedConfigSyncDays) {
        self.cachedConfigSyncDays = n;
        [self setupAllEKEvent];
    } else {
        self.cachedConfigSyncDays = n;
        [self deleteAllEKEvents];
        [self setupAllEKEvent];
    }
}


/// If enable alarm, we need to delete all existing events and setup
/// again.  else if disable alarm, just go through all existing events,
/// and clear the their alarm.


- (void) withAlarmSettingChanged {
    [self performSelectorInBackground:@selector(withAlarmSettingChangedInternal) withObject:nil];
}

- (void) withAlarmSettingChangedInternal {
    int n = [SSCalendarSyncController getAlarmSyncSetting];

    if (n == self.cachedConfigAlarmOn)
        return;

    self.cachedConfigAlarmOn = n;

    if (n == YES) {
        [self deleteAllEKEvents];
        [self setupAllEKEvent];
    } else {
        [self fetchTiming:self.eventFetchedRequestController];
        for (SyncEvent *event in [self.eventFetchedRequestController fetchedObjects]) {
                EKEvent *k = [self.eventStore eventWithIdentifier:event.ekId];
                k.alarms = nil;
                NSError *error = nil;
                [_eventStore saveEvent:k span:EKSpanThisEvent commit:YES error:&error];
                if (error)
                    NSLog(@"CalendarSync: meet error when processing ekevent error:%@",
                          error.userInfo);
        }
    };
}

- (void) allSyncEventsStoredRunBlock: (void (^)(SyncEvent *))theBlock {
    [self fetchTiming:self.eventFetchedRequestController];
    for (SyncEvent *event in [self.eventFetchedRequestController fetchedObjects])
        theBlock(event);
}

- (NSArray *) getAllShiftList {
        [self fetchTiming:self.jobFetchedRequestController];
        return [self.jobFetchedRequestController fetchedObjects];
}

- (OneJob *) getShiftWithID: (NSManagedObjectID *) objectID {
    NSError *error;
   OneJob *j = [self.managedContext existingObjectWithID:objectID error:&error];
    
    if (error) {
        NSLog(@"error on get object:%@", error.userInfo);
    }
    
    return j;
}

- (void) saveShiftChange {
    [self.managedContext save:nil];
}

@end

