//
//  ProfilesViewController.m
//  
//
//  Created by Zhang Jiejing on 11-10-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ShiftListProfilesTVC.h"
#import "ShiftProfileChangeViewController.h"
#import "OneJob.h"
#import "SSDefaultConfigName.h"
#import "UIColor+HexCoding.h"
#import "SSAppDelegate.h"
#import "I18NStrings.h"


#define PROFILE_CACHE_INDIFITER @"ProfileListCache"
#define PROFILE_OOD_CACHE_INDIFITER @"ProfileListCacheOOD"

enum {
    SECTION_NORMAL_SHIFT = 0,
    SECTION_OUTDATE_SHOW_HIDE,
    SECTION_ADD_NEW_SHIFT,
    SECTION_SIZE,
};

enum {
    TAG_MENU_BUTTON = 1,
    TAG_EDIT_BUTTON,
    TAG_ADD_BUTTON,
};

@implementation ShiftListProfilesTVC

@synthesize managedObjectContext, addingManagedObjectContext, fetchedResultsController, fetchedResultsControllerOOD;
@synthesize parentViewDelegate, timeFormatter;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (id)initWithManagedContext:(NSManagedObjectContext *)context
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.title = SHIFTS_STR;
    self.managedObjectContext = context;
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    for (OneJob *j in self.fetchedResultsController.fetchedObjects) {
        j.middleSizeImage = nil;
    }
    // Release any cached data, images, etc that aren't in use.
}

- (void) returnToHome
{
    [self.parentViewDelegate didFinishEditingSetting];
}

- (void)jobSwitchAction:(id) sender
{
    UISwitch *currentSwitch = sender;
    OneJob *j = [self.fetchedResultsController.fetchedObjects objectAtIndex:currentSwitch.tag];
    j.jobEnable = @(currentSwitch.isOn);
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    [SSTrackUtil logEvent:kLogEventShiftListEnable param:@{@"enable" : [NSNumber numberWithInteger:currentSwitch.isOn]}];
}

- (NSDateFormatter *) timeFormatter
{
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return timeFormatter;
}

- (void)menuButtonClicked
{
    if (self.menuDelegate) {
        [self.menuDelegate SSMainMenuDelegatePopMainMenu:self];
    }
}

- (IBAction)insertNewProfile:(id) sender
{
    ShiftProfileChangeViewController *addViewController = [[ShiftProfileChangeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    addViewController.viewMode = PCVC_ADDING_MODE;
	
    // Create a new managed object context for the new book -- set its persistent store coordinator to the same as that from the fetched results controller's context.
    NSManagedObjectContext *addingContext = [[NSManagedObjectContext alloc] init];
    addingContext.undoManager = nil; // Undo manager is not needed here.
    self.addingManagedObjectContext = addingContext;
    [addingManagedObjectContext setPersistentStoreCoordinator:[[self.fetchedResultsController managedObjectContext] persistentStoreCoordinator]];
    
    addViewController.managedObjectContext = addingContext;
    // use same manage object context can auto update the frc.
    OneJob *job = [NSEntityDescription insertNewObjectForEntityForName:@"OneJob" inManagedObjectContext:addingContext];
    [job forceDefaultSetting];

    addViewController.theJob = job;
    addViewController.profileDelegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addViewController];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Fetched results controller

/**
   Returns the fetched results controller. Creates and configures the controller if necessary.
*/

- (NSFetchedResultsController *)fetchedResultsControllerOOD
{
 
    if (fetchedResultsControllerOOD != nil)
        return fetchedResultsControllerOOD;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob"
                                          inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"jobFinishDate" ascending:NO]];

    @try {
        request.predicate = [self oodOnlyShifts];
    }
    @catch (NSException *exception) {
        NSLog(@"got exception... %@ %@", [exception name], [exception reason] );
        return NULL;
    }
    
    request.fetchBatchSize = 20;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc]
                                          initWithFetchRequest:request
                                          managedObjectContext:self.managedObjectContext
                                            sectionNameKeyPath:Nil cacheName:PROFILE_OOD_CACHE_INDIFITER];
    fetchedResultsControllerOOD = frc;
    return fetchedResultsControllerOOD;
}


