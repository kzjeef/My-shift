//
//  SSShiftTypePickerTVC.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-5-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSShiftWorkdayConfigTVC.h"
#import "SSShiftTableConfigTVC.h"
#import "I18NStrings.h"
#import "OneJob.h"

@interface SSShiftWorkdayConfigTVC () {
    NSArray *items;
    NSArray *detailItems;
    OneJob *theJob;
    id<SSShiftTypePickerDelegate> __unsafe_unretained pickDelegate;
}
@end

@implementation SSShiftWorkdayConfigTVC

@synthesize items, pickDelegate, theJob;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        detailItems = @[FREE_ROUND_DETAIL_STRING, FREE_JUMP_DETAIL_STRING];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = SHIFT_TYPE_PICKER_STRING;

#if CONFIG_WORKDAY_CONFIG_MODAL_VIEW
    NSAssert(self.pickDelegate, @"picker Delegate should be used");
#endif
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 0;
    else
        return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == NULL) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [self.items objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [detailItems objectAtIndex:indexPath.row];

    return cell;
}

#pragma mark - Table view delegate

- (void)shiftConfigChooseRightShiftConfigure
{
    if (![self.theJob shiftTypeValied]) {
        // do some thing , alart ?
    }

    if (self.theJob.jobShiftType.intValue == JOB_SHIFT_ALGO_FREE_ROUND) {
        NSLog(@"Warnning: Shift Free Round already deleted. SHOULD NOT BE HERE...");
    }

    if (self.theJob.jobShiftType.intValue == JOB_SHIFT_ALGO_FREE_JUMP) {
        SSShiftTableConfigTVC *fjmp = [[SSShiftTableConfigTVC alloc] initWithStyle:UITableViewStyleGrouped];
        fjmp.theJob = self.theJob;
        fjmp.pickDelegate = self;
        [self.navigationController pushViewController:fjmp animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.theJob.jobShiftType = @(indexPath.row + 1);    
    [self shiftConfigChooseRightShiftConfigure];
}

- (void) SSItemPickerChoosewithController: (SSShiftWorkdayConfigTVC *) sender itemIndex: (NSInteger) index
{
}

- (void) SSShiftTypePickerClientFinishConfigure: (id) sender
{
    [self.pickDelegate SSItemPickerChoosewithController:self itemIndex:self.theJob.jobShiftType.intValue - 1];

#if !(CONFIG_WORKDAY_CONFIG_MODAL_VIEW)
    [self.navigationController popViewControllerAnimated:YES];
#endif
}

@end
