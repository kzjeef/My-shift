//
//  ProfileChangeViewController.m
//  WhenWork
//
//  Created by Zhang Jiejing on 11-10-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ShiftProfileChangeViewController.h"
#import "UIColor+HexCoding.h"
#import "UITableViewCell+DoneButton.h"
#import "SSProfileTimeAndAlarmVC.h"
#import "SSShiftWorkdayConfigTVC.h"
#import "SSTurnFinishDatePickerTVC.h"
#import "NSDateAdditions.h"
#import "SSShiftTableConfigTVC.h"
#import "I18NStrings.h"


@interface ShiftProfileChangeViewController() 
{
    int viewMode;
    BOOL showColorAndIconPicker;
    UITextField *nameField;
    UILabel *nameLable;
    NSArray *itemsArray;
    NSArray *timeItemArray;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *cancelButton;
    NSDateFormatter *dateFormatter;
    NSManagedObjectContext *managedObjectContext;
    NSIndexPath *colorChooseCellIndexPath;
    id<ProfileViewDelegate>  __unsafe_unretained profileDelegate;
    ProfileIconPickerDataSource *iconDateSource;
    JPImagePickerController *imagePickerVC;

    UIDatePicker *datePicker;
    Boolean warnningShiftType;
    
    Boolean enterConfig;
    NSData *saveJobData;

    OneJob *theJob;
}

@property (nonatomic, strong) IBOutlet UIDatePicker *datePicker;

@end

@implementation ShiftProfileChangeViewController

@synthesize itemsArray, saveButton, dateFormatter, cancelButton;
@synthesize theJob, viewMode;
@synthesize managedObjectContext, profileDelegate, iconDateSource;
@synthesize  nameField, timeItemsArray;

@synthesize datePicker;



#pragma mark - "init values"
#define STARTWITH_ITEM 1
#define FINISH_ITEM 2

- (NSArray *) itemsArray
{
    
    if (!itemsArray) {
        itemsArray = @[NAME_ITEM_STRING,
                       ICON_ITEM_STRING,
                       COLOR_PICKER_STRING,
                       ICON_OR_TEXT_STRING,
                       STARTWITH_ITEM_STRING,
                       REPEAT_ITEM_STRING,
                       SHIFTCONFIG_ITEM_STRING];
    }
    return itemsArray;
}

- (NSArray *) timeItemsArray
{
    if (!timeItemArray) {
        timeItemArray = @[FROM_ITEM_STRING,
					 HOURS_ITEM_STRING,
					 REMIND_BEFORE_WORK,
					 REMIND_BEFORE_CLOCK_OFF];
    }
    return timeItemArray;
}

- (UIBarButtonItem *)saveButton
{
    if (!saveButton)
        saveButton = [[UIBarButtonItem alloc] 
                      initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                      target  :self
                      action:@selector(saveProfile:)];
    return saveButton;
}

- (UIBarButtonItem *)cancelButton
{
    if (!cancelButton)
        cancelButton = [[UIBarButtonItem alloc]
			   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
						target:self
						action:@selector(cancel:)];
    return cancelButton;
}

- (NSDateFormatter *) dateFormatter
{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return dateFormatter;
}

- (ProfileIconPickerDataSource *) iconDateSource
{
    if (!iconDateSource) {
        iconDateSource = [[ProfileIconPickerDataSource alloc] init];
    }
    return  iconDateSource;
}

#define kTextFieldWidth	130.0
// for general screen
#define kLeftMargin             150.0
#define kTopMargin				20.0
#define kRightMargin			20.0
#define kTweenMargin			10.0
#define kTextFieldHeight		30.0
#define kViewTag 1
- (UITextField *)nameField
{
	if (nameField == nil)
	{
		CGRect frame = CGRectMake(kLeftMargin, 8.0, kTextFieldWidth, kTextFieldHeight);
		nameField = [[UITextField alloc] initWithFrame:frame];
		nameField.textColor = [UIColor blackColor];
		nameField.placeholder = NSLocalizedString(@"Name of Shift", nil);
		nameField.autocorrectionType = UITextAutocorrectionTypeDefault;	// no auto correction support
		
		nameField.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
		nameField.returnKeyType = UIReturnKeyDone;
		nameField.borderStyle = UITextBorderStyleNone;
        //		nameField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
        nameField.clearButtonMode = UITextFieldViewModeNever;
		nameField.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
        nameField.textAlignment = NSTextAlignmentCenter;
	}	
	return nameField;
}

