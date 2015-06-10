//
//  TodayViewController.m
//  todayshift
//
//  Created by Jiejing Zhang on 15/6/7.
//
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "OneJob.h"
#import "SSCoreDataHelper.h"
#import "I18NStrings.h"
#import "CommonDefine.h"
#import "MeasureUtil.h"

NSString *kJobEnabledCacheName  = @"JobEnabledCache";

@interface TodayViewController () <NCWidgetProviding, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>
{
     NSPersistentStoreCoordinator       *_psc;
     NSManagedObjectModel               *_model;
     UITableView                        *_tableView;
     NSDateFormatter                    *_timeFormatter;
     NSArray                            *_theJobNameArray;
     NSMutableArray                     *_shiftArray;
     NSManagedObjectContext             * _objectContext;
     NSFetchedResultsController         * _jobFetchRequestController;
    NSUserDefaults                      *_sharedDefaults;
}

@property (strong, nonatomic) NSManagedObjectContext        *objectContext;
@property (strong, nonatomic) NSFetchedResultsController    *jobFetchRequestController;
@property (strong, nonatomic) NSPersistentStoreCoordinator  *psc;
@property (strong, nonatomic) NSManagedObjectModel          *model;
@property (strong, nonatomic) NSDateFormatter               *timeFormatter;
@property (strong, nonatomic) NSArray                       *theJobNameArray;
@property (strong, nonatomic) NSMutableArray                *shiftArray;
@property (strong, nonatomic) NSUserDefaults                *sharedDefaults;

@end

@implementation TodayViewController

- (NSUserDefaults *) sharedDefaults
{
    
    if (_sharedDefaults != nil)
        return _sharedDefaults;
    _sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupName];
    return _sharedDefaults;
}

- (long)getEstimatedHeight {
    long size = (self.shiftArray.count * 44);
    if (size == 0)
        size = 44;
    return size;
}

- (NSDateFormatter *) timeFormatter
{
    if (_timeFormatter == nil) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        _timeFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return _timeFormatter;
}

NSString *kKeySSTodayLastDbOpTimeIntevalSince1970 = @"kKey_SSToday_Last_Db_Op_Time_Inteval_Since_1970";

- (NSDate *) lastDBReadTime {
    NSTimeInterval itval;
    itval = [self.sharedDefaults doubleForKey:kKeySSTodayLastDbOpTimeIntevalSince1970];
    if (itval == 0.0f)
        return nil;
    
    return [NSDate dateWithTimeIntervalSince1970:itval];
}

- (void) updateLastDbReadTime
{
    [self.sharedDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kKeySSTodayLastDbOpTimeIntevalSince1970];
    [self.sharedDefaults synchronize];
}

- (void) saveJobInCache
{
//    [self.sharedDefaults set]
}

- (void) loadDateWithCache {
    
    NSDate *lastReadTime = [self lastDBReadTime];
    NSDate *updatedate = [OneJob lastUpdateTimeForAllObjects:self.sharedDefaults];
    
    [self loadDataWithContext:self.objectContext];
    [self updateLastDbReadTime];
    NSLog(@"load date from DB: last read time:%@, db update time:%@",
          [self.timeFormatter stringFromDate:lastReadTime],
          [self.timeFormatter stringFromDate:updatedate]);
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _shiftArray = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    // Do any additional setup after loading the view from its nib.
    
    LOO_MEASURE_TIME(@"TodayView: LoadData") {
        [self loadDateWithCache];
    }
    
    LOO_MEASURE_TIME(@"TodayView: Setup View") {
        long size;
        size = [self getEstimatedHeight];
        // for no shift today.
        self.preferredContentSize = CGSizeMake(0, size);
        
        CGRect rect = CGRectMake(0, 0, 320, size);
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        tableView.delegate = self;
        tableView.dataSource = self;
        [self.view addSubview:tableView];
        [tableView reloadData];
        _tableView = tableView;
    }
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
     completionHandler(NCUpdateResultNewData);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.shiftArray.count > 0 ? self.shiftArray.count : 1 ;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"TodayWorkdayNormalCell";

    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    if (self.shiftArray.count > 0) {
        OneJob *job = [self.shiftArray objectAtIndex:indexPath.row];
        cell.textLabel.text = job.jobName;
        if ([job getJobEverydayStartTime] != Nil)
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                                  [job jobEverydayStartTimeWithFormatter:self.timeFormatter],
                                                  [job jobEverydayOffTimeWithFormatter:self.timeFormatter]];
        
    } else {
        cell.textLabel.text = TODAY_VIEW_NO_SHIFT;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.text = nil;

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *pjURL = [NSURL URLWithString:@"shiftscheduler://today"];
    [self.extensionContext openURL:pjURL completionHandler:^(BOOL success) {
        [[tableView cellForRowAtIndexPath:indexPath] setSelected:false];
    }];

}



- (void) loadDataWithContext:(NSManagedObjectContext *)thecontext
{
    NSError *error = 0;
    
    [self.jobFetchRequestController performFetch:&error];
    if (error)
        NSLog(@"fetch request error:%@", error.userInfo);
    
    self.theJobNameArray = self.jobFetchRequestController.fetchedObjects;

    self.jobFetchRequestController.delegate = self;
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self
            selector:@selector(managedContextDataChanged:)
                name:NSManagedObjectContextDidSaveNotification
              object:self.objectContext];

    [self loadItemsForData:[NSDate date] toArray:_shiftArray];
}

- (void) loadItemsForData:(NSDate *)date toArray:(NSMutableArray *)array
{
    for (OneJob *job in self.theJobNameArray) {
        if ([job isDayWorkingDay:date]) {
            [array addObject:job];
        }
    }
}


- (NSManagedObjectModel *) model {
    if (_model != nil)
        return _model;
    
    _model = [SSCoreDataHelper createShiftModel];
    return _model;
}

- (NSPersistentStoreCoordinator *) psc {
    
    if (_psc != nil)
        return _psc;
    
    _psc = [SSCoreDataHelper createPersistentStoreCoordinator:self.model];
    return _psc;
}

- (NSManagedObjectContext *) objectContext
{

    if (_objectContext != nil)
        return _objectContext;

    _objectContext = [SSCoreDataHelper createContext:self.psc];
    return _objectContext;
}

- (void) managedContextDataChanged:(NSNotification *) saveNotifaction
{
    [self.jobFetchRequestController performFetch:nil];
    self.theJobNameArray = nil;
}

- (NSFetchedResultsController *) jobFetchRequestController
{
    if (_jobFetchRequestController != nil) {
        return _jobFetchRequestController;
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
                                       cacheName:kJobEnabledCacheName];
    _jobFetchRequestController = frc;
    return frc;
}



@end
