//
//  I18NStrings.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/1/18.
//
//

#ifndef ShiftScheduler_I18NStrings_h
#define ShiftScheduler_I18NStrings_h

#define SHARE_STRING NSLocalizedString(@"Share", "share to other")
#define CREATE_PROFILE_PROMPT NSLocalizedString(@"You don't have any shift profile yet. Do you want to create one? ", "prompt of create profile title")
#define CREATE_PROFILE_NO  NSLocalizedString(@"No,Thanks", "no create one")
#define CREATE_PROFILE_YES  NSLocalizedString(@"Create Profile", "create one")
#define SYNC_CALENDAR       NSLocalizedString(@"Syncing", "sync to phone")


#define kCalendarSyncTitle   NSLocalizedString(@"Sync Phone Calendar", "")

#define kEnableCalendarSync NSLocalizedString(@"Enable Calendar Sync", "")
#define kDoSyncItem NSLocalizedString(@"Manual Sync", "")
#define kAlertInCalendarItem NSLocalizedString(@"Alert Setup", "")
#define kShiftSelectItem     NSLocalizedString(@"Shifts to Sync", "")
#define kLengthItem              NSLocalizedString(@"Time Span", "")
#define kDeleteEventsItem    NSLocalizedString(@"Delete Synced Events", "")

#define kEnableAutoSyncDetail NSLocalizedString(@"", "")
#define kAlertInCalendarDetail NSLocalizedString(@"setup same alarm as shift setting", "")
#define kShiftSelectDetail     NSLocalizedString(@"default sync all enabled shift", "")
#define kLengthDetail    NSLocalizedString(@"sync days in further", "")
#define kDeleteEventsDetail   NSLocalizedString(@"", "")

#define kLengthSelectionWeek NSLocalizedString(@"One Week", "")
#define kLengthSelection2Week NSLocalizedString(@"Two Week", "")
#define kLengthSelectionMonth NSLocalizedString(@"One Month", "")
#define kLengthSelection3Month NSLocalizedString(@"Three Month", "")

#define kCalendarSyncToPhoneFmt NSLocalizedString(@"%d calendar events are sync to phone calendar", "")
#define kCalendarSyncToPhoneNoAdd NSLocalizedString(@"No new calendar event was added in phone calendar", "")
#define kCalendarSyncToPhoneNoDel NSLocalizedString(@"No calendar event was deleted.", "")
#define kCalendarSyncToPhoneDel NSLocalizedString(@"%d calendar events are delete.", "")

#define kCalenderSyncDetail NSLocalizedString(@"Perform sync shift event from scheudler to phone calendar", "")
#define kCalendarLengthDetal NSLocalizedString(@"Sync the length days shift events of selected shift to phone calendar. Calendar events will be re created for any setting changes", "")
#define kCalendarDeleveDetail NSLocalizedString(@"Delete all events created by scheduler from phone calendar", "")

#define kSSCalendarAccessError NSLocalizedString(@"Access system calendar error, you need to enable calendar access by Setting -> Privacy -> Calendar", "")

#define NAME_ITEM_STRING  NSLocalizedString(@"Shift Name", "job name")
#define ICON_ITEM_STRING  NSLocalizedString(@"Change Icon", "choose a icon")
#define COLOR_ENABLE_STRING NSLocalizedString(@"Enable Color icon", "enable color icon")
#define COLOR_PICKER_STRING NSLocalizedString(@"Change Color", "choose a color to show icon")
#define ICON_OR_TEXT_STRING NSLocalizedString(@"Icon Behavior", "show icon or text in profile change view")
#define ICON_STRING NSLocalizedString(@"Icon", "Icon")
#define TEXT_STRING NSLocalizedString(@"Charactor", "Charactor")
#define STARTWITH_ITEM_STRING NSLocalizedString(@"Start with", "start with this date")
#define REPEAT_ITEM_STRING    NSLocalizedString(@"Repeat until", "finish at this date")
#define REPEAT_FOREVER_STRING NSLocalizedString(@"Repeat forever", "repeart forever string")
#define SHIFTCONFIG_ITEM_STRING NSLocalizedString(@"Shift detail", "config  detail of shift")
#define SHIFT_TIME_DETAIL_TITLE NSLocalizedString(@"Time and Remind", "time and remind title")

