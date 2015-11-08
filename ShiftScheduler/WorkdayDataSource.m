//
//  WorkdayDataSource.m
//  Holiday
//
//  Created by Zhang Jiejing on 11-10-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "WorkdayDataSource.h"
#import "NSDateAdditions.h"
#import "SSDefaultConfigName.h"
#import "SSLunarDate/SSLunarDate.h"
#import "SSLunarDate/SSHolidayManager.h"
#import "SSDayEventUTC.h"
#import "UIColor+HexCoding.m"
#import "I18NStrings.h"
#import "SSHolidayHelper.h"
#import "SSNoteAppendingTVC.h"

#define ONE_DAY_SECONDS (60*60*24)
#define HALF_DAY_SECONDS (60*60*12)

static int kWDSAddNoteFontSize = 14;  // font size of Note 

@interface WorkdayDataSource()
{
  NSArray *_cachedRegionList;
  NSArray *_holidayManagers;
}

@property (readonly) NSArray *holidayManagers;
@property (readonly) NSArray *cachedRegionList;

@end

@implementation WorkdayDataSource

#define JOB_CACHE_INDEFITER @"JobNameCache"


@synthesize jobFetchRequestController;
@synthesize theJobNameArray;
@synthesize timeFormatter, objectContext;
- (id)init
{
    self = [super init];
    if (self) {
        items = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regionChangedNotifyHandler) name:HOLIDAY_REGION_CHANGED_NOTICE object:nil];
        _currentChoosenDate = [NSDate date];
    }

    return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) regionChangedNotifyHandler
{
    _holidayManagers = nil;
    _cachedRegionList = nil;
    [callback loadedDataSource:self];
}

- (NSDateFormatter *) timeFormatter
{
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return timeFormatter;
}

- (NSArray *) cachedRegionList
{
    if (_cachedRegionList == nil) {
        NSArray *storedList = [[NSUserDefaults standardUserDefaults] objectForKey:USER_CONFIG_HOLIDAY_REGION];
        _cachedRegionList = storedList;
    }
    return _cachedRegionList;
}

- (NSArray *) holidayManagers
{
    if (_holidayManagers == nil) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (int i = 0; i < [self.cachedRegionList count]; i++) {
            NSNumber *n = [self.cachedRegionList objectAtIndex:i];
            if (n.intValue == YES) {
                SSHolidayManager *m = [[SSHolidayManager alloc] initWithRegion:(SSHolidayRegion)i];
                [array addObject:m];
            }
        }
        _holidayManagers = array;
    }

    return _holidayManagers;
}


#pragma mark - TableView

- (NSFetchedResultsController *) jobFetchRequestController
{
    if (jobFetchRequestController != nil) {
        return jobFetchRequestController;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob" 
                                              inManagedObjectContext:self.objectContext];
    [request setEntity:entity];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor
                                                           sortDescriptorWithKey:@"jobEverydayStartTime"
                                                                       ascending:YES]];
    

    request.predicate = [NSPredicate predicateWithFormat:@"jobEnable == YES"];
    request.fetchBatchSize = 20;
    [request setReturnsObjectsAsFaults:NO];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] 
                                       initWithFetchRequest:request 
                                       managedObjectContext:self.objectContext
                                       sectionNameKeyPath:nil 
                                       cacheName:JOB_CACHE_INDEFITER];
    jobFetchRequestController = frc;
    return frc;
}

#pragma mark - Holiday Related

- (NSArray *) getHolidayForDate:(NSDate *) date
{
    return [SSHolidayHelper getHolidayForDate:date holidayManagers:self.holidayManagers];
}

- (NSArray *) getHolidayFromDateToDate:(NSDate *) fromDate  endDate:(NSDate *) toDate
{
    return [SSHolidayHelper getHolidayFromDateToDate:fromDate endDate:toDate holidayManagers:self.holidayManagers];
}

- (id) initWithManagedContext:(NSManagedObjectContext *)thecontext
{
    self = [self init];
    self.objectContext = thecontext;

#if 1
    NSError *error = 0;

    [self.jobFetchRequestController performFetch:&error];
    if (error)
        NSLog(@"fetch request error:%@", error.userInfo);
#endif
    self.jobFetchRequestController.delegate = self;
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self
            selector:@selector(managedContextDataChanged:)
                name:NSManagedObjectContextDidSaveNotification
              object:self.objectContext];

    return  self;
}

- (void) managedContextDataChanged:(NSNotification *) saveNotifaction
{
    [self.jobFetchRequestController performFetch:nil];
    theJobNameArray = nil;
    _holidayManagers = nil;
    [callback loadedDataSource:self];
}

- (BOOL) isLunarDateDisplayEnable
{
    return [[NSUserDefaults standardUserDefaults]
            boolForKey:USER_CONFIG_ENABLE_LUNAR_DAY_DISPLAY];
}

