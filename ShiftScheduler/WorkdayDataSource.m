//
//  WorkdayDataSource.m
//  Holiday
//
//  Created by Zhang Jiejing on 11-10-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "WorkdayDataSource.h"
#import "NSDateAdditions.h"

@implementation WorkdayDataSource

#define JOB_CACHE_INDEFITER @"JobNameCache"

@synthesize fetchedRequestController;
@synthesize theJobNameArray;
@synthesize timeFormatter, objectContext;

- (id)init
{
    self = [super init];
    if (self) {
        items = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSDateFormatter *) timeFormatter
{
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return timeFormatter;
}

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
    [callback loadedDataSource:self];
    
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

    OneJob *job = [self jobAtIndexPath: indexPath];
    
    cell.textLabel.text = job.jobName;
    
    if ([job getJobEverydayStartTime] != Nil)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
					      [job jobEverydayStartTimeWithFormatter:self.timeFormatter],
					      [job jobEverydayOffTimeWithFormatter:self.timeFormatter]];
    cell.imageView.image = job.iconImage;
    return cell;
}
    

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [items count];
}


#pragma mark KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate 
		   delegate:(id<KalDataSourceCallbacks>)delegate
{
    [delegate loadedDataSource:self];
    callback = delegate;
}

#define ONE_DAY_SECONDS (60*60*24)
#define HALF_DAY_SECONDS (60*60*12)
- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{


    NSMutableArray *markedDayArray = [[NSMutableArray alloc] init];
    
    for (OneJob *j in self.theJobNameArray) {
        [markedDayArray addObjectsFromArray:[j returnWorkdaysWithInStartDate:fromDate 
								     endDate:toDate]];
    }
    
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

    // FIXME: because some bug in shift module, is possible not found
    // the shift item here, return a default icon to workaround and
    // print a warnning.
    if (tjobArray.count == 0)  {
        NSLog(@"Warnning: Return nil in KalTileDrawDelegate: this should not happens:date:%@", date);
        NSAssert(NO, @"Warnning: Return nil in KalTileDrawDelegate: this should not happens:date:%@", date);
        return nil;
    }

    for (id j in tjobArray) {
        if (j && [j isKindOfClass:[OneJob class]]) {
            OneJob *job = j;
            int drawType;
            if (job.iconColor == nil)
                drawType = KAL_TILE_DRAW_METHOD_COLOR_ICON;
            else
                drawType = KAL_TILE_DRAW_METHOD_MONO_ICON_FILL_COLOR;

            NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys: 
                                   [NSNumber numberWithInt:drawType], KAL_TILE_ICON_DRAW_TYPE_KEY,
                                   job.iconImage, KAL_TILE_ICON_IMAGE_KEY,
                                   job.iconColor, KAL_TILE_ICON_COLOR_KEY,
                                   [job.jobName substringWithRange:NSMakeRange(0, 1)], KAL_TILE_ICON_TEXT,
                                   job.jobShowTextInCalendar, KAL_TILE_ICON_IS_SHOW_TEXT,
                                                nil];
            [resultArray addObject:entry];
        }
    }
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
