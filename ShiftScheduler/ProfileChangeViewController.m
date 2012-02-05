//
//  ProfileChangeViewController.m
//  WhenWork
//
//  Created by Zhang Jiejing on 11-10-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ProfileChangeViewController.h"
#import "UIColor+HexCoding.h"
#import "InfColorPicker.h"

@implementation ProfileChangeViewController

@synthesize datePicker, picker;
@synthesize itemsArray, saveButton, dateFormatter, cancelButton;
@synthesize theJob, viewMode;
@synthesize managedObjectContext, profileDelegate, iconDateSource, colorEnableSwitch;
@synthesize  nameField;


#pragma mark - "init values"


#define PICKER_VIEW_ON 3
#define PICKER_VIEW_OFF 4

#define NAME_ITEM_STRING  NSLocalizedString(@"Job Name", "job name")
#define ICON_ITEM_STRING  NSLocalizedString(@"Change Icon", "choose a icon")
#define COLOR_ENABLE_STRING NSLocalizedString(@"Enable color icon", "enable color icon")
#define COLOR_PICKER_STRING NSLocalizedString(@"Change Color", "choose a color to show icon")
#define WORKLEN_ITEM_STRING NSLocalizedString(@"Work Length", "how long work days")
#define RESTLEN_ITEM_STRING NSLocalizedString(@"Rest Length", "how long rest days")
#define STARTWITH_ITEM_STRING NSLocalizedString(@"Start With", "start with this date")

