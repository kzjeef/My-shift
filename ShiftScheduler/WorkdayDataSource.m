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

#define ONE_DAY_SECONDS (60*60*24)
#define HALF_DAY_SECONDS (60*60*12)


@interface WorkdayDataSource()
{
    NSArray *_cachedRegionList;
    NSArray *_holidayManagers;
}

@property (readonly) NSArray *holidayManagers;
@property (readonly) NSArray * cachedRegionList;

@end

@implementation WorkdayDataSource

#define JOB_CACHE_INDEFITER @"JobNameCache"

#define LUNAR_CONVERT_ERROR_TITLE_STR  NSLocalizedString(@"No Lunar Date", "not able to generate lunar Date title")
#define LUNAR_CONVERT_ERROR_DETAIL_STR  NSLocalizedString(@"lunar date out of range.", "not able to generate lunar Date title")

#define LUNAR_FMT_START_STRING  NSLocalizedString(@"Lunar", "")


@synthesize fetchedRequestController;
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

- (void) regionChangedNotifyHandler
{
    [callback loadedDataSource:self];
}

- (NSArray *) cachedRegionList
{
    NSArray *storedList = [[NSUserDefaults standardUserDefaults] objectForKey:USER_CONFIG_HOLIDAY_REGION];
    _cachedRegionList = [storedList copy];
    return _cachedRegionList;
}

- (NSArray *) holidayManagers
{
    
    // Without ARC, this should be better handle, since region changed will
    // leak orignall array.
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.cachedRegionList count]; i++) {
        NSNumber *n = [self.cachedRegionList objectAtIndex:i];
        if (n.intValue == YES) {
            SSHolidayManager *m = [[SSHolidayManager alloc] initWithRegion:(SSHolidayRegion)i];
            [array addObject:m];
        }
    }
    _holidayManagers = array;

    return _holidayManagers;
}



- (NSDateFormatter *) timeFormatter
{
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return timeFormatter;
}



#pragma mark - TableView

- (NSFetchedResultsController *) fetchedRequestController
{
    if (fetchedRequestController != nil) {
        return fetchedRequestController;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob" 
                                              inManagedObjectContext:self.objectContext];
    [request setEntity:entity];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor
                                                           sortDescriptorWithKey:@"jobName"
                                                                       ascending:YES]];
    

    request.predicate = [NSPredicate predicateWithFormat:@"jobEnable == YES"];
    request.fetchBatchSize = 20;
    [request setReturnsObjectsAsFaults:NO];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] 
                                       initWithFetchRequest:request 
                                       managedObjectContext:self.objectContext
                                       sectionNameKeyPath:nil 
                                       cacheName:JOB_CACHE_INDEFITER];
    fetchedRequestController = frc;
    return frc;
}

#pragma mark - Holiday Related

- (NSArray *) getHolidayForDate:(NSDate *) date
{
    NSAssert(date != nil, @"Date not should nil");
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (SSHolidayManager *m in self.holidayManagers) {
        NSArray *a = [m getHolidayListForDate:date];
        if (a != nil && [a lastObject] != nil)
            [result addObjectsFromArray:a];
    }
    
    return result;
}

- (NSArray *) getHolidayFromDateToDate:(NSDate *) fromDate  endDate:(NSDate *) toDate {
    
    NSDate *d = [fromDate copy];
    NSMutableArray *res = [[NSMutableArray alloc] init];
    while (true) {
        NSArray *a = [self getHolidayForDate:d];
        if ([a lastObject] != nil)
            [res addObject:[d copy]];
        d = [d dateByAddingTimeInterval:ONE_DAY_SECONDS];
        if ([d compare:toDate] == NSOrderedDescending)
            break;
    }
    return res;
}



- (id) initWithManagedContext:(NSManagedObjectContext *)thecontext
{
    self = [self init];
    self.objectContext = thecontext;

#if 1
    NSError *error = 0;

    [self.fetchedRequestController performFetch:&error];
    if (error)
        NSLog(@"fetch request error:%@", error.userInfo);
#endif
    self.fetchedRequestController.delegate = self;
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self
            selector:@selector(managedContextDataChanged:)
                name:NSManagedObjectContextDidSaveNotification
              object:self.objectContext];

    return  self;
}

- (void) managedContextDataChanged:(NSNotification *) saveNotifaction
{
    
    [self.fetchedRequestController performFetch:nil];
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
    theJobNameArray = self.fetchedRequestController.fetchedObjects;
    return theJobNameArray;
}

#pragma mark UITableViewDataSource protocol conformance

- (OneJob *) jobAtIndexPath:(NSIndexPath *)indexPath
{
    return [items objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
	 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WorkCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"WorkCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    
    if ([self isLunarDateDisplayEnable] && indexPath.section == 0) {
        SSLunarDate *lunarDate = [[SSLunarDate alloc] initWithDate:self.currentChoosenDate];
        
        if ([lunarDate convertSuccess]) {
            cell.textLabel.text =  [NSString stringWithFormat:@"%@:%@%@",
                                    LUNAR_FMT_START_STRING,
                                    [lunarDate monthString],
                                    [lunarDate dayString]];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@(%@)",
                                         [lunarDate yearGanzhiString],
                                         [lunarDate zodiacString]];
        } else {
            cell.textLabel.text = LUNAR_CONVERT_ERROR_TITLE_STR;
            cell.detailTextLabel.text = LUNAR_CONVERT_ERROR_DETAIL_STR;
        }
        cell.imageView.image = nil;
    } else {
        OneJob *job = [self jobAtIndexPath: indexPath];
        cell.textLabel.text = job.jobName;
    
    if ([job getJobEverydayStartTime] != Nil)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                     [job jobEverydayStartTimeWithFormatter:self.timeFormatter],
                                     [job jobEverydayOffTimeWithFormatter:self.timeFormatter]];
        cell.imageView.image = job.middleSizeImage;
    }
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isLunarDateDisplayEnable]) {
        if (section == 0)
            return 1;
        else
            return [items count];
    } else
        return [items count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self isLunarDateDisplayEnable]) {
        return 2;
    } else
        return 1;
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
    
    for (nextday = fromDate; [nextday timeIntervalSinceDate:toDate] < 0;
         // FIXME: why ???? dont understand now...
         nextday = 
         [nextday dateByAddingTimeInterval:24*60*60]) {
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller is about to start sending change
	// notifications, so prepare the table view for updates.
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	[callback loadedDataSource:self];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller has sent all current change
	// notifications, so tell the table view to process all
	// updates.
    
    self.theJobNameArray = nil;
}

@end
