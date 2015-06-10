//
//  SSTrackUtil.h
//  ShiftScheduler
//
//  Created by JiejingZhang on 15/6/10.
//
//

#import <Foundation/Foundation.h>
#import "Flurry.h"

@interface SSTrackUtil : NSObject

+ (void) applicationStarted;
+ (void) logEvent: (NSString *) event;
+ (void) logEvent: (NSString *)event param:(NSDictionary *) param;
+ (void) logTimedEvent: (NSString *) event;
+ (void) logTimedEvent: (NSString *) event param:(NSDictionary *)param;
+ (void) stopLogTimedEvent: (NSString *)event;
+ (void) logError: (NSString *) errorID message:(NSString *)message error: (NSError *) error;
+ (void) logError: (NSString *) errorID message:(NSString *)message exception: (NSException *) exception;


#define kLogEventTodayClicked           @"TODAY_CLICK"

#define kLogEventPopMenu                @"POP_MENU"

#define kLogEventMenuCalendar           @"MENU_CALENDAR_CLICK"
#define kLogEventMenuShiftList          @"MENU_SHIFT_LIST_CLICK"
#define kLogEventMenuMenu               @"MENU_MENU_CLICK"
#define kLogEventMenuCalendarSync       @"MENU_CALENDARSYNC_CLICK"
#define kLogEventMenuShare              @"MENU_SHARE_CLICK"


#define kLogEventNextMonth              @"NEXT_MONTH"
#define kLogEventLastMonth              @"LAST_MONTH"

#define kLogEventPopDateChoose          @"POP_DATA_CHOOSE"

#define kLogEventCalendarSync               @"CAL_SYNC"
#define kLogEventCalendarSyncDeleteAll      @"CAL_SYNC_DELETE_ALL"
#define kLogEventCaldendarSyncManualSync    @"CAL_SYNC_SYNC"
#define kLogEventCaldendarSyncLengthChange  @"CAL_SYNC_LENGTH_CHANGE"
#define kLogEventCaldendarSyncChangeShift   @"CAL_SYNC_SHIFT_CHANGE"
#define kLogEventCaldendarSyncDeleteAll     @"CAL_SYNC_DELETE_ALL"

#define kLogEventAppStart                   @"APP_START"

#define kLogEventAppStartFromTodayWidget    @"APP_START_FROM_TODAY"

#define kLogEventShiftChangePage            @"APP_SHIFT_CHANGE"

#define kLogEventShiftChangePageIconChange            @"APP_SHIFT_CHANGE_ICON_CHANGE"
#define kLogEventShiftChangePageNameChange            @"APP_SHIFT_CHANGE_NAME_CHANGE"
#define kLogEventShiftChangePageTextIcon              @"APP_SHIFT_CHANGE_TEXT_ICON"
#define kLogEventShiftChangePageColorPick              @"APP_SHIFT_CHANGE_COLOR_PICK"
#define kLogEventShiftChangePageShiftDetail           @"APP_SHIFT_CHANGE_SHIFT_DETAIL"
#define kLogEventShiftChangePageStartWith             @"APP_SHIFT_CHANGE_START_WITH"
#define kLogEventShiftChangePageRepeatTo              @"APP_SHIFT_CHANGE_REPEAT_TO"

#define kLogEventShiftListAdd                        @"APP_SHIFT_LIST_ADD"
#define kLogEventShiftListEnable                    @"APP_SHIFT_LIST_ENABLE"
#define kLogEventShiftListNormalOpen                    @"APP_SHIFT_LIST_NORMAL_OPEN"
#define kLogEventShiftListNormalOutdate                    @"APP_SHIFT_LIST_NORMAL_OUTDATE"

#define kLogEventSettingPage                                        @"SETTING_PAGE"
#define kLogEventSettingPageHolidayPick                           @"SETTING_PAGE_HOLIDAY_PICK"
#define kLogEventSettingPageSendFeedback                            @"SETTING_PAGE_SEND_FEEDBACK"
#define kLogEventSettingPageAlarm                                   @"SETTING_PAGE_ALARM_SETTING"
#define kLogEventSettingPageReset                                   @"SETTING_PAGE_RESET"
#define kLogEventSettingSysAlarmEnable                                   @"SETTING_PAGE_SYS_ALARM"
#define kLogEventSettingLuarnEnable                                   @"SETTING_PAGE_LUNAR_ENABLE"
#define kLogEventSettingMondayEnable                                    @"SETTING_PAGE_MONDAY_ENABLE"

#define kLogDataSaveError                                   @"ERROR_DATA_SAVE"
#define kLogDataCoodinatorError                             @"Error_DATA_COODINATOR"
#define kLogDataMigrateError                                @"Error_DATA_MIGRATE"

#define kLogEventDataMigrate                                @"DATA_MIGRATE"

@end
