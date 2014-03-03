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

#define kDoSyncItem NSLocalizedString(@"Perform Sync", "")
#define kAlertInCalendarItem NSLocalizedString(@"Alert In Calendar", "")
#define kShiftSelectItem     NSLocalizedString(@"Select Shift to Sync", "")
#define kLengthItem              NSLocalizedString(@"Length", "")
#define kDeleteEventsItem    NSLocalizedString(@"Delete Synced Events", "")

#define kEnableAutoSyncDetail NSLocalizedString(@"", "")
#define kAlertInCalendarDetail NSLocalizedString(@"setup same alarm as shift setting", "")
#define kShiftSelectDetail     NSLocalizedString(@"default sync all enabled shift", "")
#define kLengthDetail    NSLocalizedString(@"", "")
#define kDeleteEventsDetail   NSLocalizedString(@"", "")

#define kLengthSelectionWeek NSLocalizedString(@"One Week", "")
#define kLengthSelection2Week NSLocalizedString(@"Two Week", "")
#define kLengthSelectionMonth NSLocalizedString(@"One Month", "")
#define kLengthSelection3Month NSLocalizedString(@"Three Month", "")

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
        _lengthDict = @{kLengthSelectionWeek : @7, kLengthSelection2Week: @14, kLengthSelectionMonth:@31, kLengthSelection3Month:@93};

    return _lengthDict;
}

- (NSArray *) lengthArray {
    if (_lengthArray == nil)
        _lengthArray = @[kLengthSelectionWeek, kLengthSelection2Week, kLengthSelectionMonth, kLengthSelection3Month];
    return _lengthArray;
}

- (NSArray*) menuArray {
  if (_menuArray == nil)
    _menuArray = @[@[
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

    self.title = NSLocalizedString(@"Sync to Phone Calendar", "");
    
    UIImage *menuIcon = [UIImage imageNamed:@"menu.png"];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:menuIcon 
                                                                   style:UIBarButtonItemStylePlain  
                                                                  target:self 
                                                                  action:@selector(menuButtonClicked)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    self.busyIndicator.frame = self.view.frame;
    self.busyIndicator.center = self.view.center;

    [self.view insertSubview:self.busyIndicator aboveSubview:self.tableView];
    
    self.alarmSwitch.on = [SSCalendarSyncController getAlarmSyncSetting];
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
        return @"Perform sync shift event from scheudler to phone calendar";
    else if (section == 1)
        return @"Sync the length days shift events of selected shift to phone calendar. Calendar events will be re created for any setting changes. ";
    else if (section == 2)
        return @"Delete all events created by scheduler from phone calendar";
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

    if ([cell.textLabel.text compare:kDoSyncItem] == NSOrderedSame) {
        [self.enableSyncSwitch adjustFrameForTableViewCell:cell];
        
    } else if ([cell.textLabel.text compare:kAlertInCalendarItem] == NSOrderedSame) {
        [self.alarmSwitch adjustFrameForTableViewCell:cell];
        [cell.contentView addSubview:self.alarmSwitch];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if ([cell.textLabel.text compare:kDeleteEventsItem] == NSOrderedSame) {
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
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


// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [[self.menuArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    int count;
    
    if (title == kDoSyncItem) {
        [self.busyIndicator startAnimating];
        count = [self.calendarSyncController setupAllEKEvent];
        [self.busyIndicator stopAnimating];
        NSString *str = [NSString stringWithFormat:@"%d calendar events are sync to phone calendar", count];
        if (count == 0)
            str = @"No new calendar event was added in phone calendar";
        UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"Done" message:str delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [v show];
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
        int count = [self.calendarSyncController deleteAllEKEvents];
        [self.busyIndicator stopAnimating];
        
        NSString *str = [NSString stringWithFormat:@"%d calendar events are delete.", count];
        if (count == 0)
            str =  @"No calendar event was deleted. ";
        UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"Done" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [v show];
    }
}

- (IBAction)enableSyncValueChanged:(id)sender {
    UISwitch *s = sender;

    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey: kSSCalendarAutoSyncSetting];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSSCalendarAutoSyncSettingChangedNotification object:nil];
}

- (IBAction)enableAlarmSwitchValueChanged:(id)sender {
    UISwitch *s = sender;

    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey: kSSCalendarWithAlarmSetting];
    [[NSNotificationCenter defaultCenter] postNotificationName: kSSCalendarWithAlarmSettingChangedNotification object:nil];
}

- (void) changedLengthValue:(NSNumber *)n {
    [[NSUserDefaults standardUserDefaults] setValue:n forKey:kSSCalendarSyncLengthSetting];
    [[NSNotificationCenter defaultCenter] postNotificationName: kSSCalendarSyncLengthSettingChangedNotification object:nil];
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
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.busyIndicator startAnimating];
    NSString *key = [self.lengthArray objectAtIndex:row];
    NSNumber *n = [self.lengthDict objectForKey:key];
    [self changedLengthValue:n];
    [self.busyIndicator stopAnimating];
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
    }
    [self.calendarSyncController saveShiftChange];
}

- (void)shiftSelect:(id)sender cancelButtonClicked:(NSDictionary *)states {}
- (void) shiftSelect:(id)sender newState:(BOOL)newState {}


@end
