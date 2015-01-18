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
#import "SSCalendarSyncOperation.h"

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
 */
@interface SSCalendarSyncController()

@property (nonatomic, strong) NSManagedObjectContext *mainManagedContext;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSOperationQueue          *operationQueue;

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

@property bool savedDeleteCalendarMark;
@property bool savedSetupCalendarMark;

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
        self.mainManagedContext = context;
        NSFetchRequest *jobrequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob"
                                                  inManagedObjectContext: self.mainManagedContext];
        [jobrequest setEntity:entity];
        jobrequest.sortDescriptors = @[[NSSortDescriptor
                                       sortDescriptorWithKey: @"jobName"
                                                   ascending: YES]];
        // No predicate, fetch all job for select the calendar sync.
        
        self.jobFetchedRequestController = [[NSFetchedResultsController alloc] 
                                               initWithFetchRequest: jobrequest
                                               managedObjectContext: self.mainManagedContext
                                                 sectionNameKeyPath:nil
                                                 cacheName: kJobCacheIdentifier];
        self.jobFetchedRequestController.delegate = self;

        [self fetchTiming:self.jobFetchedRequestController];

        // Next init is event 's fetch.

        NSEntityDescription *ee = [NSEntityDescription entityForName:@"SyncEvent"
                            inManagedObjectContext: self.mainManagedContext];
        NSFetchRequest *er = [[NSFetchRequest alloc] init];
        [er setEntity:ee];
        er.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startDate"
                                   ascending: NO]];
        self.eventFetchedRequestController = [[NSFetchedResultsController alloc] initWithFetchRequest:er
                                        managedObjectContext:self.mainManagedContext sectionNameKeyPath:nil
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
        
        [self.eventStore  requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                if (!granted) {
                    /// Disable calendar sync if no calendar access to avoid mess. 
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey: kSSCalendarSyncEnableSetting];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSSCalendarSyncEnableSettingChangedNotification  object:nil];   
                    return;
                }
            if (_eventStore && !_eventStore.defaultCalendarForNewEvents.allowsContentModifications) return;
            _canAccessCalendar = YES;
        }];

        self.operationQueue = [[NSOperationQueue alloc] init];
        [self.operationQueue setName:@"Calendar Sync Queue"];
        self.persistentStoreCoordinator = [context persistentStoreCoordinator];
    }


    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark setting related functions.

+ (void) initDefaults {

    // Setup calendar sync related defaults and fetch the latest value in cached value.
    [[NSUserDefaults standardUserDefaults] registerDefaults: @{
                                                               kSSCalendarSyncEnableSetting: @0,
                                                               kSSCalendarAutoSyncSetting: @0, // default should false
                                                               kSSCalendarWithAlarmSetting: @1,
                                                               kSSCalendarSyncLengthSetting: @7}];
}

+ (int) getCalendarSyncEnable {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kSSCalendarSyncEnableSetting];
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

- (void) eventProcessStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSSCalendarSyncStartNotification object:nil];
    });
}

- (void) eventProcessFinish: (NSInteger) count  type: (SSCalendarEventType) type {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSSCalendarSyncStopNotification object:
                                                        @{@"count" : [NSNumber numberWithInt:count],
                    @"type" : [NSNumber numberWithInt: (int)type]}];
    });
}

- (void) eventProcessError: (NSString *) error {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSSCalendarSyncErrorNotification object:error];
};

- (BOOL) _checkCanlendarEnable {
    if (![self.class getCalendarSyncEnable]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSSCalendarSyncErrorNotification
                                                            object:kSSCalendarSyncNotEnable];
        return NO;
    } else {
        return YES;
    }
}
            

#pragma mark SSCalendar core function

