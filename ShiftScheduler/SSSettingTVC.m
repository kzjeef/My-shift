//
//  SSSettingTVC.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSSettingTVC.h"
#import "SSSocialThinkNoteLogin.h"
#import "SSSettingAlarmPickerVC.h"
#import "SSAppDelegate.h"
#import "SSDefaultConfigName.h"
#import "SSSettingHolidayRegionPIckerVC.h"


@implementation SSSettingTVC

#define TELL_OTHER_ITEM_STRING NSLocalizedString(@"Tell a friend", "tell a friend item")
#define EMAIL_SUPPORT_ITEM_STRING NSLocalizedString(@"Email support", "eMail support item")
#define RATING_ITEM_STRING    NSLocalizedString(@"Rating me!", "Rating me item")

#define ENABLE_ALARM_SOUND NSLocalizedString(@"Alert Sound", "enable Alert")
#define PICK_ALERT_SOUND NSLocalizedString(@"Alert", "choose alert sound")

#define LUNAR_ENABLE_ITEM   NSLocalizedString(@"Lunar Calendar", "enable chinese calendar config title")

#define LUNAR_ENABLE_TEIM_HELP NSLocalizedString(@"show chinese lunar calendar", "enable chinese calendar config help")

#define MONDAY_START_ITEM   NSLocalizedString(@"Monday Start", "enable start with monday title.")
#define MONDAY_START_ITEM_HELP   NSLocalizedString(@"change week to monday", "change week start with monday help")

#define HOLIDAY_PICK_ITEM   NSLocalizedString(@"Region Holidays", "enable chinese calendar config title")

#define HOLIDAY_PICK_ITEM_HLEP NSLocalizedString(@"show region(s) holiday on calendar", "show region hlidays help")

#define LOGIN_THINKNOTE_ITEM    NSLocalizedString(@"Login ThinkNote", "thinkNote Login")

#define CANCEL_STR NSLocalizedString(@"Cancel", "cancel")

#define RESET_STR NSLocalizedString(@"Reset All Data", "reset")
#define RESET_WARNNING_STR NSLocalizedString(@"This will delete all Shift information in your application, are you sure ?", \
                                             "long warnning information before delete all data")


@synthesize iTunesURL;

enum {
    SSSNAME_SECTION = 0,
    SSAPPCFG_SECTION,
    SSALARM_SECTION,
    SSSOCIAL_SECTION,
    SSFEEDBACK_SECTION,
    SSRESET_SECTION,
    SSSECTIONS_COUNT,
};

enum {
    SSSETTING_SOCIAL_THINKNOTEK = 0,
};

enum {
    SSSETTING_APPCFG_LUNAR_ENABLE = 0,
    SSSETTING_APPCFG_MONDAY_ENABLE,
    SSSETTING_APPCFG_HOLIDAY_PICK,
};

enum {
    SSSETTING_TAG_SYSALARM_ENABLE = 0,
    SSSETTING_TAG_APPCFG_LUNAR_ENABLE = 1,
    SSSETTING_TAG_APPCFG_MONDAY_ENABLE,
};

- (NSArray *) appConfigHelpArray
{
    if (!appConfigHelpArray)
        appConfigHelpArray = @[ LUNAR_ENABLE_TEIM_HELP,
                                MONDAY_START_ITEM_HELP,
                                HOLIDAY_PICK_ITEM_HLEP];

    return appConfigHelpArray;
}

- (NSArray *) appConfigArray
{
    if (!appConfigArray)
      appConfigArray = @[ LUNAR_ENABLE_ITEM,
                          MONDAY_START_ITEM,
                          HOLIDAY_PICK_ITEM];

    return appConfigArray;
}

- (NSArray *) alarmSettingsArray
{
    if (!alarmSettingsArray)
        alarmSettingsArray = @[ENABLE_ALARM_SOUND, PICK_ALERT_SOUND];

    return alarmSettingsArray;
}



- (NSArray *) socialAccountArray
{
    if (!socialAccountArray) {
        socialAccountArray = @[LOGIN_THINKNOTE_ITEM];
    }
    return socialAccountArray;
}

- (NSArray *) feedbackItemsArray
{
    if (!feedbackItemsArray) {
        feedbackItemsArray = @[TELL_OTHER_ITEM_STRING,
        EMAIL_SUPPORT_ITEM_STRING,
        RATING_ITEM_STRING];
    }
    return feedbackItemsArray;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", "Settings");
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _thinknoteLogin = [[SSSocialThinkNoteLogin alloc]init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socialSettingChanged)
                                                 name:SSSocialAccountChangedNotification
                                               object:nil];

}