#define EMPTY_SHIFT_WARNNING_TITLE NSLocalizedString(@"Do you forget shift detail?", "empty shift warnning")
#define EMPTY_SHIFT_WARNNING_DETAIL NSLocalizedString(@"Please choose your shift detail...", "empty shift warnning.")

// XXX: in .strings file, %d actually going to %@, which can use for a strings.
#define TIME_STR_ALARM_BEFORE_HOURS NSLocalizedString(@"will start in %d Hour", "will start in %d Hour")
#define TIME_STR_ALARM_BEFORE_MINITES NSLocalizedString(@"will start in %d Minutes", "will start in %d Minutes")
#define TIME_STR_ALARM_BEFORE_NOW NSLocalizedString(@"is start now", "is start now")
#define TIME_STR_ALARM_OFF_HOURS NSLocalizedString(@"will off in %d Hour", "will start in %d Hour")
#define TIME_STR_ALARM_OFF_MINITES NSLocalizedString(@"will off in %d Minutes", "will start in %d Minutes")
#define TIME_STR_ALARM_OFF_NOW NSLocalizedString(@"is off now", "is start now")

#define ALERT_USER_ENTER_APP NSLocalizedString(@"The alarm you setup in app is going to out of date, please enter the app to active the alarm again (only enter and exit is enough)", "alarm out of date notify body")


#define SHIFTS_STR NSLocalizedString(@"Shift Manage", "")
//NSLocalizedString(@"Shifts", "shifts works in tabbar")
#define SETTINGS_STR NSLocalizedString(@"Settings", "Settings")
#define CALENDAR_STR NSLocalizedString(@"Calendar", "calendar in tab bar")
#define APP_NAME_STR NSLocalizedString(@"Shift Scheduler", "")
#define APP_URL @"http://appstore.com/shiftscheduler"


#define FROM_ITEM_STRING NSLocalizedString(@"Clock In", "Time to start work")
#define HOURS_ITEM_STRING NSLocalizedString(@"With Hours", "How many hours?")
#define REMIND_BEFORE_WORK NSLocalizedString(@"Work Alert", "how long notice before work")
#define REMIND_BEFORE_CLOCK_OFF NSLocalizedString(@"Off Alert", "how long time remind me before off")


#define LONG_ALARM_STR NSLocalizedString(@"Long Alarm", "long alarm section title")
#define SHORT_ALARM_STR NSLocalizedString(@"Short Alarm", "short alarm section title")

#define REGION_NAME_CHINA   NSLocalizedString(@"China", "china str")
#define REGION_NAME_HK      NSLocalizedString(@"HongKong", "hongkong str")
#define REGION_NAME_MACAO   NSLocalizedString(@"Mocao", "macoa")
#define REGION_NAME_TAIWAN  NSLocalizedString(@"Taiwan", "taiwan")
#define REGION_NAME_US      NSLocalizedString(@"US",     "US")
#define REGION_NAME_CANADIA NSLocalizedString(@"Canadia", "Canadia")
#define REGION_NAME_UK      NSLocalizedString(@"UK",      "UK")


#define FREE_ROUND_STRING NSLocalizedString(@"Regular Work Day", "")
#define FREE_JUMP_STRING NSLocalizedString(@"Customize Work Day", "")
#define NA_SHITF_STRING   NSLocalizedString(@"N/A", "")


#define REMIND_NO_ITEM_STR NSLocalizedString(@"None", "no")
#define REMIND_JUST_HAPPEN_ITEM_STR NSLocalizedString(@"At time of event", "just happen")
#define REMIND_5_MIN_ITEM_STR NSLocalizedString(@"5 minutes before", "5 Minutes")
#define REMIND_15_MIN_ITEM_STR NSLocalizedString(@"15 minutes before", "15 Minutes")
#define REMIND_30_MIN_ITEM_STR NSLocalizedString(@"30 minutes before", "30 Minutes")
#define REMIND_1_HOUR_ITEM_STR NSLocalizedString(@"1 hour before", "1 Hour")
#define REMIND_1_5_HOUR_ITEM_STR NSLocalizedString(@"1.5 hour before", "1.5 Hour")
#define REMIND_2_HOUR_ITEM_STR NSLocalizedString(@"2 hour before", "2 Hour")