- (void) setupAllEKEvent: (BOOL) isNotify {

    if (![self _checkCanlendarEnable])
        return;

    // Queue a setup all events, and wait for the result.
    if (!self.canAccessCalendar) {
        [self eventProcessError: kSSCalendarSyncNoCalenarAccess];
        return;
    }


    [self.operationQueue cancelAllOperations];

    SSCalendarSyncOperation *operation = [[SSCalendarSyncOperation alloc] 
                                          initWithOperation: SSCalendarSyncOperationSetupAll
                                          oldValue: self.cachedConfigSyncDays
                                          syncDays:self.cachedConfigSyncDays
                                          withAlarm:self.cachedConfigAlarmOn
                                          coordinator : self.persistentStoreCoordinator];

    operation.mainContext = self.mainManagedContext;

    __block SSCalendarSyncOperation *weako = operation;

    [self eventProcessStart];

    [operation setCompletionBlock: ^{
        NSLog(@"finish setup all  operation, count:%d ", weako.count);
        if (isNotify)
            [self eventProcessFinish:weako.count type: SSCalendarEventTypeSetup];
    }];

    [self.operationQueue addOperation: operation];
}

- (void) deleteAllEKEvents {

    if (![self _checkCanlendarEnable])
        return;

    if (!self.canAccessCalendar) {
        [self eventProcessError: kSSCalendarSyncNoCalenarAccess];
        return;
    }


    // cancel all pending event, since it's not make sense.
    [self.operationQueue cancelAllOperations];

    // Queue a setup all events, and wait for the result.

    SSCalendarSyncOperation *operation = [[SSCalendarSyncOperation alloc] 
                                          initWithOperation: SSCalendarSyncOperationDeleteAll
                                          oldValue: 0
                                          syncDays:self.cachedConfigSyncDays
                                          withAlarm:self.cachedConfigAlarmOn
                                          coordinator : self.persistentStoreCoordinator];
    
    __block SSCalendarSyncOperation *weako = operation;
    operation.mainContext = self.mainManagedContext;
    
    [self eventProcessStart];
    [operation setCompletionBlock: ^{
        NSLog(@"finish setup all  operation: count:%d", weako.count);
        [self eventProcessFinish:weako.count type: SSCalendarEventTypeDelete];
    }];
    [self.operationQueue addOperation: operation];
 }

- (void) deleteEventsWithObjectID: (NSManagedObjectID *)id {

    if (![self _checkCanlendarEnable])
        return;

    if (!self.canAccessCalendar) {
        [self eventProcessError: kSSCalendarSyncNoCalenarAccess];
        return;
    }

    SSCalendarSyncOperation *operation = [[SSCalendarSyncOperation alloc] 
                                             initWithOperation: SSCalendarSyncOperationDeleteOneShift
                                                      oldValue: 0
                                                      syncDays:self.cachedConfigSyncDays
                                                     withAlarm:self.cachedConfigAlarmOn
                                                  coordinator : self.persistentStoreCoordinator];
    operation.shiftID = id;
    operation.mainContext = self.mainManagedContext;
    __block SSCalendarSyncOperation *weako = operation;
    
    [self eventProcessStart];
    [operation setCompletionBlock: ^{
        NSLog(@"finish setup all  operation: count:%d", weako.count);
        [self eventProcessFinish:weako.count type: SSCalendarEventTypeDelete];
    }];
    [self.operationQueue addOperation: operation];

}

- (void) deleteAndSetupEvents:(BOOL) notify {
    
    if (![self _checkCanlendarEnable])
        return;

    if (!self.canAccessCalendar) {
        [self eventProcessError: kSSCalendarSyncNoCalenarAccess];
        return;
    }

    // cancel all pending event, since it's not make sense.
    [self.operationQueue cancelAllOperations];

    // Queue a setup all events, and wait for the result.
    SSCalendarSyncOperation *operation = [[SSCalendarSyncOperation alloc] 
                                          initWithOperation: SSCalendarSyncOperationDeleteSetupAll
                                          oldValue: 0
                                          syncDays:self.cachedConfigSyncDays
                                          withAlarm:self.cachedConfigAlarmOn
                                          coordinator : self.persistentStoreCoordinator];

    operation.mainContext = self.mainManagedContext;
    __block SSCalendarSyncOperation *weako = operation;
    
    [self eventProcessStart];
    [operation setCompletionBlock: ^{
        NSLog(@"finish setup all  operation: count:%d", weako.count);
        if (notify)
            [self eventProcessFinish:weako.count type: SSCalendarEventTypeSetup];
    }];
    [self.operationQueue addOperation: operation];
}