- (void) socialSettingChanged
{
    NSIndexSet *update = [[NSIndexSet alloc] initWithIndex:SSSOCIAL_SECTION];
    [self.tableView reloadSections:update
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void) switchChanged: (id) sender
{
    UISwitch *s = sender;
    
    if (s.tag == SSSETTING_TAG_SYSALARM_ENABLE) {
        [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:USER_CONFIG_ENABLE_ALERT_SOUND];
    }  else if (s.tag == SSSETTING_TAG_APPCFG_LUNAR_ENABLE) {
        [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:USER_CONFIG_ENABLE_LUNAR_DAY_DISPLAY];
    } else if (s.tag == SSSETTING_TAG_APPCFG_MONDAY_ENABLE) {
        [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:USER_CONFIG_ENABLE_MONDAY_DISPLAY];
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_LOCAL_NOTIFY_WEEK_START_CHANGED object:[NSNumber numberWithBool:s.on]];
    }
}

- (UISwitch *)newSwitch:(NSIndexPath *)indexPath withTag:(NSInteger) tag
{
    
    UISwitch *theSwitch;
    CGRect frame = CGRectMake(210, 8.0, 120.0, 27.0);
    theSwitch = [[UISwitch alloc] initWithFrame:frame];
    [theSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    // in case the parent view draws with a custom color or gradient, use a transparent color
    theSwitch.backgroundColor = [UIColor clearColor];
    theSwitch.tag = tag;
    return theSwitch;
}


#pragma mark - Table view data source


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return Nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return SSSECTIONS_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == SSSNAME_SECTION)
        return 1;
    if (section == SSFEEDBACK_SECTION)
        return self.feedbackItemsArray.count;
    if (section == SSAPPCFG_SECTION)
        return self.appConfigArray.count;
    if (section == SSALARM_SECTION)
        return self.alarmSettingsArray.count;
    if (section == SSSOCIAL_SECTION) {
        if ([SSAppDelegate enableThinkNoteConfig])
            return self.socialAccountArray.count;
        else
            return 0;
            
    }
    if (section == SSRESET_SECTION)
        return 1;
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SSSNAME_SECTION)
        return tableView.rowHeight * 1.5;
    else
        return tableView.rowHeight;
}

- (void) setupCellForSocialSection:(UITableViewCell *) cell
                                          index: (NSIndexPath *)indexPath
{
    cell.textLabel.text = [self.socialAccountArray objectAtIndex:indexPath.row];
    
    switch (indexPath.row) {
        case SSSETTING_SOCIAL_THINKNOTEK:
        {
            NSString *loginPasswd = [[NSUserDefaults standardUserDefaults] objectForKey:kThinkNoteLoginPassword];
            if ([loginPasswd length] == 0)
                cell.detailTextLabel.text = NSLocalizedString(@"No Bound","no bould string in setting");
            else {
                cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:kThinkNoteLoginName];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
        }
        default:
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingCell";
    static NSString *nameCell = @"ShiftName";
    static NSString *appcfgCell = @"appConfig";
    UITableViewCell *cell;

    if (indexPath.section == SSSNAME_SECTION) {
        cell = [tableView dequeueReusableCellWithIdentifier:nameCell];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:nameCell];
        }

    } else if (indexPath.section == SSAPPCFG_SECTION) {
        cell = [tableView dequeueReusableCellWithIdentifier:appcfgCell];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:appcfgCell];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
    }
    
    cell.detailTextLabel.text = nil;
    
    if (indexPath.section == SSSNAME_SECTION) {
        cell.backgroundColor = [UIColor groupTableViewBackgroundColor];
        cell.textLabel.text = NSLocalizedString(@"Shift Scheduler", "");
        cell.textLabel.font = [UIFont systemFontOfSize:24];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    } else if (indexPath.section == SSAPPCFG_SECTION) {
        cell.textLabel.text = [self.appConfigArray objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = [self.appConfigHelpArray objectAtIndex:indexPath.row];
        
        if (indexPath.row == SSSETTING_APPCFG_LUNAR_ENABLE) {
            UISwitch *s = [self newSwitch:indexPath withTag:SSSETTING_TAG_APPCFG_LUNAR_ENABLE];
            BOOL enableLunar = [[NSUserDefaults standardUserDefaults] boolForKey:USER_CONFIG_ENABLE_LUNAR_DAY_DISPLAY];
            s.on = enableLunar;
            [cell.contentView addSubview:s];
        } else if (indexPath.row == SSSETTING_APPCFG_MONDAY_ENABLE) {
            UISwitch *s = [self newSwitch:indexPath withTag:SSSETTING_TAG_APPCFG_MONDAY_ENABLE];
            BOOL enableMondayFirst = [[NSUserDefaults standardUserDefaults] boolForKey:USER_CONFIG_ENABLE_MONDAY_DISPLAY];
            s.on = enableMondayFirst;
            [cell.contentView addSubview:s];
        } else if (indexPath.row == SSSETTING_APPCFG_HOLIDAY_PICK) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == SSFEEDBACK_SECTION) {
        cell.textLabel.text = [self.feedbackItemsArray objectAtIndex:indexPath.row];
    } else if (indexPath.section == SSSOCIAL_SECTION) {
        [self setupCellForSocialSection:cell index: indexPath];
    } else if (indexPath.section == SSALARM_SECTION) {
        cell.textLabel.text = [self.alarmSettingsArray objectAtIndex:indexPath.row];
        
        UISwitch *s = [self newSwitch:indexPath withTag:SSSETTING_TAG_SYSALARM_ENABLE];
        BOOL enableSound = [[NSUserDefaults standardUserDefaults] boolForKey:USER_CONFIG_ENABLE_ALERT_SOUND];
        if (indexPath.row == 0) { // enable sound.
            s.on = enableSound;
            [cell.contentView addSubview:s];
        } else if (indexPath.row == 1) {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            if (!enableSound)
                cell.textLabel.textColor = [UIColor grayColor];
            else
                cell.textLabel.textColor = [UIColor blackColor];
            
            cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:USER_CONFIG_APP_ALERT_SOUND_FILE];



            // TODO Set the current selected Alarm in the detail label
                     
        }
        
    } else if (indexPath.section == SSRESET_SECTION) {
        cell.textLabel.text = RESET_STR;
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redButtonBackgroud"]];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor colorWithWhite:.1 alpha:0];
    }
    
    return cell;
}


