//
//  SSCalendarSyncOperation.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-3-5.
//
//

#import <Foundation/Foundation.h>

@class OneJob;
@class EKEventStore;

typedef NS_ENUM(NSInteger, SSCalendarSyncOperationType) {
    SSCalendarSyncOperationSetupAll = 1,
        SSCalendarSyncOperationDeleteAll,
        SSCalendarAlarmSettingChanged,
        SSCalendarLengthSettingChanged,
};

@interface SSCalendarSyncOperation : NSOperation

- (id) initWithOperation: (SSCalendarSyncOperationType) type
                oldValue: (NSInteger) oldValue
                syncDays: (NSInteger) syncDays
               withAlarm: (NSInteger) withAlarm
             coordinator: (NSPersistentStoreCoordinator *) coordinator;


/// Delete shift event function.calendartvc
+ (int) deleteEKEventForShift: (OneJob *)shift 
                      context: (NSManagedObjectContext *)context
                        store: (EKEventStore *) store
                   formatter : (NSDateFormatter *) formatter;

@property NSInteger count;

@end