#pragma mark - FetchedResultControllerDelegate
/**
 Delegate methods of NSFetchedResultsController to respond to
 additions, removals and so on.
 */

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

/// This cause issue when using a lot on phone, this will cause iOS crash and a lot of slow down to phone.
/// So, we only do this when the application is going to background.     
#if 0
    if (controller == self.eventFetchedRequestController)
        return;

    switch(type) {
        case NSFetchedResultsChangeInsert:
            if ([anObject isKindOfClass:[OneJob class]]) {

                if (![self _checkCanlendarEnable])
                    return;

                [self setupAllEKEvent: NO];
            }
            break;
            
        case NSFetchedResultsChangeDelete:
            if ([anObject isKindOfClass:[OneJob class]]) {
                //                OneJob *j =  (OneJob *) anObject;
                // FIXME This have a delama, because this remove was base on shift, but shift already removed, and will cause crash.
//                [SSCalendarSyncOperation deleteEKEventForShift:j context:self.mainManagedContext store:self.eventStore formatter:self.formatter];
            }
            break;
            
        case NSFetchedResultsChangeUpdate:
            if ([anObject isKindOfClass:[OneJob class]]) {
                if (![self _checkCanlendarEnable])
                    return;

                OneJob *j = (OneJob *) anObject;
                NSDictionary *d = [j changedValues];
                NSLog(@"DEBUG: changed values: %@", d);
                
                if ([d objectForKey:@"syncEnableEKEvent"] == nil)
                    return;

                if (j.syncEnableEKEvent) {
                    [self deleteAndSetupEvents:YES];
                } else {
                    [self deleteEventsWithObjectID:j.objectID];
                }
            }
            break;
            
        case NSFetchedResultsChangeMove:
          // ignore this.
            break;
    }
#else
    if (controller == self.eventFetchedRequestController)
        return;

    switch(type) {
        case NSFetchedResultsChangeInsert:
            if ([anObject isKindOfClass:[OneJob class]]) {
                if (![self _checkCanlendarEnable])
                    return;

                [self markSetupCalendar];
            }
            break;
            
        case NSFetchedResultsChangeUpdate:
            if ([anObject isKindOfClass:[OneJob class]]) {
                if (![self _checkCanlendarEnable])
                    return;

                OneJob *j = (OneJob *) anObject;
                NSDictionary *d = [j changedValues];
                //                NSLog(@"DEBUG: changed values: %@", d);
                
                if ([d objectForKey:@"syncEnableEKEvent"] == nil)
                    return;

                if (j.syncEnableEKEvent) {
                    [self markDeleteCalendar];
                    [self markSetupCalendar];
                } else {
                    NSLog(@"Warnning: Will delete all shift events with object DI");
                    [self deleteEventsWithObjectID:j.objectID];
                }
            }
            break;
        default:
            break;
    }
#endif
 }

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
        // The fetch controller has sent all current change
        // notifications, so tell the table view to process all
        // updates.
    if (controller == self.eventFetchedRequestController)
        return;
    NSLog(@"CaendarSync: controller did changed context...");
//    [self calendarSettingChangeSaved];
// this will not reflect change, so don't do that...
// conservative strategy.. 
    
}


