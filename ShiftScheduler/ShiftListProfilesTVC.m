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
#import "UIColor+HexCoding.h"


#define PROFILE_CACHE_INDIFITER @"ProfileListCache"

enum {
    SECTION_NORMAL_SHIFT = 0,
    SECTION_OUTDATE_SHIFT,
    SECTION_ADD_NEW_SHIFT,
    SECTION_SIZE,
} ;


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
    self.title = NSLocalizedString(@"Shift Manage", "shift management view");
    self.managedObjectContext = context;
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) returnToHome
{
    [self.parentViewDelegate didFinishEditingSetting];
}

- (NSInteger) profileuNumber
{
    return [self.fetchedResultsController.fetchedObjects count] + [self.fetchedResultsControllerOOD.fetchedObjects count];
}

/* FIXME  This was ugly, but tag only can pass one value, the -tag will always < 0xffff, hope user don't create so much shift... */
#define MAGIC_OFFSET 0xffff

- (void)jobSwitchAction:(id) sender
{
    UISwitch *currentSwitch = sender;
    OneJob *j;
    int position;
    if (currentSwitch.tag >= 0) {
        position = currentSwitch.tag;
        if (self.fetchedResultsController.fetchedObjects.count > position)
            j = [self.fetchedResultsController.fetchedObjects objectAtIndex:position];
    } else {
        // FIXME: here we use a nagtive value to pass the info.
        position = currentSwitch.tag + MAGIC_OFFSET;
        if (self.fetchedResultsController.fetchedObjects.count > position)
            j = [self.fetchedResultsControllerOOD.fetchedObjects objectAtIndex:position];
    }
    if (j == nil) {
        NSLog(@"not found any object at index: %d", position);
        return;
    }
    j.jobEnable = @(currentSwitch.isOn);
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

- (NSDateFormatter *) timeFormatter
{
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return timeFormatter;
}

- (IBAction)insertNewProfile:(id) sender
{
    ShiftProfileChangeViewController *addViewController = [[ShiftProfileChangeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    addViewController.viewMode = PCVC_ADDING_MODE;
	
    // Create a new managed object context for the new book -- set its persistent store coordinator to the same as that from the fetched results controller's context.
    NSManagedObjectContext *addingContext = [[NSManagedObjectContext alloc] init];
    self.addingManagedObjectContext = addingContext;
    
#if 1
    [addingManagedObjectContext setPersistentStoreCoordinator:[[self.fetchedResultsController managedObjectContext] persistentStoreCoordinator]];
    
#else 
    // this below not work....
    NSManagedObjectModel *model = [[[self.fetchedResultsController managedObjectContext] persistentStoreCoordinator] managedObjectModel];
    
    NSPersistentStoreCoordinator *newco = [[NSPersistentStoreCoordinator alloc]
                                           initWithManagedObjectModel:model];
    [newco addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
    [self.addingManagedObjectContext setPersistentStoreCoordinator:newco];
#endif
    addViewController.managedObjectContext = addingContext;
    // use same manage object context can auto update the frc.
    OneJob *job = [NSEntityDescription insertNewObjectForEntityForName:@"OneJob" inManagedObjectContext:addingContext];
    [job forceDefaultSetting];

    addViewController.theJob = job;
    addViewController.profileDelegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addViewController];
    [self.navigationController presentModalViewController:navController animated:YES];
}

#pragma mark -
#pragma mark Fetched results controller


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
        request.predicate = [NSPredicate predicateWithFormat:@"(jobFinishDate != nil) && (jobFinishDate < %@)", [NSDate date]];
    }
    @catch (NSException *exception) {
        NSLog(@"got exception... %@ %@", [exception name], [exception reason] );
        return NULL;
    }
    
    request.fetchBatchSize = 20;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                          managedObjectContext:self.managedObjectContext
                                                                            sectionNameKeyPath:Nil cacheName:nil];
    fetchedResultsControllerOOD = frc;
    return fetchedResultsControllerOOD;
}


/**
 Returns the fetched results controller. Creates and configures the controller if necessary.
*/
- (NSFetchedResultsController *)fetchedResultsController 
{
    
    if (fetchedResultsController != nil)
        return fetchedResultsController;

    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"jobName"  ascending:YES]];

    request.predicate = [NSPredicate predicateWithFormat:@"(jobFinishDate == nil) || (jobFinishDate >= %@) ", [NSDate date]];
    request.fetchBatchSize = 20;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] 
                                       initWithFetchRequest:request 
                                       managedObjectContext:self.managedObjectContext
                                       sectionNameKeyPath:nil 
                                       cacheName:Nil];
    fetchedResultsController = frc;
    return frc;
}


