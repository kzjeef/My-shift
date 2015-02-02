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
#import "UISwitch+AdjustForTableViewCell.h"
#import "I18NStrings.h"



@implementation SSSettingTVC
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
    SSSETTING_APPCFG_HOLIDAY_PICK,
    SSSETTING_APPCFG_MONDAY_ENABLE,
};

enum {
    SSSETTING_TAG_SYSALARM_ENABLE = 0,
    SSSETTING_TAG_APPCFG_LUNAR_ENABLE = 1,
    SSETTING_TAG_APPCFG_MONDAY_ENABLE,
};

- (NSArray *) appConfigHelpArray
{
    if (!appConfigHelpArray)
        appConfigHelpArray = @[LUNAR_ENABLE_TEIM_HELP, HOLIDAY_PICK_ITEM_HLEP];

    return appConfigHelpArray;
}

- (NSArray *) appConfigArray
{
    if (!appConfigArray)
        appConfigArray = @[ LUNAR_ENABLE_ITEM, HOLIDAY_PICK_ITEM];

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
        feedbackItemsArray = @[TELL_OTHER_ITEM_STRING, EMAIL_SUPPORT_ITEM_STRING, RATING_ITEM_STRING];
    }
    return feedbackItemsArray;
}

- (void)menuButtonClicked
{
    if (self.menuDelegate) {
        [self.menuDelegate SSMainMenuDelegatePopMainMenu:self];
    }
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    [super viewDidLoad];
    
    //    self.tableView.separatorColor = [UIColor colorWithRed:150/255.0f green:161/255.0f blue:177/255.0f alpha:1.0f];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.title = NSLocalizedString(@"Settings", "Settings");
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIImage *menuIcon = [UIImage imageNamed:@"menu.png"];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:menuIcon 
                                                                   style:UIBarButtonItemStylePlain  
                                                                  target:self 
                                                                  action:@selector(menuButtonClicked)];
    self.navigationItem.leftBarButtonItem = menuButton;


    _thinknoteLogin = [[SSSocialThinkNoteLogin alloc]init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socialSettingChanged)
                                                 name:SSSocialAccountChangedNotification
                                               object:nil];

}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != SSRESET_SECTION) {
        //        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor colorWithRed:62/255.0f green:68/255.0f blue:75/255.0f alpha:1.0f];
    }
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17];

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
    } else if (s.tag == SSETTING_TAG_APPCFG_MONDAY_ENABLE) {
        [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:USER_CONFIG_ENABLE_MONDAY_DISPLAY];
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_LOCAL_NOTIFY_WEEK_START_CHANGED object:[NSNumber numberWithBool:s.on]];
    }
}

- (UISwitch *)newSwitch:(NSIndexPath *)indexPath withTag:(NSInteger) tag cell:(UITableViewCell*) cell
{
    UISwitch *theSwitch = [[UISwitch alloc] init];

    [theSwitch adjustFrameForTableViewCell: cell];
    [theSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    // in case the parent view draws with a custom color or gradient, use a transparent color
    theSwitch.backgroundColor = [UIColor clearColor];
    theSwitch.tag = tag;
    return theSwitch;
}


#pragma mark - Table view data source

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
    if (tableView.rowHeight == -1)
        return tableView.rowHeight;

    if (indexPath.section == SSSNAME_SECTION)
        return tableView.rowHeight * 1.33;
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
        cell.textLabel.text = APP_NAME_STR;
        cell.textLabel.font = [UIFont systemFontOfSize:24];
        cell.userInteractionEnabled = NO;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    } else if (indexPath.section == SSAPPCFG_SECTION) {
        cell.textLabel.text = [self.appConfigArray objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = [self.appConfigHelpArray objectAtIndex:indexPath.row];
        
        if (indexPath.row == SSSETTING_APPCFG_LUNAR_ENABLE) {
            UISwitch *s = [self newSwitch:indexPath withTag:SSSETTING_TAG_APPCFG_LUNAR_ENABLE cell:cell];
            BOOL enableLunar = [[NSUserDefaults standardUserDefaults] boolForKey:USER_CONFIG_ENABLE_LUNAR_DAY_DISPLAY];
            s.on = enableLunar;
            [cell.contentView addSubview:s];
        } else if (indexPath.row == SSSETTING_APPCFG_MONDAY_ENABLE) {
            UISwitch *s = [self newSwitch:indexPath withTag:SSETTING_TAG_APPCFG_MONDAY_ENABLE cell:cell];
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
        
        UISwitch *s = [self newSwitch:indexPath withTag:SSSETTING_TAG_SYSALARM_ENABLE cell:cell];
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
        //       cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redButtonBackgroud"]];
        cell.textLabel.textColor = [UIColor redColor];
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
            SSSettingAlarmPickerVC  *view = [[SSSettingAlarmPickerVC alloc] initWithNibName:@"SSSettingAlarmPickerVC" bundle:nil];
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
