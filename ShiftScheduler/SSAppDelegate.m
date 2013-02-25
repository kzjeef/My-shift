//
//  SSAppDelegate.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 11-11-15.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "config.h"
#import "SSAppDelegate.h"
#import "WorkdayDataSource.h"
#import "SSKalDelegate.h"
#import "SSMailAgent.h"
#import "SSShareProfileListViewController.h"
#import "SSShareObject.h"
#import "SSThinkNoteShareAgent.h"
#import "ThinkNoteShareViewController.h"
#import "UIImageResizing.h"
#import "SSDefaultConfigName.h"

#import "Kal.h"

@implementation SSAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

// --
@synthesize profileView;
@synthesize navController;
@synthesize profileNVC, rightAS, changelistVC, settingVC, sskalDelegate, shareProfilesVC;

enum {
    TAG_MENU,
    TAG_ZERO_PROFILE,
};

#define SHARE_STRING NSLocalizedString(@"Share", "share to other")
#define CREATE_PROFILE_PROMPT NSLocalizedString(@"You don't have any shift profile yet. Do you want to create one? ", "prompt of create profile title")
#define CREATE_PROFILE_NO  NSLocalizedString(@"No,Thanks", "no create one")
#define CREATE_PROFILE_YES  NSLocalizedString(@"Create Profile", "create one")

//#define CONFIG_SS_ENABLE_SHIFT_CHANGE_FUNCTION