-(BOOL)textFieldShouldReturn:(UITextField*)sender
{
    if (self.theJob.jobName.length > 0) {
       [self.nameField resignFirstResponder];
        return YES;
    } else
        return  NO;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
        return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // update the name every tpying.
    self.theJob.jobName = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.theJob.jobName = textField.text;
    [textField resignFirstResponder];
}

- (void)jobSwitchAction:(id) sender
{
    UISwitch *currentSwitch = sender;
    self.theJob.jobShowTextInCalendar = @(currentSwitch.isOn);
}


#pragma mark - "controller start init"

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
    
    NSAssert(self.theJob, @"the job should not nil");
    
    enterConfig = NO;
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.allowsSelectionDuringEditing = YES;
 
    self.navigationItem.rightBarButtonItem = self.saveButton;

    // cancel button only appear in adding mode, because we can not cancel the date in editing mode, it use save data context.

    self.navigationItem.leftBarButtonItem = self.cancelButton;

    
    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 250, 325, 250)];
    CGSize pickerSize = [datePicker sizeThatFits:CGSizeZero];
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    CGRect pickerRect = CGRectMake(0.0, screenRect.origin.y + screenRect.size.height - pickerSize.height - 65, pickerSize.width, pickerSize.height);
   datePicker.frame = pickerRect;
   [datePicker setDatePickerMode:UIDatePickerModeDate];

// default value configure
   [self.theJob trydDfaultSetting];
    

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.cancelButton = nil;
    self.datePicker = nil;

    // Release any retained subviews of the main view.
//    [self cleanUpunDoManager];
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self setEditing:YES];
    
    [SSTrackUtil logTimedEvent:kLogEventShiftChangePage];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // should not save any managed context here...
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [SSTrackUtil stopLogTimedEvent:kLogEventCaldendarSyncLengthChange];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (index <= 2) {
        return  0;
    } else {
        return  1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // For first section , don't needs a title, save some space for let customer see the last section's title.
    if (section == 0)
        return nil;
    else if (section == 1)
        return SHIFTCONFIG_ITEM_STRING;
    else if (section == 2)
        return SHIFT_TIME_DETAIL_TITLE;
    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
#if 0
        return  self.editing ? 3 : 1;
#else
        return 4;
#endif
    else if (section == 1)
        return 3;
    else if (section == 2)
        return self.timeItemsArray.count;
    return 0;
}

- (NSString *) returnItemByIndexPath: (NSIndexPath *)indexPath
{
    NSString *item;
    if (indexPath.section == 0)
        item = [self.itemsArray objectAtIndex:indexPath.row];
    else if (indexPath.section == 1)
        item = [self.itemsArray objectAtIndex:(indexPath.row + 4)];
    else if (indexPath.section == 2)
        item = [self.timeItemsArray objectAtIndex:indexPath.row];
    return item;
}