- (NSFetchedResultsController *)fetchedResultsController 
{
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"jobStartDate"  ascending:YES]];

    BOOL showOOD = [[NSUserDefaults standardUserDefaults] boolForKey:USER_CONFIG_ENABLE_DISPLAY_OUT_DATE_SHIFT];
    if (showOOD)
        request.predicate = nil;
    else
        request.predicate = [self validOnlyPredicate];

    request.fetchBatchSize = 20;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] 
                                          initWithFetchRequest:request 
                                          managedObjectContext:self.managedObjectContext
                                            sectionNameKeyPath:nil 
                                                     cacheName:Nil];
    fetchedResultsController = frc;
    return frc;
}


- (void) switchPredicate: (NSPredicate *)  predicate
{
    [self.fetchedResultsController.fetchRequest setPredicate:predicate];
}

- (NSPredicate *) fullPredicate
{
    return nil;
}

- (NSPredicate *) oodOnlyShifts
{
    return [NSPredicate predicateWithFormat:@"(jobFinishDate != nil) && (jobFinishDate < %@)", [NSDate date]];
}

- (NSPredicate *) validOnlyPredicate
{
    return [NSPredicate predicateWithFormat:@"(jobFinishDate == nil) || (jobFinishDate >= %@) ", [NSDate date]];
}

/**
   Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.
*/

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (NSInteger) profileuNumber
{
    return [self.fetchedResultsController.fetchedObjects count];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *tableView = self.tableView;
    
    switch(type) {
			
    case NSFetchedResultsChangeInsert:
        [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        break;
			
    case NSFetchedResultsChangeDelete:
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        // If the last OOD Object was delete, really need is just
        // remove the section, but seems only make a full update can
        // make the section disappear.
        [self.fetchedResultsControllerOOD performFetch:NULL];

            [tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_OUTDATE_SHOW_HIDE] withRowAnimation:UITableViewRowAnimationAutomatic];

        break;
			
    case NSFetchedResultsChangeUpdate:
            //            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
        break;
			
    case NSFetchedResultsChangeMove:
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	
    switch(type) {
			
    case NSFetchedResultsChangeInsert:
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        break;
			
    case NSFetchedResultsChangeDelete:
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        break;
    default:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
    
    // update all contexts if same change happens, don't change it if editing 
    if (!self.editing)
        [self.tableView reloadData];
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.editButtonItem.tag = TAG_EDIT_BUTTON;
    //    UIBarButtonItem *addbutton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewProfile:)];

    ///    self.navigationItem.leftBarButtonItem = addbutton;
    UIImage *menuIcon = [UIImage imageNamed:@"menu.png"];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:menuIcon style:UIBarButtonItemStylePlain  target:self action:@selector(menuButtonClicked)];
    menuButton.tag = TAG_MENU_BUTTON;
    self.navigationItem.leftBarButtonItem = menuButton;


    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error when load %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }

    [self.fetchedResultsControllerOOD performFetch:NULL];
    self.fetchedResultsController.delegate = self;

    plusImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"addButton" ofType:@"png"]];
    if ([plusImage respondsToSelector:@selector(imageWithRenderingMode:)])
        plusImage = [plusImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    // start init coach marks.
    
}


- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    plusImage = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTION_SIZE;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (section == SECTION_ADD_NEW_SHIFT)
        return 1;
    else if (section == SECTION_OUTDATE_SHOW_HIDE) {
        if ([self.fetchedResultsControllerOOD.fetchedObjects count] > 0)
        return 1;
        else
            return  0;
    }
    else {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SECTION_NORMAL_SHIFT
        && [self.fetchedResultsController.fetchedObjects count] > 0)
        return NSLocalizedString(@"Shift Manage", "");
    
        
    return  [NSString string] ;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([self.fetchedResultsController.fetchedObjects count] > 0 && section == SECTION_NORMAL_SHIFT) {
        return NSLocalizedString(@"choose to change shift detail", "");
    } else if (section == SECTION_OUTDATE_SHOW_HIDE && [self.fetchedResultsControllerOOD.fetchedObjects count] > 0)
        return NSLocalizedString(@"click button to show or hide the outdated shifts", "show hide out date shifts strings.");
    return  [NSString string] ;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellOfProfileCell";
    static NSString *clearCellIdentifier = @"CellProfileCellClean";
    NSString *indentifer;
    UITableViewCell *cell;
    
    if (indexPath.section == SECTION_ADD_NEW_SHIFT || (indexPath.section == SECTION_OUTDATE_SHOW_HIDE))
        indentifer = clearCellIdentifier;
    else
        indentifer = CellIdentifier;

    cell = [tableView dequeueReusableCellWithIdentifier:indentifer];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:indentifer];


        if (indexPath.section == SECTION_NORMAL_SHIFT)
        [self configureCell:cell atIndexPath:indexPath.row withFrc:self.fetchedResultsController];
    else if (indexPath.section == SECTION_ADD_NEW_SHIFT) {
        cell.imageView.image = plusImage;
        cell.textLabel.text = NSLocalizedString(@"Adding new shift...", "add new shift");
        cell.textLabel.textColor = [UIColor colorWithRed:22.0/255.0 green:152.0/255.0 blue:69.0/255.0 alpha:1];
        cell.tag = TAG_ADD_BUTTON;
    } else if (indexPath.section == SECTION_OUTDATE_SHOW_HIDE) {
        NSString *tt = NSLocalizedString(@"Outdated Shifts", "expand archived shifts");
        NSString *text = [NSString stringWithFormat:@"%@ (%lu)",
                                   tt,
                                   (unsigned long)[self.fetchedResultsControllerOOD.fetchedObjects count]];
        cell.textLabel.text = text;
        cell.imageView.image = [UIImage imageNamed:@"overdate"];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        //        cell.textLabel.textColor = [UIColor colorWithHexString:@"283DA0"];
        cell.textLabel.backgroundColor = [UIColor colorWithWhite:.1 alpha:0];
        //        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grayButtonBackgroud"]];
    }

    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == SECTION_ADD_NEW_SHIFT)
        return NO;
    if (indexPath.section == SECTION_OUTDATE_SHOW_HIDE)
        return NO;

    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[self.fetchedResultsController fetchedObjects] count] <= 0) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
// Return NO if you do not want the item to be re-orderable.
return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        // Delete the managed object.
        NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
        [context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
		
        NSError *error;
        if (![context save:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error when save on delete %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
    }   
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
    
    
    // hide all UISwitch when edting... since it will affect Detete UI.
    
    for (id a  in self.tableView.visibleCells)
        if ([a isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *c = a;
            for  (id s in c.contentView.subviews)
                if ([s isKindOfClass:[UISwitch class]]) {
                    if (editing)   [s setHidden:YES];
                    else           [s setHidden:NO];
                }
        }
    
    if (!editing) {
        [self.tableView reloadData];
    }
}

- (void) openProfileEditView: (NSInteger)row withFrc: (NSFetchedResultsController *)frc
{
    ShiftProfileChangeViewController *pcvc = [[ShiftProfileChangeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    pcvc.theJob = [frc.fetchedObjects objectAtIndex:row];
    pcvc.profileDelegate = self;
    pcvc.managedObjectContext = self.managedObjectContext;
    pcvc.viewMode = PCVC_EDITING_MODE;
    UINavigationController *navController = [[UINavigationController alloc]
                                                initWithRootViewController:pcvc];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_NORMAL_SHIFT) {
        [self openProfileEditView:indexPath.row
                          withFrc:self.fetchedResultsController];
        [SSTrackUtil logEvent:kLogEventShiftListNormalOpen];
    } else if (indexPath.section == SECTION_OUTDATE_SHOW_HIDE) {

        if (self.fetchedResultsController.fetchRequest.predicate == nil) {
            [self switchPredicate:[self validOnlyPredicate]];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_CONFIG_ENABLE_DISPLAY_OUT_DATE_SHIFT];
        } else {
            [self switchPredicate:nil];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_CONFIG_ENABLE_DISPLAY_OUT_DATE_SHIFT];
        }
        
        [self.fetchedResultsControllerOOD performFetch:NULL];
        [self.fetchedResultsController performFetch:NULL];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_NORMAL_SHIFT]  withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_OUTDATE_SHOW_HIDE]  withRowAnimation:UITableViewRowAnimationAutomatic];
        [SSTrackUtil logEvent:kLogEventShiftListNormalOutdate];

    } else {
        [self insertNewProfile:nil];
        [SSTrackUtil logEvent:kLogEventShiftListAdd];
    }
}