- (void) SSKalControllerInit
{
    
    dispatch_async(dispatch_get_main_queue(), ^{

	    [self shiftModuleMigration];
	    
	    kal = [[KalViewController alloc] init];
	    kal.title = NSLocalizedString(@"Shift Scheduler", "application title");
    
	    kal.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
						       initWithTitle:NSLocalizedString (@"Today", "today") 
							       style:UIBarButtonItemStyleBordered target:self action:@selector(showAndSelectToday)];
    
	    SSKalDelegate *kalDelegate = [[SSKalDelegate alloc] init];
	    self.sskalDelegate = kalDelegate;
	    kal.delegate = self.sskalDelegate;
	    kal.vcdelegate = self.sskalDelegate;
	    WorkdayDataSource *wds = [[WorkdayDataSource alloc] initWithManagedContext:self.managedObjectContext];
	    dataSource  = wds;
	    kal.dataSource = dataSource;
	    kal.tileDelegate = dataSource;
        
	    if ([self.class enableThinkNoteConfig]) {
		self.rightAS = [[UIActionSheet alloc] initWithTitle:SHARE_STRING delegate:self
						  cancelButtonTitle:NSLocalizedString(@"Cancel", "cancel")
					     destructiveButtonTitle:nil
						  otherButtonTitles:
							  NSLocalizedString(@"Email", "share by mail"),
#if ENABLE_THINKNOTE_SHARE
						      NSLocalizedString(@"ThinkNote", "share by thinknote"),
#endif
						      nil];
        
	    } else {
		self.rightAS = [[UIActionSheet alloc] initWithTitle:SHARE_STRING delegate:self
						  cancelButtonTitle:NSLocalizedString(@"Cancel", "cancel")
					     destructiveButtonTitle:nil
						  otherButtonTitles:
							  NSLocalizedString(@"Email", "share by mail"),
						      nil];

	    }
	    self.rightAS.tag = TAG_MENU;
	    shareButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem: UIBarButtonSystemItemAction
                                                          target:self action:@selector(showRightActionSheet)];
    
	    [UIView beginAnimations:nil context:NULL];
	    [navController setViewControllers:@[kal] animated:NO];
	    [UIView setAnimationDuration:.5];
	    [UIView setAnimationBeginsFromCurrentState:YES];        
	    [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown  forView:navController.view cache:YES];
	    [UIView commitAnimations];

	    [self rightButtonSwitchToShareOrBusy:YES];
	    // 6. setup share operation, and add it in Kal view.
	    _shareC = [[SSShareController alloc] initWithProfilesVC:self.shareProfilesVC withKalController:kal];
    
	    mailAgent = [[SSMailAgent alloc] initWithShareController:_shareC];
    
	    thinkNoteAgent = [[SSThinkNoteShareAgent alloc] initWithSharedObject:_shareC];
    
	    self.tnoteShareVC = [[ThinkNoteShareViewController alloc] initWithNibName:@"ThinkNoteShareViewController" bundle:nil];
	    self.tnoteShareVC.shareC = _shareC;
	    self.tnoteShareVC.shareAgent = thinkNoteAgent;
	    self.tnoteShareVC.shareDelegate = self;
	});
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{


    /*
     *    Kal Initialization
     *
     * When the calendar is first displayed to the user, Kal will automatically select today's date.
     * If your application requires an arbitrary starting date, use -[KalViewController initWithSelectedDate:]
     * instead of -[KalViewController init].
     */
    
    // 1. Kal view controller init.
    
    // 2. shift profile list init functions.
    self.profileView = [[ShiftListProfilesTVC alloc] initWithManagedContext:self.managedObjectContext];
    self.profileView.parentViewDelegate = self;
    self.profileNVC = [[UINavigationController alloc] initWithRootViewController:self.profileView];

    // 3. work days data source init, used by Kal.
    // setup tile view delegate, provides tile icon information.

    
    // 4. init a nav view, used by mail.
    // Setup the navigation stack and display it.

    navController = [[UINavigationController alloc] init];
    navController.view.backgroundColor = [UIColor underPageBackgroundColor];

    self.navController = navController;
    self.navController.modalPresentationStyle = UIModalPresentationFormSheet;

    // a loading button
    UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [activityView sizeToFit];
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
    loadingButton = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    [activityView startAnimating];
    [activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];

    
#if 0
    // 5. alert view for no profiles.
    alertNoProfile = [[UIAlertView alloc] initWithTitle:nil message:CREATE_PROFILE_PROMPT
                                               delegate:self cancelButtonTitle:CREATE_PROFILE_NO
                                      otherButtonTitles:CREATE_PROFILE_YES, nil];
    alertNoProfile.tag = TAG_ZERO_PROFILE;
    
#endif
    
    // setup a alert controller
    alertC = [[SSAlertController alloc] initWithManagedContext:self.managedObjectContext];
    
    if ([self.profileView profileuNumber] == 0)
        [self performSelector:@selector(popNotifyZeroProfile:) withObject:nil afterDelay:1];

    
    // 7. setup up for the tabbar related.
    // add tab bar vc related things.
    tabBarVC = [[UITabBarController alloc] init];
    NSString *iconPath = [[NSBundle mainBundle] pathForResource:@"tab-calendar" ofType:@"png"];
    
#define TAB_ICON_SIZE CGSizeMake(32, 32)
    UIImage *calImage = [[UIImage imageWithContentsOfFile:iconPath]  scaleToSize:TAB_ICON_SIZE onlyIfNeeded:YES];
    self.navController.tabBarItem = [[UITabBarItem alloc]
                                        initWithTitle:NSLocalizedString(@"Calendar", "calendar in tab bar")
                                                image:calImage tag:1];
    [tabBarVC addChildViewController:self.navController];
    
    iconPath = [[NSBundle mainBundle] pathForResource:@"users"
                                               ofType:@"png"];
    UIImage *shiftlistImg = [[UIImage imageWithContentsOfFile:iconPath]  scaleToSize:TAB_ICON_SIZE onlyIfNeeded:YES];
    self.profileView.tabBarItem = [[UITabBarItem alloc]
                                      initWithTitle:NSLocalizedString(@"Shifts", "shifts works in tabbar") 
                                              image:shiftlistImg tag:2];


    UINavigationController *profileNVCC = [[UINavigationController alloc]
                                              initWithRootViewController:self.profileView];
    [tabBarVC addChildViewController:profileNVCC];
    
    iconPath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"png"];
    
    UIImage *settingImg = [[UIImage imageWithContentsOfFile:iconPath]  scaleToSize:TAB_ICON_SIZE onlyIfNeeded:YES];
    self.settingVC.tabBarItem = [[UITabBarItem alloc]
                                    initWithTitle:NSLocalizedString(@"Settings", "Settings")
                                            image:settingImg tag:3];


    UINavigationController *settingNVC = [[UINavigationController alloc]
                                             initWithRootViewController:self.settingVC];
    [tabBarVC addChildViewController:settingNVC];
    
    iconPath = [[NSBundle mainBundle] pathForResource:@"GSFacesInfo" ofType:@"png"];
    
    //    UINavigationController *help = [[UINavigationController alloc] init];
    //    help.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Tips", "tips in tabbar")
    //                                                    image:[UIImage imageWithContentsOfFile:iconPath] tag:4];
    //[tabBarVC addChildViewController:help];
    // help interface
    // [tabBarVC addChildViewController:self.helpView];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [self.window addSubview:tabBarVC.view];

    [self.window makeKeyAndVisible];
    
    
    // default perferences
    NSDictionary *appDefaults = [NSDictionary
                                 dictionaryWithObjects:
                                 @[@(YES),
                                 @(NO),
                                 @"Alarm_Beep_03.caf",
                                 @"Beep",
                                 @[@0,@0],
                                 @(NO),
                                 @(NO)]
                                 forKeys:@[USER_CONFIG_ENABLE_ALERT_SOUND,
                                 USER_CONFIG_USE_SYS_DEFAULT_ALERT_SOUND,
                                 USER_CONFIG_APP_DEFAULT_ALERT_SOUND,
                                 USER_CONFIG_APP_ALERT_SOUND_FILE,
                                 USER_CONFIG_HOLIDAY_REGION,
                                 USER_CONFIG_ENABLE_LUNAR_DAY_DISPLAY,
                                 USER_CONFIG_ENABLE_DISPLAY_OUT_DATE_SHIFT]];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];

    [self performSelectorInBackground:@selector(SSKalControllerInit) withObject:nil];
    
    if (![[NSFileManager defaultManager] respondsToSelector:@selector(ubiquityIdentityToken)]) {
        // iOS 5.x System.
        NSLog(@"ios5 system.");
    } else {
        // iOS 6.x + system.
        id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
        
        if (token) {
            NSLog(@"have icloud");
            // have iClude account;
        } else {
            NSLog(@"don't have icloud");
        }
    }

    
    return YES;
}