- (void)configureStartRepeatItems:(NSString *)item withCell:(UITableViewCell *)cell
{
    if ([item isEqualToString:STARTWITH_ITEM_STRING]) {
        cell.detailTextLabel.text = [self.dateFormatter stringFromDate:theJob.jobStartDate];
        self.datePicker.date = self.theJob.jobStartDate;
        [cell addModalDatePickerView:self.datePicker target:self done:@selector(doneButtonClicked:) tag:STARTWITH_ITEM];
    }
    
    if ([item isEqualToString:REPEAT_ITEM_STRING]) {
        NSString *text;
        
        if ([self.theJob isShiftDateValied] == NO) {
            cell.detailTextLabel.textColor = [UIColor redColor];
        }
        
        text = (theJob.jobFinishDate == nil) ? REPEAT_FOREVER_STRING : [self.dateFormatter stringFromDate:theJob.jobFinishDate];
        cell.detailTextLabel.text = text;
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProfileCell";
    NSString *item;
    
    // here can't recycle tabelViewCell.
    UITableViewCell *cell;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

    // setup cell text by index path

    item =  [self returnItemByIndexPath:indexPath];

    cell.textLabel.text = item;
    cell.imageView.image = nil;

    if ([item isEqualToString:ICON_OR_TEXT_STRING]) {
        if (self.theJob.jobShowTextInCalendar.intValue == YES)
            cell.detailTextLabel.text = TEXT_STRING;
        else
            cell.detailTextLabel.text = ICON_STRING;
    }
    
   
    if ([item isEqualToString:NAME_ITEM_STRING]) {
        cell.imageView.image = self.theJob.middleSizeImage;
        self.nameField.delegate = self;
        [self.nameField setText:self.theJob.jobName];
        [cell.contentView addSubview:self.nameField];

    }

    if ([item isEqualToString:SHIFTCONFIG_ITEM_STRING]) {
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (warnningShiftType) {
            cell.textLabel.highlightedTextColor = [UIColor redColor];
            cell.textLabel.highlighted = YES;
        }
    }
    
    [self configureStartRepeatItems:item withCell:cell];

    if ([SSProfileTimeAndAlarmVC isItemInThisViewController:item])
        [SSProfileTimeAndAlarmVC configureTimeCell:cell indexPath:indexPath Job:self.theJob];

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == 0 && indexPath.row == 0) // can't edit name ?
        return NO; 
    return YES;

}

#pragma mark - Table view delegate

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
    [super setEditing:editing animated:animate];

    if (!editing)
    {
        self.nameField.enabled = NO;
        [self.nameField resignFirstResponder];
        [self saveProfile:Nil];
    } else {
        self.nameField.enabled = YES;
    }
    
    // hide the color picker and icon picker.


#if 0 // will crash if retrun from other view, disable it.
        NSArray *a = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:2 inSection:0], nil];
    
    if (editing) {
        showColorAndIconPicker = YES;
        [self.tableView insertRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationAutomatic];
        
    } else {
        showColorAndIconPicker = NO;
        [self.tableView deleteRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationAutomatic];
        // index paths for icon picker and color picker.
    }
