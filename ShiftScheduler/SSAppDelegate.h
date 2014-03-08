//
//  SSAppDelegate.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 11-11-15.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShiftListProfilesTVC.h"
#import "KalViewController.h"
#import "SSShiftHolidayList.h"
#import "SSKalDelegate.h"
#import "SSSettingTVC.h"
#import "SSAlertController.h"
#import "ThinkNoteShareViewController.h"
#import "REFrostedViewController.h"
#import "SSMainNavigationController.h"
#import "CalendarSyncTVC.h"
#import "WeixinActivity.h" // this file include WXApi.h
#import "config.h"

@class SSShareProfileListViewController;

@class SSMailAgent;
@class SSThinkNoteShareAgent;
@class SSShareController;
@class ThinkNoteShareViewController;

#define SS_LOCAL_NOTIFY_WEEK_START_CHANGED @"week start day changed"

@interface SSAppDelegate : UIResponder <UIApplicationDelegate,
UIActionSheetDelegate,UIAlertViewDelegate,SSShareViewControllerDelegate,
ProfileEditFinishDelegate, REFrostedViewControllerDelegate, SSMainMenuDelegate, SSMainMenuShareButtonDelegate, WXApiDelegate>
{
    SSMainNavigationController	*navController;
    UINavigationController	*profileNVC;
    KalViewController *_kalController;
    SSAlertController *alertC;
    ShiftListProfilesTVC *profileView;
    SSShiftHolidayList *changelistVC;
    SSKalDelegate *sskalDelegate;
    SSSettingTVC *settingVC;
    SSShareProfileListViewController *shareProfilesVC;
    UITabBarController *tabBarVC;
    UIActionSheet *rightAS;
    UIAlertView  *alertNoProfile;
    SSMailAgent *mailAgent;
    SSThinkNoteShareAgent *thinkNoteAgent;
    SSShareController *_shareC;
    REFrostedViewController *_frostedViewController;

    ThinkNoteShareViewController *_tnoteShareVC;

    // bar button items.

    UIBarButtonItem *shareButton;
    UIBarButtonItem *loadingButton;
    UIBarButtonItem *todayButton;
    UIBarButtonItem *menuButton;
    id dataSource;

}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) ThinkNoteShareViewController *tnoteShareVC;

// --
@property (nonatomic, strong) SSMainNavigationController *navController;
@property (nonatomic, strong) ShiftListProfilesTVC *profileView;
@property (nonatomic, strong) SSSettingTVC *settingVC;
@property (nonatomic, strong) KalViewController *kalController;
@property (nonatomic, strong) CalendarSyncTVC  *calendarSyncSettingTVC;
@property (nonatomic, strong) UINavigationController *profileNVC;
@property (nonatomic, strong) SSShiftHolidayList *changelistVC;
@property (nonatomic, strong) UIActionSheet *rightAS;
@property (nonatomic, strong) SSKalDelegate *sskalDelegate;
@property (nonatomic, strong) SSShareProfileListViewController *shareProfilesVC;
@property (nonatomic, strong ) SSShareController *shareC;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)didFinishEditingSetting;
- (void)showRightActionSheet;
- (void)popNotifyZeroProfile:(id) sender;

+ (BOOL) enableThinkNoteConfig;
@end


#define SHIFTS_STR NSLocalizedString(@"Shift Manage", "")
//NSLocalizedString(@"Shifts", "shifts works in tabbar")
#define SETTINGS_STR NSLocalizedString(@"Settings", "Settings")
#define CALENDAR_STR NSLocalizedString(@"Calendar", "calendar in tab bar")
#define APP_NAME_STR NSLocalizedString(@"Shift Scheduler", "")
#define APP_URL @"http://appstore.com/shiftscheduler"
