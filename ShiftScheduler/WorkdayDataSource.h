//
//  WorkdayDataSource.h
//  Holiday
//
//  Created by Zhang Jiejing on 11-10-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "Kal.h"
#import "OneJob.h"

@interface WorkdayDataSource : NSObject  <KalDataSource, NSFetchedResultsControllerDelegate, KalTileIconDelegate, UITableViewDelegate>
{
    //WorkDateGenerator *generator;
    //NSArray *jobsArray;
    NSManagedObjectContext * objectContext;
    NSFetchedResultsController * jobFetchRequestController;
    NSArray *theJobNameArray;
    NSMutableArray*items;
    NSDateFormatter *timeFormatter;
    NSDate *_currentChoosenDate;
    id<KalDataSourceCallbacks> callback;

}

@property (strong, nonatomic) NSDate *currentChoosenDate;
@property (strong, nonatomic) NSArray *theJobNameArray;
@property (strong, nonatomic) NSFetchedResultsController *jobFetchRequestController;
@property (strong, nonatomic) NSDateFormatter *timeFormatter;
@property (strong, nonatomic) NSManagedObjectContext * objectContext;
@property (weak,   nonatomic) UINavigationController   *globalNavController;


- (id) initWithManagedContext:(NSManagedObjectContext *)thecontext;

// Tile View Icon delegate
- (NSArray *) KalTileDrawDelegate: (KalTileView *) sender getIconDrawInfoWithDate: (NSDate *) date;

- (void)updateSelectDay:(NSDate *)date;





@end
