//
//  SSProfileTimeAndAlarmVC.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSProfileTimeAndAlarmVC.h"
#import "NSDateAdditions.h"
#import "SSProfileReminderDateSource.h"
#import "UITableViewCell+DoneButton.h"

enum {
    CLOCK_IN_ITEM = 0,
    HOURS_ITEM,
    REMIND_BEFORE_WORK_ITEM,
    REMIND_BEFORE_OFF_ITEM,
};

#define PICKER_VIEW_BEFORE_WORK 2
#define PICKER_VIEW_BEFORE_OFF 3

@implementation SSProfileTimeAndAlarmVC

@synthesize dateFormatter, theJob, startDatePicker, lengthDatePicker, onAlertPicker, offAlertPicker, firstChooseIndexPath;

+ (NSArray *) returnItemArray {
    return @[FROM_ITEM_STRING,
            HOURS_ITEM_STRING,
            REMIND_BEFORE_WORK,
            REMIND_BEFORE_CLOCK_OFF];
}

- (NSArray *) itemsArray
{
    if (!itemsArray) {
        itemsArray = [[self class] returnItemArray];
    }
    return itemsArray;
}

- (NSDateFormatter *) dateFormatter
{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    }
    return dateFormatter;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.startDatePicker = [[UIDatePicker alloc] init];
        self.startDatePicker.timeZone = [NSTimeZone defaultTimeZone];
 
        
        self.lengthDatePicker = [[UIDatePicker alloc] init];
        self.lengthDatePicker.timeZone = [NSTimeZone defaultTimeZone];
 
        
        self.onAlertPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, 200.0f, 320.0f, 216.0f)];
        self.onAlertPicker.showsSelectionIndicator = YES;
        self.onAlertPicker.dataSource = self;
        self.onAlertPicker.delegate = self;
        [self.onAlertPicker reloadAllComponents];
        
        
        self.offAlertPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, 200.0f, 320.0f, 216.0f)];
        self.offAlertPicker.showsSelectionIndicator = YES;
        self.offAlertPicker.dataSource = self;
        self.offAlertPicker.delegate = self;
        [self.offAlertPicker reloadAllComponents];
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

+ (BOOL) isItemInThisViewController: (NSString *) item
{
    for (id i  in [SSProfileTimeAndAlarmVC returnItemArray]) {
        if ([i isKindOfClass: [NSString class]]) {
            NSString *str = i;
            if ([str isEqualToString:item])
                return YES;
        }
        
    }
    return NO;
}

- (void) showUserChoosenSection
{
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.firstChooseIndexPath.row inSection:0]
                                animated:NO
                          scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:self.firstChooseIndexPath.row inSection:0]];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

//
//    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self showUserChoosenSection];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.itemsArray.count;
}

+ (NSString *)jobWorkHourCellStringwithJob: (OneJob *)theJob
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPositiveFormat:@"##0.#"];
    float a = [theJob getJobEveryDayLengthSec].floatValue / (60.f * 60.f);
    
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    dateformatter.timeStyle = NSDateFormatterShortStyle;
    NSString *formattedNumberString = [numberFormatter stringFromNumber:@(a)];
    
    NSString *dateString = [theJob jobEverydayOffTimeWithFormatter:dateformatter];
    NSString *resultString = [NSString stringWithFormat:@"%@ %@ (%@)", 
                               formattedNumberString,
                               NSLocalizedString(@"Hours", "hours"),
                               dateString];
    return resultString;
}

+ (void) configureTimeCell: (UITableViewCell *)cell indexPath: (NSIndexPath *)indexPath Job: (OneJob *)theJob
{

    // this is for compitable with old version witch not adding such information. 
    if ([theJob getJobEveryDayLengthSec] == Nil
        || [theJob getJobEverydayStartTime] == Nil
        || theJob.jobRemindBeforeOff == Nil
        || theJob.jobRemindBeforeWork == Nil)
        [theJob trydDfaultSetting];
    
    if (indexPath.row == CLOCK_IN_ITEM) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        cell.detailTextLabel.text = [dateFormatter stringFromDate:[theJob getJobEverydayStartTime]];
    } else if (indexPath.row == HOURS_ITEM) {
        cell.detailTextLabel.text = [SSProfileTimeAndAlarmVC jobWorkHourCellStringwithJob:theJob];
    } else if (indexPath.row == REMIND_BEFORE_WORK_ITEM) {
        cell.detailTextLabel.text = [SSProfileTimeAndAlarmVC convertTimeIntervalToString:theJob.jobRemindBeforeWork];
        //        cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize] - 0];
    } else if (indexPath.row == REMIND_BEFORE_OFF_ITEM) {
        cell.detailTextLabel.text = [SSProfileTimeAndAlarmVC convertTimeIntervalToString:theJob.jobRemindBeforeOff];
        //        cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize] - 0];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSString *item;
    item = [self.itemsArray objectAtIndex:indexPath.row];
    cell.textLabel.text = item;
    
    [[self class] configureTimeCell:cell indexPath:indexPath Job:self.theJob];
    
    [self configurePicker:cell indexPath:indexPath Job:self.theJob];
    
    
    return cell;
}

