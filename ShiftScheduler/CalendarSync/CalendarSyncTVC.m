//
//  CalendarSyncTVC.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-2-20.
//
//

#import "CalendarSyncTVC.h"
#import "UISwitch+AdjustForTableViewCell.h"
#import "SSCalendarSyncController.h"
#import "UIActivityIndicatorView+BigRound.h"
#import "config.h"

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


/// TODO: add note to user, event it's a auto sync, it's still require
/// user open the app after the length of further time is about to
/// expired.

@interface CalendarSyncTVC ()
@property (nonatomic, strong) NSArray *menuArray;
@property (nonatomic, strong) NSArray *detailArray;
@property (nonatomic, strong) NSDictionary *lengthDict;
@property (nonatomic, strong) NSArray *lengthArray;
@property (nonatomic, strong) IBOutlet UISwitch  *enableSyncSwitch;
@property (nonatomic, strong) IBOutlet UISwitch  *alarmSwitch;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicator;
@property                       BOOL    eventProcessWorking;
@property                       BOOL    disabled;
- (IBAction)enableSyncValueChanged:(id)sender;
- (IBAction)enableAlarmSwitchValueChanged:(id)sender;
@end


@implementation CalendarSyncTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark varrible init

- (NSDictionary *) lengthDict {
    if (_lengthDict == nil)
        _lengthDict = @{kLengthSelectionWeek : @7, kLengthSelection2Week: @14, kLengthSelectionMonth:@31};

    return _lengthDict;
}

- (NSArray *) lengthArray {
    if (_lengthArray == nil)
        _lengthArray = @[kLengthSelectionWeek, kLengthSelection2Week, kLengthSelectionMonth];
    return _lengthArray;
}

- (NSArray*) menuArray {
  if (_menuArray == nil)
    _menuArray = @[@[
            kEnableCalendarSync,
                     kDoSyncItem
                     ],
                   @[
                     kAlertInCalendarItem,
                     kLengthItem,
                     kShiftSelectItem,
                    ],
                   @[
                     kDeleteEventsItem
                     ]
                   ];
  return _menuArray;
}

- (NSArray *) detailArray {
    if (_detailArray == nil)
        _detailArray = @[ @[
                          @"",
                          @"",
                          ],
                      @[
                          kAlertInCalendarDetail,
                          kLengthDetail,
                          kShiftSelectDetail,],
                      @[
                          kDeleteEventsDetail,]
                      ];
    return _detailArray;
}