- (NSArray *)theJobNameArray 
{
    theJobNameArray = self.jobFetchRequestController.fetchedObjects;
    return theJobNameArray;
}

#pragma mark UITableViewDataSource protocol conformance

- (OneJob *) jobAtIndexPath:(NSIndexPath *)indexPath
{
    return [items objectAtIndex:indexPath.row];
}

- (UITableViewCell *)setupHolidayCell
{
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"SSDayEventUTC"
                                                   owner:self
                                                 options:nil];
    
    SSDayEventUTC *cell = [views objectAtIndex:0];
    cell.lunarLabel.text = nil;
    cell.holidayLabel.text = nil;
    cell.lunarLabel.textColor = [UIColor colorWithHexString:@"2C3E50"];
    cell.holidayLabel.textColor = [UIColor colorWithHexString:@"D35400"];
    
    if ([self isLunarDateDisplayEnable]) {
        SSLunarDate *lunarDate = [[SSLunarDate alloc] initWithDate:self.currentChoosenDate];
        
        if ([lunarDate convertSuccess])
            cell.lunarLabel.text = [NSString stringWithFormat:@"%@:%@%@",
                                    LUNAR_FMT_START_STRING,
                                    [lunarDate monthString],
                                    [lunarDate dayString]];
    }
    
    if (self.currentChoosenDate != nil) {
        NSArray *holidays = [self getHolidayForDate:self.currentChoosenDate];
        if ([holidays count] > 0)
            cell.holidayLabel.text = [holidays objectAtIndex:0];
    }
    
    return cell;
}

- (BOOL) isCurrentDateNeedsShowHoliday {
   return  [self isLunarDateDisplayEnable]
            || (self.currentChoosenDate && [self getHolidayForDate:self.currentChoosenDate].count > 0);
}

- (UITableViewCell *)setupWorkdayCell:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"WorkdayNormalCell"];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"WorkdayNormalCell"];
    
    OneJob *job = [self jobAtIndexPath: indexPath];
    cell.textLabel.text = job.jobName;
    
    if ([job getJobEverydayStartTime] != Nil)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                     [job jobEverydayStartTimeWithFormatter:self.timeFormatter],
                                     [job jobEverydayOffTimeWithFormatter:self.timeFormatter]];
    cell.imageView.image = job.middleSizeImage;
    return cell;
}

- (UITableViewCell *)setupNoteCell:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"NoteCell"];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoteCell"];
    
    cell.textLabel.text = @"Click to add Note";
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:kWDSAddNoteFontSize];

    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
	 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && [self isCurrentDateNeedsShowHoliday])
        return [self setupHolidayCell];
    else {
        if (indexPath.row < items.count)
            return [self setupWorkdayCell:tableView indexPath:indexPath];
        else {  // shift file is over, let move into notes area.
            return [self setupNoteCell:tableView  indexPath:indexPath];
        }
    }

    NSLog(@"work day data source return an nil cell");
    return nil;
}

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
//        [self startAddNote];
}

- (void)startAddNote
{
    
    UINavigationController *nav = [[UINavigationController alloc] init];
    SSNoteAppendingTVC *noteaddVC = [[SSNoteAppendingTVC alloc] init];
    
    [nav  pushViewController:noteaddVC animated:NO];
    // Create a new managed object context for the new book -- set its persistent store coordinator to the same as that from the fetched results controller's context.
    NSManagedObjectContext *addingContext = [[NSManagedObjectContext alloc] init];
    [addingContext setPersistentStoreCoordinator:[self.objectContext persistentStoreCoordinator]];
    addingContext.undoManager = nil; // Undo manager is not needed here.

    //    noteaddVC.managedContext = addingContext;
    // use same manage object context can auto update the frc.
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:noteaddVC];
    if (self.globalNavController != nil) {
        [self.globalNavController presentViewController:nav animated:YES completion:nil];
    }
}

- (BOOL) needsDisplayInformationBar
{
    if ([self isLunarDateDisplayEnable]
        || (self.currentChoosenDate && [self getHolidayForDate:self.currentChoosenDate].count > 0))
        return YES;
    return NO;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self needsDisplayInformationBar] && section == 0)
        return 1;
    else
        return [items count]; // [items count] + 1; // only for add note function.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self needsDisplayInformationBar])
        return 2;
    else
        return 1;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat def = 44.0f;
    
    if ([self needsDisplayInformationBar] && indexPath.section == 0 && indexPath.row == 0) {
        return def * 0.75;
    } else
        return def;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.rowHeight == UITableViewAutomaticDimension)
        return tableView.rowHeight;

    if ([self needsDisplayInformationBar] && indexPath.section == 0 && indexPath.row == 0) {
        return tableView.rowHeight * 0.75;
    } else
        return  tableView.rowHeight;
}