- (NSArray *) itemsArray
{
    
    if (!itemsArray) {
        itemsArray = [[NSArray alloc] initWithObjects:NAME_ITEM_STRING,
                      ICON_ITEM_STRING,
//                      COLOR_ENABLE_STRING,
                      COLOR_PICKER_STRING,
				      WORKLEN_ITEM_STRING,
				      RESTLEN_ITEM_STRING,
				      STARTWITH_ITEM_STRING ,
				      nil];
    }
    return itemsArray;
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

#define kTextFieldWidth	150.0
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
		nameField.placeholder = NSLocalizedString(@"Name of Job", nil);
		nameField.autocorrectionType = UITextAutocorrectionTypeDefault;	// no auto correction support
		
		nameField.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
		nameField.returnKeyType = UIReturnKeyDone;
		nameField.borderStyle = UITextBorderStyleNone;
		nameField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
		
		nameField.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
		
		nameField.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
		
		// Add an accessibility label that describes what the text field is for.
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


- (UISwitch *)colorEnableSwitch
{
    if (colorEnableSwitch == nil) 
    {
        CGRect frame = CGRectMake(200, 8.0, 120.0, 27.0);
        colorEnableSwitch = [[UISwitch alloc] initWithFrame:frame];
        [colorEnableSwitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
        
        // in case the parent view draws with a custom color or gradient, use a transparent color
        colorEnableSwitch.backgroundColor = [UIColor clearColor];
		
		[colorEnableSwitch setAccessibilityLabel:NSLocalizedString(@"Color Enable Switch", @"")];
		
		colorEnableSwitch.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
    }
    return colorEnableSwitch;
}

- (void)switchAction:(id)sender
{
	// NSLog(@"switchAction: value = %d", [sender isOn]);
    self.theJob.jobOnIconColorOn = [NSNumber numberWithInt:[sender isOn]];
    [self.tableView reloadData];
    
    // TODO: make choose color cell disappear.
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

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.allowsSelectionDuringEditing = YES;
 
    if (self.viewMode == PCVC_ADDING_MODE) {
        self.navigationItem.rightBarButtonItem = self.saveButton;
    } else {
        // not support profile editing yet!
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    
    if (self.viewMode == PCVC_ADDING_MODE) 
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    // in editing mode, only show return.
    
    picker.delegate = self;
    picker.dataSource = self;
    
    [self.colorEnableSwitch setOn:self.theJob.jobOnIconColorOn.intValue];
//    [self setUpUndoManager];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.picker = nil;
    self.datePicker = nil;
    self.cancelButton = nil;
    // Release any retained subviews of the main view.
//    [self cleanUpunDoManager];
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.editing = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.picker removeFromSuperview];
    [self.datePicker removeFromSuperview];
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
    return 2;
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
    if (section == 0)
        return @"Name and Icon";
    else
        return @"Shift Detail";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return  3;
    else
        return [self.itemsArray count] - 3;
}

- (NSString *) returnItemByIndexPath: (NSIndexPath *)indexPath
{
    NSString *item;
    if (indexPath.section == 0)
        item = [self.itemsArray objectAtIndex:indexPath.row];
    else
        item = [self.itemsArray objectAtIndex:(indexPath.row + 3)];
    return item;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProfileCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

    }
    
    NSString *item;
    item =  [self returnItemByIndexPath:indexPath];
            
    cell.textLabel.text = item;
    
    if ([item isEqualToString:ICON_ITEM_STRING]) {
    }
    
    if ([item isEqualToString:COLOR_ENABLE_STRING]) {
        [cell.contentView addSubview:self.colorEnableSwitch];
    }
    
    if ([item isEqualToString:COLOR_PICKER_STRING]) {
        colorChooseCellIndexPath = indexPath;
    }
    
    if ([item isEqualToString:NAME_ITEM_STRING]) {

        cell.imageView.image = self.theJob.iconImage;

        if (self.viewMode == PCVC_ADDING_MODE) {
            nameField.delegate = self;
            nameLable.text = NSLocalizedString(@"Job Name", nil);
            [cell.contentView addSubview:self.nameField];
        } else             // only one place needs display name
            cell.detailTextLabel.text = self.theJob.jobName;

    } else if ([item isEqualToString:WORKLEN_ITEM_STRING]) {
        if (self.viewMode == PCVC_ADDING_MODE 
            && self.theJob.jobOnDays == [NSNumber numberWithInt:0])  {
            // change default value ony if not changed.
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2d", PCVC_DEFAULT_ON_DAYS];
            self.theJob.jobOnDays = [NSNumber numberWithInt:PCVC_DEFAULT_ON_DAYS];
        } else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2d", [self.theJob.jobOnDays intValue]];
    } else if ([item isEqualToString:RESTLEN_ITEM_STRING]) {
        if (self.viewMode == PCVC_ADDING_MODE 
            && [self.theJob jobOffDays] == [NSNumber numberWithInt:0]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2d", PCVC_DEFAULT_OFF_DAYS];
            self.theJob.jobOffDays = [NSNumber numberWithInt:PCVC_DEFAULT_OFF_DAYS];
        } else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2d", [self.theJob.jobOffDays intValue]];
        
    } else if ([item isEqualToString:STARTWITH_ITEM_STRING]) {
        if (self.viewMode == PCVC_ADDING_MODE) {
            cell.detailTextLabel.text = [self.dateFormatter stringFromDate:[NSDate date]];
            self.theJob.jobStartDate = [NSDate date];
        } else
            cell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.theJob.jobStartDate];
    }
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
        NSError *error;
        [self.managedObjectContext save:&error];

        [self.datePicker removeFromSuperview];
        [self.picker removeFromSuperview];
    }
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
    
    UITableViewCell *targetCell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString *item = [self returnItemByIndexPath:indexPath];

    if ([self.nameField isFirstResponder]) { // release, in case other need ui.
        [self.nameField resignFirstResponder];
    }
            
    if ([item isEqualToString:NAME_ITEM_STRING]) {
        [self.nameField becomeFirstResponder];
    }
    
    if ([item isEqualToString:ICON_ITEM_STRING]) {
        JPImagePickerController *imagePickerController = [[JPImagePickerController alloc] init];
		
		imagePickerController.delegate = self;
		imagePickerController.dataSource = self.iconDateSource;
		imagePickerController.imagePickerTitle = @"Choose Icon";
		
		[self.navigationController presentModalViewController:imagePickerController animated:YES];
    }
    
    if ([item isEqualToString:COLOR_PICKER_STRING]) {
        InfColorPickerController* color_picker = [ InfColorPickerController colorPickerViewController];
        color_picker.delegate = self;
        UIColor *color = self.theJob.iconColor;
        if (color != nil)
            color_picker.sourceColor = self.theJob.iconColor;

        [color_picker presentModallyOverViewController:self];
    }
    
    
    if ([item isEqualToString:WORKLEN_ITEM_STRING] || [item isEqualToString:RESTLEN_ITEM_STRING]) {
        lastChoosePicker = indexPath.row;
        [self.datePicker removeFromSuperview];
        NSInteger n  =  [targetCell.detailTextLabel.text intValue];
        if (self.picker.superview == nil) {
            CGSize pickerSize = [self.picker sizeThatFits:CGSizeZero];
            CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
            CGRect pickerRect = CGRectMake(0.0,
                                           screenRect.origin.y + screenRect.size.height - pickerSize.height,
                                           pickerSize.width,
                                           pickerSize.height);
            
            self.picker.frame = pickerRect;
            self.picker.hidden = NO;
            [self.view.superview addSubview: self.picker];
        }
        // since picker already +1 to the row number;
        [self.picker selectRow:n-1 inComponent:0 animated:YES];
    } else
        [self.picker removeFromSuperview];

    if ([item isEqualToString:STARTWITH_ITEM_STRING]) {
        [self.picker removeFromSuperview];
        self.datePicker.date = [self.dateFormatter dateFromString:targetCell.detailTextLabel.text];
        
        if (self.datePicker.superview == nil) {
            CGSize pickerSize = [self.datePicker sizeThatFits:CGSizeZero];
            CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
            CGRect pickerRect = CGRectMake(0.0,
                                           screenRect.origin.y + screenRect.size.height - pickerSize.height,
                                           pickerSize.width,
                                           pickerSize.height);
            
            self.datePicker.frame = pickerRect;
            [self.view.superview addSubview: self.datePicker];
        } else {
            [self.datePicker removeFromSuperview];
        }
    }

}