- (void) rightButtonSwitchToShareOrBusy:(BOOL) share
{
    if (share)
        [kal.navigationItem setRightBarButtonItem:shareButton];
    else
        [kal.navigationItem setRightBarButtonItem:loadingButton];
}

- (void)popNotifyZeroProfile:(id) sender
{
      [alertNoProfile show];
}

- (void)showRightActionSheet
{
    // friendly for iPAD
    [self.rightAS showFromBarButtonItem: kal.navigationItem.rightBarButtonItem animated:YES];
}

- (SSShareProfileListViewController *)shareProfilesVC
{
    if (shareProfilesVC == nil) {
        shareProfilesVC =  [[SSShareProfileListViewController alloc] initWithManagedContext:self.managedObjectContext];
    }
        
    return shareProfilesVC;
}

- (void)showManageView
{
        //    [self.navController presentModalViewController:self.profileNVC animated:YES];
    [self.navController pushViewController:self.profileView animated:YES];
}

// Action handler for the navigation bar's right bar button item.
- (void)showAndSelectToday
{
    [kal showAndSelectDate:[NSDate date]];
}

- (SSShiftHolidayList *)changelistVC
{
    if (changelistVC)
        return changelistVC;
    changelistVC = [[SSShiftHolidayList alloc] initWithManagedContext:self.managedObjectContext];
    return changelistVC;
}

