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

@class SSShareProfileListViewController;

@class SSMailAgent;
@class SSThinkNoteShareAgent;
@class SSShareController;
@class ThinkNoteShareViewController;

@interface SSAppDelegate : UIResponder <UIApplicationDelegate, 
UIActionSheetDelegate,UIAlertViewDelegate,SSShareViewControllerDelegate,
ProfileEditFinishDelegate>
{
    UINavigationController	*navController;
    UINavigationController	*profileNVC;
    KalViewController *kal;
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
    
    ThinkNoteShareViewController *_tnoteShareVC;
    
    UIBarButtonItem *shareButton;
    UIBarButtonItem *loadingButton;
    id dataSource;
    
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) ThinkNoteShareViewController *tnoteShareVC;

// --
@property (nonatomic, strong) UINavigationController *navController;				
@property (nonatomic, strong) ShiftListProfilesTVC *profileView;
@property (nonatomic, strong) SSSettingTVC *settingVC;
@property (nonatomic, strong) UINavigationController *profileNVC;
@property (nonatomic, strong) SSShiftHolidayList *changelistVC;
@property (nonatomic, strong) UIActionSheet *rightAS;
@property (nonatomic, strong) SSKalDelegate *sskalDelegate;
@property (nonatomic, strong) SSShareProfileListViewController *shareProfilesVC;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)didFinishEditingSetting;
- (void)showRightActionSheet;
- (void)popNotifyZeroProfile:(id) sender;
- (void) rightButtonSwitchToShareOrBusy:(BOOL) share;
@end