#pragma mark - Table view delegate



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    NSString *supprt_mail = @"zhangjeef@gmail.com";
    NSString *support_title = NSLocalizedString(@"[SSS] ShiftSheduler support", "shift sheduler support");
    NSString *support_body = [NSString stringWithFormat:@"\n\n\n---\nApp Version: %@ \nCurrent TimeZone:%@\niOS Version:%@",
                              [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]],
                              [NSTimeZone systemTimeZone],
                              versionCompatibility
                              ];
    
    NSString *tel_other_title = NSLocalizedString(@"Check this app: Shift Sheduler", "");
    NSString *tel_other_body  = NSLocalizedString(@"Hi, \n I found a very interesting app, and I think it will help for you, check it out!\n Link is: http://itunes.apple.com/us/app/shift-scheduler/id482061308?mt=8", "");
    
    if (indexPath.section == SSSOCIAL_SECTION) {
        if ([LOGIN_THINKNOTE_ITEM isEqualToString:
             [self.socialAccountArray objectAtIndex:indexPath.row]]) {
            [_thinknoteLogin showThinkNoteLoingView];
        }
        return;
    } else if (indexPath.section == SSAPPCFG_SECTION) {
        if (indexPath.row == SSSETTING_APPCFG_HOLIDAY_PICK) {
            SSSettingHolidayRegionPIckerVC *vc = [[SSSettingHolidayRegionPIckerVC alloc] initWithStyle:UITableViewStylePlain];
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else if (indexPath.section == SSFEEDBACK_SECTION) {
        
        if ( [TELL_OTHER_ITEM_STRING isEqualToString:[self.feedbackItemsArray objectAtIndex:indexPath.row]])
            [self sendEMailTo:@"" WithSubject:tel_other_title withBody:tel_other_body];
        
        else if ( [EMAIL_SUPPORT_ITEM_STRING isEqualToString:[self.feedbackItemsArray objectAtIndex:indexPath.row]]) {
            [self sendEMailTo:supprt_mail WithSubject:support_title withBody:support_body];
        }
        
        else if ( [RATING_ITEM_STRING isEqualToString: [self.feedbackItemsArray objectAtIndex:indexPath.row]]) {
            NSString *str = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=482061308";
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
        }
    } else if (indexPath.section == SSALARM_SECTION) {
        if (indexPath.row == 1) {
            BOOL enableSound = [[NSUserDefaults standardUserDefaults] boolForKey:USER_CONFIG_ENABLE_ALERT_SOUND];
            if (!enableSound)
                return;
            SSSettingAlarmPickerVC  *view = [[SSSettingAlarmPickerVC alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:view animated:YES];
        }
    } else if (indexPath.section == SSRESET_SECTION) {
        [[[UIAlertView alloc] initWithTitle:RESET_STR message:RESET_WARNNING_STR delegate:self
                          cancelButtonTitle:RESET_STR otherButtonTitles:NSLocalizedString(@"Cancel", "cancel") ,nil] show];

    }
    
    
}

#pragma mark - delete shift functions

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
        [self deleteAllShifts];
    else if (buttonIndex == 1)
        return; // 0 is cancel.
    
}

- (void) sendEMailTo: (NSString *)to WithSubject: (NSString *) subject withBody:(NSString *)body {
    NSString *mailString =  [NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
                             [to stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailString]];
    
}

-(void) deleteAllShifts
{
    [self deleteAllObjects:@"OneJob"];
}

- (void) deleteAllObjects: (NSString *) entityDescription
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    
    
    for (NSManagedObject *managedObject in items) {
    	[_managedObjectContext deleteObject:managedObject];
    	NSLog(@"%@ object deleted",entityDescription);
    }
    if (![_managedObjectContext save:&error]) {
    	NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }
    
}


@end