- (void) autoSyncSettingChanged {

    if (![self _checkCanlendarEnable])
        return;

    if (!self.canAccessCalendar) {
        [self eventProcessError: kSSCalendarSyncNoCalenarAccess];
        return;
    }

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

    if (![self _checkCanlendarEnable])
        return;

    if (!self.canAccessCalendar) {
        [self eventProcessError: kSSCalendarSyncNoCalenarAccess];
    }
    
    if (self.cachedConfigSyncDays == n) {
        return;
    }

    // Queue a setup all events, and wait for the result.
    SSCalendarSyncOperation *operation = [[SSCalendarSyncOperation alloc] 
                                          initWithOperation: SSCalendarLengthSettingChanged
                                          oldValue: self.cachedConfigSyncDays
                                          syncDays:n
                                          withAlarm:self.cachedConfigAlarmOn
                                          coordinator : self.persistentStoreCoordinator];

    operation.mainContext = self.mainManagedContext;
    __block SSCalendarSyncOperation *weako = operation;

    [self eventProcessStart];
    [operation setCompletionBlock: ^{
            NSLog(@"finish length change  operation: count:%d", weako.count);
            [self eventProcessFinish:weako.count type: SSCalendarEventTypeDays];
        }];
    [self.operationQueue addOperation: operation];
    self.cachedConfigSyncDays = n;

}


/// If enable alarm, we need to delete all existing events and setup
/// again.  else if disable alarm, just go through all existing events,
/// and clear the their alarm.
- (void) withAlarmSettingChanged {
    int n = [SSCalendarSyncController getAlarmSyncSetting];


    if (![self _checkCanlendarEnable])
        return;

    if (!self.canAccessCalendar) {
        [self eventProcessError: kSSCalendarSyncNoCalenarAccess];
    }

    if (n == self.cachedConfigAlarmOn)
        return;

    SSCalendarSyncOperation *operation = [[SSCalendarSyncOperation alloc] 
                                          initWithOperation: SSCalendarAlarmSettingChanged
                                          oldValue: self.cachedConfigAlarmOn
                                          syncDays:self.cachedConfigSyncDays
                                          withAlarm:self.cachedConfigAlarmOn
                                          coordinator : self.persistentStoreCoordinator];

    operation.mainContext = self.mainManagedContext;
    __block SSCalendarSyncOperation *weako = operation;

    [self eventProcessStart];
    [operation setCompletionBlock: ^{
            NSLog(@"finish alarm setting  operation: count:%d", weako.count);
            // TODO: add notification here.
            [self eventProcessFinish:weako.count type: SSCalendarEventTypeAlarm];
        }];
    [self.operationQueue addOperation: operation];

    self.cachedConfigAlarmOn = n;

}

- (void) startOrStopAutoSync {

}

- (NSArray *) getAllShiftList {

        [self fetchTiming:self.jobFetchedRequestController];
        return [self.jobFetchedRequestController fetchedObjects];
}

- (OneJob *) getShiftWithID: (NSManagedObjectID *) objectID {
    NSError *error;

    NSManagedObject* e = [self.mainManagedContext existingObjectWithID:objectID error:&error];
    if (error) {
        NSLog(@"error on get object:%@", error.userInfo);
        return nil;
    }

    if (![e isKindOfClass:[OneJob class]])
        return nil;
    else
        return (OneJob *)e;
}

- (void) saveShiftChange {
    [self.mainManagedContext save:nil];
}

- (void) calendarSettingChangeSaved {
     if (self.savedDeleteCalendarMark && self.savedSetupCalendarMark)
     [self deleteAndSetupEvents:NO];
     else if (self.savedDeleteCalendarMark)
     [self deleteAllEKEvents];
     else if (self.savedSetupCalendarMark)
     [self setupAllEKEvent:NO];

}

- (void) appGoingToBackgroud {
    
    // iOS sees don't execute operation queue when app going to background.
    // so we don't do that automaticlly.
    // compare to mess up user's system calendar, we let user manually setup this.

    [self markCalendarReset];
}

- (void) markCalendarReset {
    self.savedDeleteCalendarMark = NO;
    self.savedSetupCalendarMark = NO;
}

/// Mark the schedule delete operation of current calendar
- (void) markDeleteCalendar {
    self.savedDeleteCalendarMark = YES;
}

/// Mark the schedule delete operation of current calendar 
- (void) markSetupCalendar {
    self.savedSetupCalendarMark = YES;
}

@end