#pragma mark KalDataSource protocol conformance

- (void)updateSelectDay:(NSDate *)date
{
  _currentChoosenDate = date;
}

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate 
		   delegate:(id<KalDataSourceCallbacks>)delegate
{
    [delegate loadedDataSource:self];
    callback = delegate;
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{

    NSMutableArray *markedDayArray = [[NSMutableArray alloc] init];
    
    for (OneJob *j in self.theJobNameArray) {
        [markedDayArray addObjectsFromArray:[j returnWorkdaysWithInStartDate:fromDate endDate:[toDate dateByAddingTimeInterval:ONE_DAY_SECONDS]]];
    }
    
    [markedDayArray addObjectsFromArray:[self getHolidayFromDateToDate:fromDate endDate:toDate]];
    
    return  markedDayArray;
}

- (void) loadItemsForData:(NSDate *)date toArray:(NSMutableArray *)array
{
    for (OneJob *job in self.theJobNameArray) {
        if ([job isDayWorkingDay:date]) {
            [array addObject:job];
        }
    }
}


- (void) loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate toArray: (NSMutableArray *)array
{
    NSDate *nextday;
    
    for (nextday = fromDate;
         [nextday timeIntervalSinceDate:toDate] < 0;
         // FIXME: why ???? dont understand now...
         nextday =  [nextday dateByAddingTimeInterval:24*60*60]) {
        [self loadItemsForData:nextday toArray:array];
    }
}


- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    [self loadItemsFromDate:fromDate toDate:toDate toArray:items];
}

- (void)removeAllItems
{
    [items removeAllObjects];
}

#pragma mark - TileViewIconDelegate

// Tile View Icon delegate
- (NSArray *) KalTileDrawDelegate: (KalTileView *) sender getIconDrawInfoWithDate: (NSDate *) date
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];

    NSMutableArray *tjobArray = [[NSMutableArray alloc] init];

    [self loadItemsForData:date toArray:tjobArray];
    
    NSArray *holidays = [self getHolidayForDate:date];
    if ([holidays lastObject] != nil) {
        NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt:KAL_TILE_ICON_TYPE_HOLIDAY],    KAL_TILE_ICON_TYPE_KEY,
                               [NSNumber numberWithInt:KAL_TILE_ICON_POSITION_BOTTOM], KAL_TILE_ICON_POS_KEY,
                               nil];
        [resultArray addObject:entry];
    }
    
    // FIXME: because some bug in shift module, is possible not found
    // the shift item here, return a default icon to workaround and
    // print a warnning.
    if (tjobArray.count == 0 && resultArray.count == 0)  {
        NSLog(@"Warnning: Return nil in KalTileDrawDelegate: this should not happens:date:%@", date);
        NSAssert(NO, @"Warnning: Return nil in KalTileDrawDelegate: this should not happens:date:%@", date);
        return nil;
    } else if (tjobArray == 0) {
        return resultArray;
    }

    // First, deal with shift icons.
    for (id j in tjobArray) {
        if (j && [j isKindOfClass:[OneJob class]]) {
            OneJob *job = j;

            NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:KAL_TILE_ICON_TYPE_SHIFT], KAL_TILE_ICON_TYPE_KEY,
                                   [NSNumber numberWithInt:KAL_TILE_ICON_POSITION_TOP], KAL_TILE_ICON_POS_KEY,
                                   job.iconImage,                                       KAL_TILE_ICON_IMAGE_KEY,
                                   job.iconColor,                                       KAL_TILE_ICON_COLOR_KEY,
                                   [job.jobName substringWithRange:NSMakeRange(0, 1)],  KAL_TILE_ICON_TEXT_KEY,
                                   job.jobShowTextInCalendar,                           KAL_TILE_ICON_IS_SHOW_TEXT_KEY,
                                   nil];
            [resultArray addObject:entry];
        }
    }

    // Then, add a icon that to notice the day was a holiday, the Kal
    // will draw the icon.
    
    return resultArray;   
}

#pragma mark - FetchedResultController 

/**
 Delegate methods of NSFetchedResultsController to respond to
 additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	// The fetch controller is about to start sending change
	// notifications, so prepare the table view for updates.
}


- (void)controller:(NSFetchedResultsController *)controller
        didChangeObject:(id)anObject
        atIndexPath:(NSIndexPath *)indexPath
        forChangeType:(NSFetchedResultsChangeType)type
        newIndexPath:(NSIndexPath *)newIndexPath
{
    [callback loadedDataSource:self];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller has sent all current change
	// notifications, so tell the table view to process all
	// updates.
    self.theJobNameArray = nil;
}

@end
