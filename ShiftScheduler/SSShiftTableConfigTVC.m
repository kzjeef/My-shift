//
//  FreeJumpProfileConfigTVC.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSShiftTableConfigTVC.h"
#import "NSDateAdditions.h"
#import "I18NStrings.h"
#import "UITableViewCell+DoneButton.h"

@interface SSShiftTableConfigTVC ()
{
    OneJob *job_;
    UITextField *popupHelperField;
    UIPickerView *picker;
    NSMutableArray *shiftStateArray;
    NSDateFormatter *dateFormatter;
    id<SSShiftTypePickerDelegate> __unsafe_unretained pickDelegate;
}

@property (weak, readonly) NSDateFormatter *dateFormatter;

@end

@implementation SSShiftTableConfigTVC

@synthesize theJob=job_;
@synthesize pickDelegate;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)reloadShiftTable
{
    int i, size;
    // First copy the array,
    NSArray *arrayBackup = [NSArray arrayWithArray:shiftStateArray];
    // Invvalid the cache.
    [self.theJob jobFreeJumpTableCacheInvalid];
    // Get new new jump array
    shiftStateArray = [self.theJob.jobFreeJumpTable mutableCopy];
    
    size = self.theJob.jobFreeJumpCycle.intValue;

    // Then try to copy back all table items back, try it all.
    for (i = 0; i < MIN(size, arrayBackup.count); i ++)
        [shiftStateArray replaceObjectAtIndex:i withObject:[arrayBackup objectAtIndex:i]];

}

- (void)viewDidLoad
{
    [super viewDidLoad];

    shiftStateArray = [self.theJob.jobFreeJumpTable mutableCopy];
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200.f, 320.f, 216.0f)];
    picker.delegate = self;
    picker.dataSource = self;
    picker.showsSelectionIndicator = YES;
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSDateFormatter *) dateFormatter
{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return dateFormatter;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
        return 1;
    else if (section == 1)
        return self.theJob.jobFreeJumpCycle.intValue;
    else
        return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return NSLocalizedString(@"Shift Cycle Length", "");
    else
        return NSLocalizedString(@"Which days on shift?", "");
}

- (void)cancelButtonSelected {
    
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return NSLocalizedString(@"Click to change shift cycle", "");
    if (section == 1)
        return NSLocalizedString(@"Click to choose shift on days", "");
    return [NSString string];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FreeJumpCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            [cell addModalPickerView:picker target:self done:@selector(doneButtonSelected) tag:0];
            [picker selectRow:self.theJob.jobFreeJumpCycle.intValue - 1 inComponent:0 animated:YES];
            cell.textLabel.text = LENGTH_OF_CYCLE;
            cell.detailTextLabel.text = (self.theJob.jobFreeJumpCycle == nil) ? @"0" : ([NSString stringWithFormat:@"%@", self.theJob.jobFreeJumpCycle]);
            
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    if (indexPath.section == 1) {
        cell.textLabel.text = [NSString stringWithFormat:@"%d", indexPath.row + 1];

        if ([self checkShiftDayState:indexPath.row]) {
            cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
            // @TODO: add more detail information when check
            cell.detailTextLabel.text = [self shiftChooserDetailedHelpMessageWithCount:indexPath.row];
        } else {
            cell.editingAccessoryType = UITableViewCellAccessoryNone;
            cell.detailTextLabel.text = [self shiftChooserDetailedHelpMessageWithCount:indexPath.row];
        }
    }

    return cell;
}

- (NSString *) shiftChooserDetailedHelpMessageWithCount:(int) row
{
    return [self.dateFormatter stringFromDate:[self.theJob.jobStartDate
                                                  cc_dateByMovingToNextOrBackwardsFewDays:row
                                                  withCalender:[NSCalendar currentCalendar]]];
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
    [super setEditing:editing animated:animate];

    if (!editing) {
        [self saveShiftChange];

	if (pickDelegate)
	    [pickDelegate SSShiftTypePickerClientFinishConfigure: self];
        else
            [self.navigationController popViewControllerAnimated:animate];
    }
}

- (void)saveShiftChange
{
    self.theJob.jobFreeJumpTable = shiftStateArray;
}

- (BOOL) checkShiftDayState: (int) index
{
    if (shiftStateArray.lastObject == nil)
        return NO;
    int v = [[shiftStateArray objectAtIndex:index] intValue];
    return v;
}

- (void) toggleShiftDayState: (int) index
{
    int v = [[shiftStateArray objectAtIndex:index] intValue];
    v = (v == 0)  ? 1 : 0;
    [shiftStateArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:v]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
        [self toggleShiftDayState:indexPath.row];

    [self.tableView reloadData];
}

- (void)doneButtonSelected {
    __weak OneJob *job = self.theJob;
    __weak SSShiftTableConfigTVC *_self = self;
    NSIndexPath *pChoosedIndexPath = [self.tableView indexPathForSelectedRow];
    __weak UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:pChoosedIndexPath];

    int value = [picker selectedRowInComponent:0] + 1;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
    [cell dismissModalPickerView];
    [cell setSelected:YES];
    
    // Clear the cache of shift table, and load new one.
    job.jobFreeJumpCycle = @(value);
    [_self reloadShiftTable];
    [_self.tableView reloadData];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *returnStr = @"";

    // note: custom picker doesn't care about titles, it uses custom views
    // don't return 0
    returnStr = [@(row + 1) stringValue];

    return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
  return 60.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 366;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

@end
