//
//  SSCalendarSyncOperation.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-3-5.
//
//

#import "SSCalendarSyncOperation.h"

#import <EventKit/EventKit.h>
#import "OneJob.h"
#import "SyncEvent.h"
#import "NSDateAdditions.h"
#import "math.h"


@interface SSCalendarSyncOperation ()
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property SSCalendarSyncOperationType operation;

/// Used to store the sync days in when in setup all operation.
@property NSInteger oldValue;

// Below is the new values of these setting.
@property NSInteger syncDays;
@property NSInteger withAlarm;

/// fetched result controller for the job.
@property (nonatomic, strong)  NSFetchedResultsController *jobFetchedRequestController;

/// fetched result controller for the event.
@property (nonatomic, strong)  NSFetchedResultsController *eventFetchedRequestController;

@property (nonatomic, strong) NSCalendar *calendar;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic, strong)  EKCalendar   *ekEventCalendar;

@end

@implementation SSCalendarSyncOperation


- (id) initWithOperation: (SSCalendarSyncOperationType) type
                oldValue: (NSInteger) oldValue
                syncDays: (NSInteger) syncDays
               withAlarm: (NSInteger) withAlarm
             coordinator: (NSPersistentStoreCoordinator *) coordinator
{
    self = [super init];
    if (self) {
        self.coordinator = coordinator;
        self.oldValue = oldValue;
        self.syncDays = syncDays;
        self.withAlarm = withAlarm;
        self.operation = type;
        self.count = 0;
    }

    return self;
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




- (void) initFetchController {

        NSFetchRequest *jobrequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob"
                                                  inManagedObjectContext: self.context];

        [jobrequest setEntity:entity];
        jobrequest.sortDescriptors = @[[NSSortDescriptor
                                       sortDescriptorWithKey: @"jobName"
                                                   ascending: YES]];
        // No predicate, fetch all job for select the calendar sync.
        
        self.jobFetchedRequestController = [[NSFetchedResultsController alloc] 
                                               initWithFetchRequest: jobrequest
                                               managedObjectContext: self.context
                                                 sectionNameKeyPath:nil
                                                 cacheName: nil];

        [self fetchTiming:self.jobFetchedRequestController];

        // Next init is event 's fetch.
        NSEntityDescription *ee = [NSEntityDescription entityForName:@"SyncEvent"
                            inManagedObjectContext: self.context];
        NSFetchRequest *er = [[NSFetchRequest alloc] init];
        [er setEntity:ee];
        er.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startDate"
                                   ascending: NO]];
        self.eventFetchedRequestController = [[NSFetchedResultsController alloc] initWithFetchRequest:er
                                        managedObjectContext:self.context sectionNameKeyPath:nil
                                        cacheName:nil];

        [self fetchTiming:self.eventFetchedRequestController];
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

- (void) reloadData {
    [self fetchTiming:self.jobFetchedRequestController];
    [self fetchTiming:self.eventFetchedRequestController];
}