#define LENGTH_OF_CYCLE NSLocalizedString(@"Shift Cycle", "length of cycle")


#define TELL_OTHER_ITEM_STRING NSLocalizedString(@"Tell a friend", "tell a friend item")
#define EMAIL_SUPPORT_ITEM_STRING NSLocalizedString(@"Email support", "eMail support item")
#define RATING_ITEM_STRING    NSLocalizedString(@"Rating me!", "Rating me item")

#define ENABLE_ALARM_SOUND NSLocalizedString(@"Alert Sound", "enable Alert")
#define PICK_ALERT_SOUND NSLocalizedString(@"Alert", "choose alert sound")

#define LUNAR_ENABLE_ITEM   NSLocalizedString(@"Lunar Calendar", "enable chinese calendar config title")
#define LUNAR_ENABLE_TEIM_HELP NSLocalizedString(@"show chinese lunar calendar", "enable chinese calendar config help")

#define MONDAY_START_ITEM   NSLocalizedString(@"Monday Start", "enable start with monday title.")
#define MONDAY_START_ITEM_HELP   NSLocalizedString(@"change week to monday", "change week start with monday help")

#define HOLIDAY_PICK_ITEM   NSLocalizedString(@"Holiday", "enable chinese calendar config title")
#define HOLIDAY_PICK_ITEM_HLEP NSLocalizedString(@"pick your region to show holidays", "show region hlidays help")

#define LOGIN_THINKNOTE_ITEM    NSLocalizedString(@"Login ThinkNote", "thinkNote Login")

#define CANCEL_STR NSLocalizedString(@"Cancel", "cancel")

#define RESET_STR NSLocalizedString(@"Reset All Data", "reset")
#define RESET_WARNNING_STR NSLocalizedString(@"This will delete all Shift information in your application, are you sure ?", \
"long warnning information before delete all data")



#define FREE_ROUND_DETAIL_STRING NSLocalizedString(@"eg, work 5 days off 2 days.", "")
#define FREE_JUMP_DETAIL_STRING NSLocalizedString(@"eg, 1, 3, 5, 7 on, 2, 4, 6 off", "")

#define SHIFT_TYPE_PICKER_STRING  NSLocalizedString(@"Work days mode", "in shift type picker view")


#define WORKLEN_ITEM_STRING   NSLocalizedString(@"Work Length", "how long work days")
#define RESTLEN_ITEM_STRING   NSLocalizedString(@"Rest Length", "how long rest days")


#define LUNAR_CONVERT_ERROR_TITLE_STR  NSLocalizedString(@"No Lunar Date", "not able to generate lunar Date title")
#define LUNAR_CONVERT_ERROR_DETAIL_STR  NSLocalizedString(@"lunar date out of range.", "not able to generate lunar Date title")

#define LUNAR_FMT_START_STRING  NSLocalizedString(@"Lunar", "")

#define kThinkNoteLoginName @"ThinkNoteLoginName"
#define kThinkNoteLoginPassword @"ThinkNoteLoginPassword"
#define LOGIN_STR  NSLocalizedString(@"Login", "login")
#define REGISTER_STR  NSLocalizedString(@"Register", "register a new account for thinknote")

#define LOGIN_THINKNOTE_ITEM    NSLocalizedString(@"Login ThinkNote", "thinkNote Login")

#define USER_PASSWD_WRONG_STR   NSLocalizedString(@"User Name or Password is not correct, failed to login to server, please double again", "user/password wrong message")
#define LOGIN_FAILED_STR NSLocalizedString(@"ThinkNote Login Failed", "think note login failed")

#define REPEAT_FOREVER_STRING NSLocalizedString(@"Repeat forever", "repeart forever string")

#define SHARE_STRING NSLocalizedString(@"Share", "share to other")
#define  TNS_SUCCESS_SHARED NSLocalizedString(@"Success share shift calendar to  www.qinbiji.cn", "success share shift calendar to qingbiji")

#define SHARE_TO_THINKNOTE  NSLocalizedString(@"Share by ThinkNote", "share by thinknote")

#define TNS_SETTING_TIPS NSLocalizedString(@"Please setup your ThinkNote account in 'Setting->Login ThinkNote'", "thinkNote Setting tips")


#endif