- (void) configurePicker: (UITableViewCell *)cell indexPath: (NSIndexPath *)indexPath Job: (OneJob *)theJob
{
    if (indexPath.row == CLOCK_IN_ITEM) {
        [cell addModalDatePickerView:self.startDatePicker target:self done:@selector(datePickerDoneButtonClicked) tag:0];
        self.startDatePicker.datePickerMode = UIDatePickerModeTime;
        self.startDatePicker.date = [self.theJob getJobEverydayStartTime];
        
    } else if (indexPath.row == HOURS_ITEM) {
        [cell addModalDatePickerView:self.lengthDatePicker target:self done:@selector(lengthPickerDoneButtonClicked) tag:1];
        self.lengthDatePicker.datePickerMode = UIDatePickerModeCountDownTimer;
        self.lengthDatePicker.minuteInterval = 1;
        self.lengthDatePicker.countDownDuration = [[self.theJob getJobEveryDayLengthSec] intValue];
    } else if (indexPath.row == REMIND_BEFORE_WORK_ITEM) {
        [cell addModalPickerView:self.onAlertPicker target:self done:@selector(pickerDoneButtonClicked) tag:2];
    } else if (indexPath.row == REMIND_BEFORE_OFF_ITEM) {
        [cell addModalPickerView:self.offAlertPicker target:self done:@selector(offpickerDoneButtonClicked) tag:3];
    }
}



#pragma mark - Table view delegate

- (void) pickerDoneButtonClicked
{
    OneJob *job = self.theJob;
   
    NSTimeInterval i = [SSProfileTimeAndAlarmVC convertRemindItemToTimeInterval:[self.onAlertPicker selectedRowInComponent:0]];
    job.jobRemindBeforeWork = [NSNumber numberWithInt:i];
    [self.tableView reloadData];
}

- (void) offpickerDoneButtonClicked
{
    OneJob *job = self.theJob;

    NSTimeInterval i = [SSProfileTimeAndAlarmVC convertRemindItemToTimeInterval:[self.offAlertPicker selectedRowInComponent:0]];

    job.jobRemindBeforeOff = [NSNumber numberWithInt:i];

    [self.tableView reloadData];
}


-(void)lengthPickerDoneButtonClicked {
    [self.theJob mysetJobEveryDayLengthSec:[NSNumber numberWithInt:self.lengthDatePicker.countDownDuration]];
    NSLog(@"work every length:%@ with Job:%@", [self.theJob getJobEveryDayLengthSec], self.theJob.jobName);
    [self.tableView reloadData];
}

- (void) datePickerDoneButtonClicked {
        [self.theJob mysetJobEverydayStartTime:self.startDatePicker.date];
        NSLog(@"start time every date:%@ with Job:%@", [self.dateFormatter stringFromDate:[self.theJob getJobEverydayStartTime]], self.theJob.jobName);
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - PickerView Data Source

// the event should be: NO, Just happen, 5 Minutes, 15 Minutes, 30 Minutes, 1 Hour, 2 Hours,

+ (NSDictionary *) returnRemindDict
{
    NSArray *objectArray = @[@-1,
                            @0,
                            @(5 * 60),
                            @(15 * 60),
                            @(30 * 60),
                            @(60 * 60),
                            [NSNumber numberWithInt:1.5 * 60 * 60],
                            @(2 *60 * 60),
                            @(3 * 60 * 60),
                            @(4 * 60 * 60)];
    NSArray *keysArray = @[@(REMIND_NO_ITEM),
                          @(REMIND_JUST_HAPPEN_ITEM),
                          @(REMIND_5_MIN_ITEM),
                          @(REMIND_15_MIN_ITEM),
                          @(REMIND_30_MIN_ITEM),
                          @(REMIND_1_HOUR_ITEM),
                          @(REMIND_1_5_HOUR_ITEM),
                          @(REMIND_2_HOUR_ITEM),
                          @(REMIND_3_HOUR_ITEM),
                          @(REMIND_4_HOUR_ITEM)];
    return [[NSDictionary alloc] initWithObjects:objectArray forKeys:keysArray];
}

+ (NSTimeInterval) convertRemindItemToTimeInterval:(int) item
{
    return [[[SSProfileTimeAndAlarmVC returnRemindDict] objectForKey:@(item)] intValue];
}

+ (int) convertTimeIntervalToRemindItem: (NSTimeInterval) time
{
    return [[[[SSProfileTimeAndAlarmVC returnRemindDict] allKeysForObject:[NSNumber numberWithInt:time]] lastObject] intValue];
}

+ (NSArray *) returnRemindItemArray
{
    return @[REMIND_NO_ITEM_STR,
    REMIND_JUST_HAPPEN_ITEM_STR,
    REMIND_5_MIN_ITEM_STR,
    REMIND_15_MIN_ITEM_STR,
    REMIND_30_MIN_ITEM_STR,
    REMIND_1_HOUR_ITEM_STR,
    REMIND_1_5_HOUR_ITEM_STR,
    REMIND_2_HOUR_ITEM_STR,
    REMIND_3_HOUR_ITEM_STR,
    REMIND_4_HOUR_ITEM_STR];

}

+ (NSString *) convertTimeIntervalToString: (NSNumber *) time
{
    return [[SSProfileTimeAndAlarmVC returnRemindItemArray] objectAtIndex: 
            [SSProfileTimeAndAlarmVC convertTimeIntervalToRemindItem:[time intValue]]];
}

- (NSArray *) remindItemsArray
{
    if (remindItemsArray == nil) {
        remindItemsArray = [SSProfileTimeAndAlarmVC returnRemindItemArray];	    
    }
    return remindItemsArray;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *returnStr = @"";
	
    // note: custom picker doesn't care about titles, it uses custom views
    // don't return 0
    returnStr = [remindItemsArray objectAtIndex:row];
    
    return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 220;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.remindItemsArray.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}




@end