- (int) setupAllEKEvent {
    BOOL alarmOn = self.withAlarm;
    int days = self.syncDays;
    int count = 0;
    
    [self reloadData];
    
    for (OneJob *job in [self.jobFetchedRequestController fetchedObjects]) {
        count += [self setupEKEventWithAlarm:job alarm:alarmOn furtherLength:days];
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
    int daysNeedSync = days;

    // first need to figure out when is lastest synced event.
    
    NSDate *latestDate;
    NSDate *installDate;

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
        NSDate *upper = [[NSDate date] cc_dateByMovingToNextOrBackwardsFewDays:daysNeedSync withCalender:self.calendar];
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
 
        SyncEvent *syncevent = [NSEntityDescription insertNewObjectForEntityForName:@"SyncEvent" inManagedObjectContext:self.context];
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

    [self.context save:&error];
    if (error) {
        NSLog(@"mainManagedContext save in setup ek event failed:%@", error.userInfo);
    }

    return counter;
}

+ (int) deleteEKEventForShift: (OneJob *)shift 
                      context: (NSManagedObjectContext *)context
                        store: (EKEventStore *) store
                    formatter: (NSDateFormatter *) formatter
{
    NSError *error;
    int count = 0;
    NSMutableSet *set = [[NSMutableSet alloc] init];
    for (SyncEvent *event in shift.syncevents) {
        NSLog(@"Delete calendar eventID: %@ by : %@", event.ekId, [formatter stringFromDate:event.startDate]);
        EKEvent *e = [store eventWithIdentifier:event.ekId];
        [store removeEvent:e span:EKSpanThisEvent commit:NO error:&error];
        count++;
        if (error) {
            NSLog(@"remove event failed:%@", error.userInfo);
        }
        [set addObject:event];

    }
    
    [shift removeSyncevents:set];

    [store commit:&error];

    if (error) {
        NSLog(@"Error on commit eventStore");
    }

    [context save:&error];
    if (error) {
        NSLog(@"Remove EK Event failed: %@", error.userInfo);
    }
    return count;
}

+ (void) removeEKEventandSyncEvent: (SyncEvent *) event store: (EKEventStore *) store {
    NSError *error;
    EKEvent *e = [store eventWithIdentifier:event.ekId];
    
    [store removeEvent:e span:EKSpanThisEvent commit:NO error:&error];
    if (error) {
        NSLog(@"remove event failed:%@", error.userInfo);
    }
}

- (int) deleteOneShiftEKEvents  {
    int count = 0;
    [self reloadData];
    
    OneJob *j = (OneJob *)([self.context objectWithID:self.shiftID]);
    
    if (!j)
        return 0;
    
    count += [SSCalendarSyncOperation deleteEKEventForShift:j context:self.context store:self.eventStore formatter:self.formatter];
    return count;
}

- (int) deleteAllEKEvents {
    int count = 0;
    NSError *error;

    [self reloadData];
    
    for (OneJob *job in [self.jobFetchedRequestController fetchedObjects]) {
        count += [SSCalendarSyncOperation deleteEKEventForShift:job context:self.context store:self.eventStore formatter:self.formatter];
    }
    
    NSMutableSet *set = [[NSMutableSet alloc] init];
    for (SyncEvent *event in [self.eventFetchedRequestController fetchedObjects]) {
        [self.class removeEKEventandSyncEvent:event store:self.eventStore];
        [set addObject:event];
    }
    
    for (SyncEvent *e in set)
        [self.context deleteObject:e];
    
    [self.context save:&error];

    return count;
}

- (void) syncLengthSettingChanged {
    if (self.syncDays > self.oldValue) {
        [self setupAllEKEvent];
    } else {
        [self deleteAllEKEvents];
        [self setupAllEKEvent];
    }
}

- (void) alarmSettingChanged {
    if (self.withAlarm == YES) {
        [self deleteAllEKEvents];
        [self setupAllEKEvent];
    } else {
        [self reloadData];
        for (SyncEvent *event in [self.eventFetchedRequestController fetchedObjects]) {
            EKEvent *k = [self.eventStore eventWithIdentifier:event.ekId];
            k.alarms = nil;
            NSError *error = nil;
            [self.eventStore saveEvent:k span:EKSpanThisEvent commit:YES error:&error];
            if (error)
                NSLog(@"CalendarSync: meet error when processing ekevent error:%@",
                      error.userInfo);
        }
    }
}

- (void) main
{
    
    /// Note: about concurrcy CoreData, can set the main queue to parent to private type context,
    /// so when child changed, will also notify parent to merge child's change.
    
    self.context = [[NSManagedObjectContext alloc]
                    initWithConcurrencyType: NSPrivateQueueConcurrencyType];
    self.context.parentContext = self.mainContext;
    self.context.undoManager = nil;
    self.eventStore = [[EKEventStore alloc] init];

    [self.context performBlockAndWait:^
         {
             [self startWork];
         }];
}

- (void) startWork {

    [self initFetchController];
    if (self.operation == SSCalendarSyncOperationSetupAll) {
       self.count = [self setupAllEKEvent];
    } else if (self.operation == SSCalendarSyncOperationDeleteAll) {
        self.count = [self deleteAllEKEvents];
    } else if (self.operation == SSCalendarSyncOperationDeleteSetupAll) {
        [self deleteAllEKEvents];
        self.count = [self setupAllEKEvent];
    } else if (self.operation == SSCalendarSyncOperationDeleteOneShift) {
        self.count = [self deleteOneShiftEKEvents];
    } else if (self.operation == SSCalendarAlarmSettingChanged) {
        [self alarmSettingChanged];
    } else if (self.operation == SSCalendarLengthSettingChanged) {
        [self syncLengthSettingChanged];
    }
}


@end