#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *returnStr = @"";
	
    // note: custom picker doesn't care about titles, it uses custom views
    // don't return 0
    returnStr = [[NSNumber numberWithInt:(row + 1)] stringValue];
    
    return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat componentWidth = 0.0;
    
    componentWidth = 40.0;	// first column size is wider to hold names
    return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 30;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

#pragma mark - "Date/Number Picker Save events"

- (IBAction)datePickerValueChanged:(id)sender
{
    UIDatePicker *p = sender;
    self.theJob.jobStartDate = p.date;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.theJob.jobStartDate];
    NSLog(@"date changed: %@", [self.dateFormatter stringFromDate:p.date]);
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // If the user chooses a new row, update the label accordingly.
    NSAssert((lastChoosePicker == PICKER_VIEW_ON || lastChoosePicker == PICKER_VIEW_OFF),
           @"last Choose Picker in wrong state!");
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    int value = row + 1;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", value];
    [cell setSelected:YES];

    if (indexPath.row == PICKER_VIEW_ON) // on day
        self.theJob.jobOnDays = [NSNumber numberWithInt:value];
    
    if (indexPath.row == PICKER_VIEW_OFF) //off day
        self.theJob.jobOffDays = [NSNumber numberWithInt:value];
}

- (IBAction)jobNameEditingDone:(id)sender
{
    [self.tableView reloadData];
}

- (void)saveProfile:(id) sender
{
    if (self.theJob.jobName == nil || self.theJob.jobName.length == 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Input Job Name", "alart title in editing profile view")
				     message:NSLocalizedString(@"Please input Job Name", "alert string in editing profile view to let user input job name")
				    delegate:self
			   cancelButtonTitle:NSLocalizedString(@"I Know", @"I Know") otherButtonTitles:nil, nil] show];
        return;
    }
    NSError *error = nil;
    if (self.theJob.jobStartDate == nil) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"incomplete input", "alart title start profile view")
                                    message:NSLocalizedString(@"Please choose start date", "alert string in editing profile view let user choose start date")
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"I Know", @"I Know") otherButtonTitles:nil, nil] show];
        return;
    }
        
    
    [self.profileDelegate didChangeProfile:self didFinishWithSave:YES];
    [self.managedObjectContext save:&error];

    if (error != nil) {
        NSLog(@"save error happens when save profile: %@", [error userInfo]);
    }
    [self.navigationController popViewControllerAnimated:YES];
    // NSLog(@"have new profile %@", job.jobName);
}

- (IBAction)cancel:(id)sender {
    [self.profileDelegate didChangeProfile:self didFinishWithSave:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma - mark - ColorPicker

- (void) colorPickerControllerDidFinish: (InfColorPickerController*) color_picker
{
	self.theJob.jobOnColorID = [color_picker.resultColor hexStringFromColor];
	[self dismissModalViewControllerAnimated:YES];
}


#pragma - mark - JPImage Picker Delegate

- (void)imagePicker:(JPImagePickerController *)picker didFinishPickingWithImageNumber:(NSInteger)imageNumber
{

    // only store last path component
    self.theJob.jobOnIconID = [self.iconDateSource.iconList objectAtIndex:imageNumber];
    NSLog(@"choose icon :%@ saveIconPath:%@ lastPath %@", [self.iconDateSource.iconList objectAtIndex:imageNumber]
          , self.theJob.jobOnColorID, [self.theJob.jobOnColorID lastPathComponent]);
    
    [self.tableView reloadData];
    [self.modalViewController dismissModalViewControllerAnimated:YES];
}

- (void) imagePickerDidCancel:(JPImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];   
}

@end