#pragma mark Table View deletage

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;

    self.title = kCalendarSyncTitle;
    
    UIImage *menuIcon = [UIImage imageNamed:@"menu.png"];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:menuIcon 
                                                                   style:UIBarButtonItemStylePlain  
                                                                  target:self 
                                                                  action:@selector(menuButtonClicked)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    [self.busyIndicator setupRoundCorner:100];
    self.busyIndicator.center = self.view.center;

    [self.view insertSubview:self.busyIndicator aboveSubview:self.tableView];
    
    self.alarmSwitch.on = [SSCalendarSyncController getAlarmSyncSetting];

    self.enableSyncSwitch.on = [SSCalendarSyncController getCalendarSyncEnable];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(calendarEventProcessStart)
                                                 name: kSSCalendarSyncStartNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(calendarEventProcessFinish:)
                                                 name: kSSCalendarSyncStopNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(calendarEventProcessError:)
                                                 name: kSSCalendarSyncErrorNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(calendarEnableChanged)
                                                 name: kSSCalendarSyncEnableSettingChangedNotification
                                               object:nil];
 
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.menuArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

    if (section == 0)
        return kCalenderSyncDetail;
    else if (section == 1)
        return kCalendarLengthDetal;
    else if (section == 2)
        return kCalendarDeleveDetail;
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.menuArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"CellCalendarSyncMenu";
    UITableViewCellStyle style = UITableViewCellStyleSubtitle;
    
    NSString *text = [[self.menuArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if ([text compare:kLengthItem] == NSOrderedSame) {
        CellIdentifier = @"CellCalendarSyncMenuValue";
        style = UITableViewCellStyleValue1;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:CellIdentifier];
    }
  
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.text = [[self.menuArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [[self.detailArray objectAtIndex:indexPath.section] objectAtIndex: indexPath.row];

    if ([cell.textLabel.text compare:kEnableCalendarSync ] == NSOrderedSame) {
        [self.enableSyncSwitch adjustFrameForTableViewCell:cell];
        if ([cell.contentView.subviews indexOfObject:self.enableSyncSwitch] == NSNotFound)
            [cell.contentView addSubview:self.enableSyncSwitch];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

   } else if ([cell.textLabel.text compare:kDoSyncItem] == NSOrderedSame) {
        cell.textLabel.textColor = UIColorFromRGB(0x0466C0);
        NSString *syncIconPath = [[NSBundle mainBundle] pathForResource:@"sync-icon" ofType:@"png"];
       if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
           cell.imageView.image = [[[UIImage alloc] initWithContentsOfFile:syncIconPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
           cell.imageView.tintColor = UIColorFromRGB(0x0466C0);
       }

    } else if ([cell.textLabel.text compare:kAlertInCalendarItem] == NSOrderedSame) {
        [self.alarmSwitch adjustFrameForTableViewCell:cell];
        [cell.contentView addSubview:self.alarmSwitch];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    } else if ([cell.textLabel.text compare:kDeleteEventsItem] == NSOrderedSame) {
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        NSString *removeIconPath = [[NSBundle mainBundle] pathForResource:@"remove" ofType:@"png"];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            cell.imageView.image = [[[UIImage alloc] initWithContentsOfFile:removeIconPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imageView.tintColor = [UIColor redColor];
        }
        [cell.textLabel sizeToFit];

    } else if ([cell.textLabel.text compare:kLengthItem] == NSOrderedSame) {
        cell.detailTextLabel.text = [self getStringLength];
    }
    
    if ([cell.textLabel.text compare:kLengthItem] == NSOrderedSame
        || [cell.textLabel.text compare:kShiftSelectItem] == NSOrderedSame) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}
#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.disabled)
        return nil;
    else
        return indexPath;
}

- (void) notifyUserEnableCalendarAccess {
    
    UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"" message:kSSCalendarAccessError delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [v show];
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [[self.menuArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    if (title == kDoSyncItem) {
        [self.busyIndicator startAnimating];
        [self.calendarSyncController deleteAndSetupEvents:YES];
        //        [self.calendarSyncController setupAllEKEvent:YES];
    }
    if (title == kLengthItem) {
        SSSingleSelectTVC *select = [[SSSingleSelectTVC alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:select];
        
        select.tableData = self.lengthArray;
        select.delegate = self;
        select.selectedRow = [self.lengthArray  indexOfObject:[self getStringLength]];
        select.navigationItem.title = kLengthItem;
        [self presentViewController:navController animated:YES completion:nil];
    }

    if (title == kShiftSelectItem) {
        SSShiftMultipSelectTVC *select = [[SSShiftMultipSelectTVC alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:select];
        NSMutableArray *array = [[NSMutableArray alloc] init];
       NSArray *list = [self.calendarSyncController getAllShiftList];
        for (OneJob *s in list)
            [array addObject:s.objectID];
        select.items = array;
        select.delegate = self;
        select.navigationItem.title = kShiftSelectItem;
        [self presentViewController: navController animated: YES completion:nil];
    }

    if (title == kDeleteEventsItem) {
        [self.busyIndicator startAnimating];
        [self.calendarSyncController deleteAllEKEvents];

    }
}

- (IBAction)enableSyncValueChanged:(id)sender {
    UISwitch *s = sender;
    
    [[NSUserDefaults standardUserDefaults] setBool: s.on forKey: kSSCalendarSyncEnableSetting];
    [self calendarEnable: s.on];
}

- (IBAction)enableAlarmSwitchValueChanged:(id)sender {
    UISwitch *s = sender;
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey: kSSCalendarWithAlarmSetting];
    [[NSNotificationCenter defaultCenter] postNotificationName: kSSCalendarWithAlarmSettingChangedNotification object:nil];
}

- (void) changedLengthValue:(NSNumber *)n {
    [[NSUserDefaults standardUserDefaults] setValue:n forKey:kSSCalendarSyncLengthSetting];
    [[NSNotificationCenter defaultCenter] postNotificationName: kSSCalendarSyncLengthSettingChangedNotification object:nil];
    // Because this notification will result calendar sync controller start work,
    // so the busy indicator will start.
}

- (void)menuButtonClicked
{
    if (self.menuDelegate) {
        [self.menuDelegate SSMainMenuDelegatePopMainMenu:self];
    }
}

- (NSString *) getStringLength {
   int n =  [SSCalendarSyncController getSyncLengthSetting];
    NSString *str;
   
    for (NSString *key in [self.lengthDict allKeys]) {
        NSNumber *t = [self.lengthDict objectForKey:key];
        if (t.intValue == n)
            str = key;
    }
    if (str == nil)
        str = kLengthSelectionWeek;
    return str;
}

- (void)singleSelect: (id) sender itemSelectedatRow:(NSInteger) row {

    __block CalendarSyncTVC *blk_self = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (blk_self.eventProcessWorking)
            [blk_self _calendarEventStart];
    }];
    NSString *key = [self.lengthArray objectAtIndex:row];
    NSNumber *n = [self.lengthDict objectForKey:key];
    [self _calendarEventStart];
    [self changedLengthValue:n];
    [self.tableView reloadData];
}

- (NSString *) shiftSelect:(id)sender objectTitle:(id)item {
    
    OneJob *j = [self.calendarSyncController getShiftWithID:item];
    if (j)
        return j.jobName;
    else
        return @"<Error>";
}

- (BOOL) shiftSelect:(id)sender shouldSelectItem:(id)item {
    OneJob *j = [self.calendarSyncController getShiftWithID:item];
    if (j)
        return j.syncEnableEKEvent.integerValue == 1;
    else
        return NO;
}

- (void) shiftSelect:(id)sender doneButtonClicked:(NSDictionary *)states {
    for (NSManagedObjectID *objid in states.allKeys) {
        OneJob *j = [self.calendarSyncController getShiftWithID:objid];
        if (j) {
            j.syncEnableEKEvent = [states objectForKey:objid];
        }
        [self.calendarSyncController saveShiftChange];
    }
    // After save, the controller will perform the operation in the case.
    // so it will be a busy indicator show up.
    __block CalendarSyncTVC *blk_self = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (blk_self.eventProcessWorking)
            [blk_self _calendarEventStart];
    }];
}

- (void)shiftSelect:(id)sender cancelButtonClicked:(NSDictionary *)states {}
- (void) shiftSelect:(id)sender newState:(BOOL)newState {}

#pragma mark "Notification handlers"
/// Do thing when sync finish, or error. 
- (void) _calendarEventDone {
    self.disabled = NO;
    self.enableSyncSwitch.enabled = YES;
    self.alarmSwitch.enabled = YES;
    [self.busyIndicator stopAnimating];
    self.eventProcessWorking = NO;
}


/// Do things when start sync
- (void) _calendarEventStart {
    if (self.view.window) {
        [self.busyIndicator startAnimating];
        self.disabled = YES;
        self.enableSyncSwitch.enabled = NO;
        self.alarmSwitch.enabled = NO;
    }
    self.eventProcessWorking = YES;
}

- (void) calendarEventProcessFinish: (NSNotification *) notify {
    [self _calendarEventDone];
    if ([notify.object isKindOfClass:NSDictionary.class]) {
        //        NSDictionary *dict = notify.object;
        //        NSInteger count = [[dict objectForKey:@"count"] integerValue];
        //        SSCalendarEventType type = [[dict objectForKey:@"type"] intValue];
 
        //        if (type == SSCalendarEventTypeSetup) {
            //            NSString *str = [NSString stringWithFormat:kCalendarSyncToPhoneFmt, count];
            // if (count == 0)
            //   str = kCalendarSyncToPhoneNoAdd;
            //            UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"" message:str delegate:nil
            //                                              cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //            [v show];
            //    not show the alert is better
            //        } else if (type == SSCalendarEventTypeDelete) {
            //            NSString *str = [NSString stringWithFormat:kCalendarSyncToPhoneDel, count];
            //            if (count == 0)
            //                str = kCalendarSyncToPhoneNoDel;
            //            UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //            [v show];
            // not show the alert is better.
            
            //        }
    }
}

- (void) calendarEventProcessStart {
    // This event can be sent even the window not there,
    // so if not show, don't show this animation.
    [self _calendarEventStart];
}

- (void) calendarEventProcessError: (NSNotification *) notify {
    [self _calendarEventDone];

    NSString *error = notify.object;
    if ([error isEqualToString: kSSCalendarSyncNoCalenarAccess]) {
        [self notifyUserEnableCalendarAccess];
    } else if ([error isEqualToString: kSSCalendarSyncNotEnable]) {
        // Not enable, do nothing...
    }
}

- (void) calendarEnable:(BOOL) enable {

    if (enable) {
    // Need enable the manual sync index path.
    // and delete button.
    } else {

        // disable manual sync button
        // disable delete button.
    }

}

- (void) calendarEnableChanged {
    // if disable , need disable the manual sync and delete access.
// also gray them out.
    BOOL on = [SSCalendarSyncController getCalendarSyncEnable];
    [self calendarEnable:on];
}


@end
