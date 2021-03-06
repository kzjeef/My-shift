//
//  SSCalendarSyncController.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-2-23.
//
//

#import <Foundation/Foundation.h>


#define kSSCalendarAutoSyncSettingChangedNotification @"SSCalendarAutoSyncSettingChangedNotification"
#define kSSCalendarWithAlarmSettingChangedNotification @"SSCalendarAlarmSettingChangedNotification"
#define kSSCalendarSyncLengthSettingChangedNotification @"SSCalendarSyncLengthSettingChangedNotification"
#define kSSCalendarSyncEnableSettingChangedNotification @"SSCalendarSyncEnableChangeddNotification"

#define kSSCalendarSyncStartNotification  @"SSCalendarSyncBegin"
#define kSSCalendarSyncStopNotification   @"SSCalendarSyncEnd"
#define kSSCalendarSyncErrorNotification   @"SSCalendarSyncError"

#define kSSCalendarSyncNoCalenarAccess @"Error_SSCalendarNotCalendarAccess"
#define kSSCalendarSyncNotEnable @"Error_SSCalendarNotEnable"

#define kSSCalendarAutoSyncSetting @"SSCalendarAutoSyncSetting"
#define kSSCalendarWithAlarmSetting @"SSCalendarAlarmSetting"
#define kSSCalendarSyncLengthSetting @"SSCalendarSyncLengthSetting"
#define kSSCalendarSyncEnableSetting @"kSSCalendarSyncEnableSetting"

enum {
    SSCalendarSyncErrorUnkown = -1,
    SSCalendarSyncErrorNoAccessCalendar = -2,
};

typedef NS_ENUM(NSInteger, SSCalendarEventType) {
    SSCalendarEventTypeSetup = 1,
        SSCalendarEventTypeDelete,
        SSCalendarEventTypeAlarm,
        SSCalendarEventTypeDays,
};

@class OneJob;

/**
 * SSCalendarSyncController is the class manage sync shift to iOS OS calendar,
 */
@interface SSCalendarSyncController : NSObject <NSFetchedResultsControllerDelegate>

- (id) initWithManagedContext: (NSManagedObjectContext *) context;

/**
   just setup all enabled shift's ekevent
 */
- (void) setupAllEKEvent: (BOOL) isNotify;

/**
   delete all events generated by this controller.
 */
- (void) deleteAllEKEvents;

/** 
 Delete and resetup all sync events.
 */

- (void) deleteAndSetupEvents: (BOOL) isNotify;

/**
   get shift list for other UI.
*/
- (NSArray *) getAllShiftList;

/**
 get managed object with ID
 */
- (OneJob *) getShiftWithID: (NSManagedObjectID *) objectID;

/**
   save shift change
*/
- (void) saveShiftChange;

/**
   application going to background callback.
*/
- (void) appGoingToBackgroud;

/**
 get current settting value of auto sync
 */
+ (NSInteger) getAutoSyncSetting;

/**
 get current setting value of alarm of sync
 */
+ (NSInteger) getAlarmSyncSetting;

/**
 get current setting value of sync length 
 */
+ (NSInteger) getSyncLengthSetting;

/**
   get current setting of enable calendar sync
*/

+ (NSInteger) getCalendarSyncEnable;


@end