- (void) showShiftChangeView
{
        //    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:self.changelistVC];
        //   [self.navController presentModalViewController:nvc animated:YES];
    [self.navController pushViewController:self.changelistVC animated:YES];
}

- (SSSettingTVC *) settingVC

{
    if (settingVC == nil)
    {
        settingVC = [[SSSettingTVC alloc] initWithNibName:@"SSSettingTVC" bundle:nil];
        settingVC.managedObjectContext = self.managedObjectContext;
    }
    return settingVC;
}

- (void) showSettingView
{
    [self.navController pushViewController:self.settingVC animated:YES];
}

#pragma mark - alert and action sheet
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) return; // 0 is cancel.

    [self.navController pushViewController:self.profileView animated:YES];
    [self.profileView insertNewProfile:self.navController];    
}

- (void)actionSheet:(UIAlertView *)sender clickedButtonAtIndex:(NSInteger)index
{
    [alertNoProfile dismissWithClickedButtonIndex:alertNoProfile.cancelButtonIndex animated:NO];
    switch (index) {

    case 0:
            [_shareC invaildCache];
            [mailAgent composeMailWithAppDelegate:self withNVC:self.navController];
            break;
    case 1:
            if ([self.class enableThinkNoteConfig]) {
                [_shareC invaildCache];
                [self.navController presentModalViewController:self.tnoteShareVC animated:YES];
            }
        break;
    default:
        break;
    }
    
}

#pragma  mark - share controller delegate

- (void) shareViewControllerfinishShare
{
    [self.navController dismissModalViewControllerAnimated:YES];
}


- (void) didFinishEditingSetting
{
    [self.navController dismissModalViewControllerAnimated:YES];
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    //    NSString *itemName = [notif.userInfo objectForKe	y:ToDoItemKey]
    if (app.applicationState == UIApplicationStateActive) {
        [[[UIAlertView alloc] initWithTitle:notif.alertBody message:nil delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];

        [alertC playAlarmSound];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    [alertC setupAlarm:NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
    [self.rightAS dismissWithClickedButtonIndex:self.rightAS.cancelButtonIndex animated:NO];
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    NSError *error;
    [self.managedObjectContext save:&error];
    [alertC setupAlarm:NO];
    [alertC clearBadgeNumber];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    dispatch_queue_t queue = dispatch_queue_create("start setup", nil);
    dispatch_async(queue, ^{
        [alertC clearBadgeNumber];
        [alertC setupAlarm:YES];
    });
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ShiftScheduler" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ShiftScheduler.sqlite"];
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                                NSInferMappingModelAutomaticallyOption: @(YES)};
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    
    
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (BOOL) enableThinkNoteConfig
{
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    NSArray* languages = [defs objectForKey:@"AppleLanguages"];
    NSString* preferredLang = [languages objectAtIndex:0];
    // Only enable think note for chinese people.
    return [preferredLang isEqualToString:@"zh-Hans"];
}

- (void) shiftModuleMigration
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob"
                                              inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"jobName"  ascending:YES]];
    [request setEntity:entity];
    
    request.fetchBatchSize = 20;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc]
                                       initWithFetchRequest:request
                                       managedObjectContext:self.managedObjectContext
                                       sectionNameKeyPath:Nil cacheName:nil];
    
    NSError *error = nil;
    [frc performFetch:&error];
    if (error) {
        NSLog(@"fetch meeds error when shift module migration:%@", [error userInfo]);
        return;
    }
    
    OneJob *j;
    for (j in frc.fetchedObjects) {
        if ([j convertShiftRoundToJump] == NO) {
            NSLog(@"shift:%@ convert failed", j);
	    [self.managedObjectContext reset];
	    break;
        }
    }

    [self.managedObjectContext save:&error];

    if (error)
        NSLog(@"save manage context error:%@", error.userInfo);

}


@end