#endif
    
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewMode == PCVC_ADDING_MODE)
        return indexPath;
    return (self.editing) ? indexPath : nil;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *item = [self returnItemByIndexPath:indexPath];

    if ([self.nameField isFirstResponder]) { // release, in case other need ui.
        [self.nameField resignFirstResponder];
    }
            
    if ([item isEqualToString:NAME_ITEM_STRING]) {
        [self.nameField becomeFirstResponder];
        [SSTrackUtil logEvent:kLogEventShiftChangePageNameChange];
    }
    
    if ([item isEqualToString:ICON_ITEM_STRING]) {
        JPImagePickerController *imagePickerController = [[JPImagePickerController alloc] init];
		
		imagePickerController.delegate = self;
		imagePickerController.dataSource = self.iconDateSource;
		imagePickerController.imagePickerTitle = NSLocalizedString(@"Choose Icon", "title of choose icon view");
                imagePickerController.monoColor = [self.theJob iconColor];
                imagePickerController.monoProcessAllImage = YES;
		
		[self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
        
        [SSTrackUtil logEvent:kLogEventShiftChangePageIconChange];
    }

    if ([item isEqualToString:ICON_OR_TEXT_STRING]) {
        UIActionSheet *colorTextPicker = [[UIActionSheet alloc] initWithTitle:Nil 
                                                                     delegate:self
                                                            cancelButtonTitle:NSLocalizedString(@"Cancel", "cancel")
                                                       destructiveButtonTitle:nil 
                                                            otherButtonTitles:ICON_STRING, TEXT_STRING , nil];
        [colorTextPicker showInView:self.tableView.superview];
        
        [SSTrackUtil logEvent:kLogEventShiftChangePageTextIcon];
    }
    
    if ([item isEqualToString:COLOR_PICKER_STRING]) {
        KKColorListViewController *controller = [[KKColorListViewController alloc] initWithSchemeType:
                                                                                       KKColorsSchemeTypeCrayola];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        controller.delegate = self;
        [self presentViewController:navController animated:YES completion:nil];
        
        [SSTrackUtil logEvent:kLogEventShiftChangePageColorPick];
    }
    
    if ([item isEqualToString:SHIFTCONFIG_ITEM_STRING]) {
      	SSShiftTableConfigTVC *fjmp = [[SSShiftTableConfigTVC alloc] initWithStyle:UITableViewStyleGrouped];
        fjmp.theJob = self.theJob;
        fjmp.pickDelegate = self;
        [self.navigationController pushViewController:fjmp animated:YES];
        enterConfig = YES;
        warnningShiftType = NO;
        [SSTrackUtil logEvent:kLogEventShiftChangePageShiftDetail];
    }

    if ([item isEqualToString:STARTWITH_ITEM_STRING]) {
        self.datePicker.tag = STARTWITH_ITEM;
        [SSTrackUtil logEvent:kLogEventShiftChangePageStartWith];
    }
    
    if ([item isEqualToString:REPEAT_ITEM_STRING]) {
        SSTurnFinishDatePickerTVC *finishpicker = [[SSTurnFinishDatePickerTVC alloc] initWithStyle:UITableViewStyleGrouped];
        finishpicker.job = self.theJob;
        [self.navigationController pushViewController:finishpicker animated:YES];
        [SSTrackUtil logEvent:kLogEventShiftChangePageRepeatTo];
    }


    if ([SSProfileTimeAndAlarmVC isItemInThisViewController:item])
	{
	    SSProfileTimeAndAlarmVC *taavc = [[SSProfileTimeAndAlarmVC alloc]
                                          initWithStyle:UITableViewStyleGrouped];
	    taavc.theJob = self.theJob;
        taavc.firstChooseIndexPath = indexPath;
        [self.navigationController pushViewController:taavc animated:YES];
	}
}


- (IBAction)jobNameEditingDone:(id)sender
{
    [self.tableView reloadData];
}

- (void)saveProfile:(id) sender
{

    // No profile name not allow save.
    if (self.theJob.jobName == nil || self.theJob.jobName.length == 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Input Shift Name", "alart title in editing profile view")
				     message:NSLocalizedString(@"Please input shift Name", "alert string in editing profile view to let user input job name")
				    delegate:self
			   cancelButtonTitle:NSLocalizedString(@"I Know", @"I Know") otherButtonTitles:nil, nil] show];
        return;
    }

    // No Shift Type don't allow save.
    if (self.theJob.jobShiftType == nil || self.theJob.jobShiftType.intValue == JOB_SHIFT_ALGO_NON_TYPE) {
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Needs Shift Type", "alart shift type in editing profile view")
				    message:NSLocalizedString(@"Please Choose a shift type", "alert string in editing profile view to let user input shift type")
				   delegate:self
			  cancelButtonTitle:NSLocalizedString(@"I Know", @"I Know") otherButtonTitles:nil, nil] show];
        warnningShiftType = YES;
        [self.tableView reloadData];
        return;
    }
    
    if ([self.theJob isJobFreeJumpTableAllZero]) {

        if (warnningShiftType != YES) {  // just warnning once...
            [[[UIAlertView alloc] initWithTitle:EMPTY_SHIFT_WARNNING_TITLE
                                        message:EMPTY_SHIFT_WARNNING_DETAIL
                                       delegate:nil
                              cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            warnningShiftType = YES;
            [self.tableView reloadData];
            return;
        }
    }


    // shift start date > shift < date.
    if ([self.theJob isShiftDateValied] == NO) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Shift Invalied", "alart shift type in editing profile view")
                                    message:NSLocalizedString(@"Please choose shift endDate", "alert string in editing profile view to let user input shift type")
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"I Know", @"I Know") otherButtonTitles:nil, nil] show];
        return;
    }
    
    // must have configure the shift once.
    if (self.viewMode == PCVC_ADDING_MODE && enterConfig == NO) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Configure shift", "alert for not configure shift yet.") message:@"please have a configure of your shift." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        warnningShiftType = YES;
        [self.tableView reloadData];
        return;
    }

    if (self.theJob.jobStartDate == nil) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"incomplete input", "alart title start profile view")
                                    message:NSLocalizedString(@"Please choose start date", "alert string in editing profile view let user choose start date")
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"I Know", @"I Know") otherButtonTitles:nil, nil] show];
        return;
    }

    [self.profileDelegate didChangeProfile:self didFinishWithSave:YES];
    [self.navigationController popViewControllerAnimated:YES];
    // NSLog(@"have new profile %@", job.jobName);
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [self.profileDelegate didChangeProfile:self didFinishWithSave:NO];


}