/**
 Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	[self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *tableView = self.tableView;
    
    switch(type) {
			
    case NSFetchedResultsChangeInsert:
        [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        break;
			
    case NSFetchedResultsChangeDelete:
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        break;
			
    case NSFetchedResultsChangeUpdate:
//        if (indexPath.section == SECTION_NORMAL_SHIFT)
//            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
//                    atIndexPath:indexPath.row
//                        withFrc:self.fetchedResultsController];
//        else
//            if (indexPath.row > 0)
//                [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
//                    atIndexPath:indexPath.row - 1
//                        withFrc:self.fetchedResultsControllerOOD];
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
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:(@selector(insertNewProfile:))];
    [self.navigationItem setLeftBarButtonItem:addButton];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

        //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home", @"return to home in profile view") style:UIBarButtonItemStylePlain target:self action:@selector(returnToHome)];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error fetchShifts %@, %@", error, [error userInfo]);
		abort();
    }
    self.fetchedResultsController.delegate = self;

    NSError *ooderr;
    if (![self.fetchedResultsControllerOOD performFetch:&ooderr]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error fetchOODShifts %@, %@", ooderr, [ooderr userInfo]);
		exit(-1);  // Fail
    }
    self.fetchedResultsControllerOOD.delegate = self;

    plusImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"addButton" ofType:@"png"]];
    
}



- (void)viewDidUnload
{
    [super viewDidUnload];
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

- (NSInteger)numberOfObjectsOfFrc:(NSFetchedResultsController *) frc
{
    return [frc.fetchedObjects count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int normalshifts = [self numberOfObjectsOfFrc:self.fetchedResultsController];
    int oodshifts = [self numberOfObjectsOfFrc:self.fetchedResultsControllerOOD];
    
    if (section == SECTION_NORMAL_SHIFT && normalshifts  > 0 )
        return normalshifts;
    else if (section == SECTION_OUTDATE_SHIFT && oodshifts > 0) {
        if (_expendOutOfDateShifts)
            return  oodshifts + 1;
        else 
            return 1;
    } else if (section == SECTION_ADD_NEW_SHIFT)
        return 1;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SECTION_NORMAL_SHIFT &&
        [self.fetchedResultsController.fetchedObjects count] > 0) {
        return NSLocalizedString(@"Shift Manage", "");
    } else if (section == SECTION_OUTDATE_SHIFT &&
               [self numberOfObjectsOfFrc: self.fetchedResultsControllerOOD])
        return NSLocalizedString(@"Archived Shifts", "out of date shift is archived");
    return  [NSString string] ;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([self.fetchedResultsController.fetchedObjects count] > 0 && section == 0) {
        return NSLocalizedString(@"choose to change shift detail", "");
    } else if (section == SECTION_OUTDATE_SHIFT &&
               [self numberOfObjectsOfFrc: self.fetchedResultsControllerOOD])
        return NSLocalizedString(@"archive for shifts already out of date ", "out of date shift is archived");
    return  [NSString string] ;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellOfProfileCell";
    static NSString *clearCellIdentifier = @"CellProfileCellClean";
    NSString *indentifer;
    
    
    UITableViewCell *cell;
    
    if (indexPath.section == SECTION_ADD_NEW_SHIFT || (indexPath.section == SECTION_OUTDATE_SHIFT && indexPath.row == 0))
        indentifer = clearCellIdentifier;
    else
        indentifer = cellIdentifier;

    cell = [tableView dequeueReusableCellWithIdentifier:indentifer];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:indentifer];

    if (indexPath.section == SECTION_NORMAL_SHIFT)
        [self configureCell:cell atIndexPath:indexPath.row withFrc:self.fetchedResultsController];
    else if (indexPath.section == SECTION_ADD_NEW_SHIFT) {
        cell.imageView.image = plusImage;
        cell.textLabel.text = NSLocalizedString(@"Adding new shift...", "add new shift");
        cell.textLabel.textColor = [UIColor colorWithHexString:@"283DA0"];
    } else  {
        // Handle for show/hide archive shifts of out of date.
        if (indexPath.row == 0) {
            NSString *tt = NSLocalizedString(@"Outdated Shifts", "expand archived shifts");
            NSString *text = [NSString stringWithFormat:@"%@ (%d)",
                              tt, [self numberOfObjectsOfFrc:self.fetchedResultsControllerOOD]];
            cell.textLabel.text = text;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor colorWithHexString:@"283DA0"];
        } else {
            if (_expendOutOfDateShifts)
                [self configureCell:cell atIndexPath:indexPath.row - 1
                            withFrc:self.fetchedResultsControllerOOD];
        }
    }
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.

    if (indexPath.section == SECTION_ADD_NEW_SHIFT)
        return NO;
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
        return UITableViewCellEditingStyleDelete;
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
        if (indexPath.section == SECTION_NORMAL_SHIFT)
            [self.managedObjectContext
                deleteObject:[self.fetchedResultsController
                                 objectAtIndexPath:indexPath]];
        else if (indexPath.section == SECTION_OUTDATE_SHIFT)
            [self.managedObjectContext
                deleteObject:[self.fetchedResultsControllerOOD
                                 objectAtIndexPath:indexPath]];
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
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

#pragma mark - Table view delegate

- (void) openProfileEditView: (NSInteger)row withFrc: (NSFetchedResultsController *)frc
{
    ShiftProfileChangeViewController *pcvc = [[ShiftProfileChangeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    pcvc.theJob = [frc.fetchedObjects objectAtIndex:row];
    pcvc.profileDelegate = self;
    pcvc.managedObjectContext = self.managedObjectContext;
    pcvc.viewMode = PCVC_EDITING_MODE;
    UINavigationController *navController = [[UINavigationController alloc]
                                                initWithRootViewController:pcvc];
    [self.navigationController presentModalViewController:navController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_NORMAL_SHIFT) {
        [self openProfileEditView:indexPath.row
                          withFrc:self.fetchedResultsController];
    } else if (indexPath.section == SECTION_OUTDATE_SHIFT) {
        // ... if row is 0, toggle show and hide OOD shifts.
        if (indexPath.row == 0) {
            _expendOutOfDateShifts = !_expendOutOfDateShifts;
            
              [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_OUTDATE_SHIFT]
                            withRowAnimation:UITableViewRowAnimationAutomatic];

  
        } else {
            [self openProfileEditView:indexPath.row - 1
                              withFrc:self.fetchedResultsControllerOOD];
        }
    } else
        [self insertNewProfile:nil];
}

- (void)configureCell:(UITableViewCell *)cell
          atIndexPath:(NSInteger) row
              withFrc:(NSFetchedResultsController *)frc
    
{
    id t = [frc.fetchedObjects objectAtIndex:row];
    if ([t isKindOfClass:[OneJob class]]) {
        OneJob *j = t;
        cell.textLabel.text = j.jobName;
        cell.imageView.image = j.iconImage;

        if ([j getJobEverydayStartTime] != Nil)
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                                  [j jobEverydayStartTimeWithFormatter:self.timeFormatter],
                                                  [j jobEverydayOffTimeWithFormatter:self.timeFormatter]];
        
        UISwitch *theSwitch;
        CGRect frame = CGRectMake(200, 8.0, 120.0, 27.0);
        theSwitch = [[UISwitch alloc] initWithFrame:frame];
        [theSwitch addTarget:self action:@selector(jobSwitchAction:)
            forControlEvents:UIControlEventValueChanged];
        
        // in case the parent view draws with a custom color or gradient, use a transparent color
        theSwitch.backgroundColor = [UIColor clearColor];

        // FIXME Here we use trick to figure out which OOD or not.
        // OOD use a nagtive value, tag is a int value.
        theSwitch.tag = row;

        if (frc == self.fetchedResultsControllerOOD)
            theSwitch.tag = (theSwitch.tag - MAGIC_OFFSET);
        
        //XXX: for complicate the old job data modole.
        if (j.jobEnable == nil)
            j.jobEnable = @1;

        theSwitch.on = j.jobEnable.boolValue;
		
		[theSwitch setAccessibilityLabel:NSLocalizedString(@"Shift Enable Display on Calender", @"")];
        
        for  (id a in cell.contentView.subviews) {
            if ([a isKindOfClass:theSwitch.class]) {
                [a removeFromSuperview];
            }
        }

        [cell.contentView addSubview:theSwitch];
        
    }
}

#pragma mark - Profile View Delegete

/**
 Notification from the add controller's context's save operation. This
 is used to update the fetched results controller's managed object
 context with the new book instead of performing a fetch (which would
 be a much more computationally expensive operation).
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
    }
    // Release the adding managed object context.
    self.addingManagedObjectContext = nil;
    
    // Dismiss the modal view to return to the main list
    [self dismissModalViewControllerAnimated:YES];
}



@end