- (void)configureCell:(UITableViewCell *)cell
          atIndexPath:(NSInteger) row
              withFrc:(NSFetchedResultsController *)frc
    
{
    @try {
    id t = [frc.fetchedObjects objectAtIndex:row];
    if ([t isKindOfClass:[OneJob class]]) {
        OneJob *j = t;
        cell.textLabel.text = j.jobName;
        // If it's a outdated shift, gray the font 's color.
        if ([j isShiftAlreadyOutdated]) {
            cell.textLabel.textColor = [UIColor grayColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }

        cell.imageView.image = j.middleSizeImage;

        if ([j getJobEverydayStartTime] != Nil)
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                                  [j jobEverydayStartTimeWithFormatter:self.timeFormatter],
                                                  [j jobEverydayOffTimeWithFormatter:self.timeFormatter]];
        
        UISwitch *theSwitch;
        theSwitch = [[UISwitch alloc] init];
        CGSize switchSize = [theSwitch sizeThatFits:CGSizeZero];

        theSwitch.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 5.0f,
                             (cell.contentView.bounds.size.height - switchSize.height) / 2.0f,
                             switchSize.width,
                             switchSize.height);
        theSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [theSwitch addTarget:self action:@selector(jobSwitchAction:)
            forControlEvents:UIControlEventValueChanged];
        
        // in case the parent view draws with a custom color or gradient, use a transparent color
        theSwitch.backgroundColor = [UIColor clearColor];

        theSwitch.tag = row;

        if (j.jobEnable == nil)
            j.jobEnable = @1;

        theSwitch.on = j.jobEnable.boolValue;
        [theSwitch setAccessibilityLabel:NSLocalizedString(@"Shift Enable Display on Calender", @"accessibility label for enable shift")];
        
        for  (id a in cell.contentView.subviews) {
            if ([a isKindOfClass:theSwitch.class]) {
                [a removeFromSuperview];
            }
        }
        if (!self.editing)
            [cell.contentView addSubview:theSwitch];
        
    }
    } @catch (NSException *e) {
        NSLog(@"Got exception when configure cell at %ld %@",(long)row, e);
    }
    
}

#pragma mark - Profile View Delegete

/**
   Notification from the add controller's context's save operation. This is used to update the fetched results controller's managed object context with the new book instead of performing a fetch (which would be a much more computationally expensive operation).
*/
- (void)addControllerContextDidSave:(NSNotification*)saveNotification {
	
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    // Merging changes causes the fetched results controller to update its results
    [context mergeChangesFromContextDidSaveNotification:saveNotification];
    [context save:nil];
    [self.fetchedResultsController performFetch:NULL];
    [self.fetchedResultsControllerOOD performFetch:NULL];
    [self.tableView reloadData];
}

- (void) didChangeProfile:(ShiftProfileChangeViewController *) addController
				didFinishWithSave:(BOOL) finishWithSave
{
    NSError *error = nil;

    if (finishWithSave) {
        if (addController.viewMode == PCVC_EDITING_MODE) {
            if (![self.managedObjectContext save:&error])
                NSLog(@"Unresolved error can not save editing profile %@, %@", error, [error userInfo]);
        } else {

            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            [dnc addObserver:self selector:@selector(addControllerContextDidSave:)
                        name:NSManagedObjectContextDidSaveNotification
                      object:addingManagedObjectContext];
            
            if (![addingManagedObjectContext save:&error]) {
                // Update to handle the error appropriately.
                NSLog(@"Unresolved can not saveerror %@, %@", error, [error userInfo]);
            }
            [dnc removeObserver:self
                           name:NSManagedObjectContextDidSaveNotification
                         object:addingManagedObjectContext];
        }
    } else {
        [self.addingManagedObjectContext reset];
        
        // reset will cancel any not saved data, so the change made in edit view will also discard.
        [self.managedObjectContext reset];

        [self.fetchedResultsController performFetch:NULL];
        [self.tableView reloadData];
    }
    // Release the adding managed object context.
    self.addingManagedObjectContext = nil;
    
    // Dismiss the modal view to return to the main list
    [self dismissViewControllerAnimated:YES completion:nil];

}
@end