#pragma - mark DatePicker

-(void) doneButtonClicked:(id) sender
{
    UIBarButtonItem *button = sender;
    if (button.tag == STARTWITH_ITEM) {
        theJob.jobStartDate = [datePicker.date cc_dateByMovingToMiddleOfDay];
    } else if (button.tag == FINISH_ITEM)
        theJob.jobFinishDate = [datePicker.date cc_dateByMovingToMiddleOfDay];
    
    [[self tableView] reloadData];
}

#pragma - mark - ColorPicker

-(void) colorListPickerDidComplete:(KKColorListViewController *)controller
{
    [self dismissViewControllerAnimated:YES  completion:nil];
    [self.tableView  reloadData];
}

- (void)colorListController:(KKColorListViewController *)controller didSelectColor:(KKColor *)color;
{

    self.theJob.jobOnColorID = [[color uiColor] hexStringFromColor];
    self.theJob.cachedJobOnIconID = nil;
    self.theJob.cachedJobOnIconColor = nil;
}

#pragma - mark - JPImage Picker Delegate

- (void)imagePicker:(JPImagePickerController *)picker didFinishPickingWithImageNumber:(NSInteger)imageNumber
{
    // only store last path component
    self.theJob.jobOnIconID = [[self.iconDateSource.iconList objectAtIndex:imageNumber] lastPathComponent];
    NSLog(@"choose icon :%@",self.theJob.jobOnIconID);
    self.theJob.cachedJobOnIconID = nil;
    self.theJob.cachedJobOnIconColor = nil;
    [self.tableView reloadData];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerDidCancel:(JPImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma - mark - ShiftTypePickerDelegate
- (void) SSItemPickerChoosewithController: (SSShiftWorkdayConfigTVC *) sender itemIndex: (NSInteger) index
{

#if CONFIG_WORKDAY_CONFIG_MODAL_VIEW
    [self dismissModalViewControllerAnimated:YES];
#endif

    warnningShiftType = NO;
    
    [self.tableView reloadData];
}


- (void)actionSheet:(UIAlertView *)sender clickedButtonAtIndex:(NSInteger)index
{
    switch (index) {
    case 0:
        self.theJob.jobShowTextInCalendar = @0;
        [self.tableView reloadData];
        break;
    case 1:
        self.theJob.jobShowTextInCalendar = @1;
        [self.tableView reloadData];
        break;
    }
}

- (void) SSShiftTypePickerClientFinishConfigure: (id) sender
{
  UITableViewController *s = sender;
  [s.navigationController popViewControllerAnimated:YES];
}
@end
