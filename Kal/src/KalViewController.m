/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalViewController.h"
#import "KalLogic.h"
#import "KalDataSource.h"
#import "KalDate.h"
#import "KalPrivate.h"

#import <QuartzCore/QuartzCore.h>

#define PROFILER 0
#if PROFILER
#include <mach/mach_time.h>
#include <time.h>
#include <math.h>
void mach_absolute_difference(uint64_t end, uint64_t start, struct timespec *tp)
{
    uint64_t difference = end - start;
    static mach_timebase_info_data_t info = {0,0};

    if (info.denom == 0)
        mach_timebase_info(&info);
    
    uint64_t elapsednano = difference * (info.numer / info.denom);
    tp->tv_sec = elapsednano * 1e-9;
    tp->tv_nsec = elapsednano - (tp->tv_sec * 1e9);
}
#endif

NSString *const KalDataSourceChangedNotification = @"KalDataSourceChangedNotification";

@interface KalViewController ()
@property (nonatomic, strong, readwrite) NSDate *initialDate;
@property (nonatomic, strong, readwrite) NSDate *selectedDate;
- (KalView*)calendarView;
@end

@implementation KalViewController

@synthesize dataSource, delegate, vcdelegate, initialDate, selectedDate, tileDelegate;

- (id)initWithSelectedDate:(NSDate *)date
{
  if ((self = [super init])) {
    logic = [[KalLogic alloc] initForDate:date];
    self.initialDate = date;
    self.selectedDate = date;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeChangeOccurred) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:KalDataSourceChangedNotification object:nil];

  }
  return self;
}

- (id)init
{
  return [self initWithSelectedDate:[NSDate date]];
}

- (KalView*)calendarView { return (KalView*)self.view; }

- (void)setDataSource:(id<KalDataSource>)aDataSource
{
  if (dataSource != aDataSource) {
    dataSource = aDataSource;
    tableView.dataSource = dataSource;
  }
}

- (void)setDelegate:(id<UITableViewDelegate>)aDelegate
{
  if (delegate != aDelegate) {
    delegate = aDelegate;
    tableView.delegate = delegate;
  }
}

- (void)clearTable
{
  [dataSource removeAllItems];
  [tableView reloadData];
}

- (void)reloadData
{
  [dataSource presentingDatesFrom:logic.fromDate to:logic.toDate delegate:self];
}

- (void)significantTimeChangeOccurred
{
  [[self calendarView] jumpToSelectedMonth];
  [self reloadData];
}

+ (UIImage *) imageWithView:(UIView *)view
{
    // UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    // CGRect rectFullScreen = [keyWindow bounds];
    // FIXME: if use full screen capture, it was a black in bottom,
    // if use view boudns capture, it will be scaled...
    UIGraphicsBeginImageContextWithOptions(view.frame.size, view.opaque, 0.0);
    if(SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    } else {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (UIImage *)captureCalendarView
{
   return [KalViewController imageWithView:self.navigationController.view];
}

- (NSString *)selecedMonthNameAndYear
{
    return [logic selectedMonthNameAndYear];
}

// -----------------------------------------
#pragma mark KalViewDelegate protocol

- (void)didSelectDate:(KalDate *)date
{
  [self.vcdelegate KalViewController:self selectDate:[date NSDate]];  
  self.selectedDate = [date NSDate];
  NSDate *from = [[date NSDate] cc_dateByMovingToBeginningOfDay];
  NSDate *to = [[date NSDate] cc_dateByMovingToEndOfDay];
  [self clearTable];
  [dataSource updateSelectDay:[date NSDate]];
  [dataSource loadItemsFromDate:from toDate:to];
  [tableView reloadData];
  [tableView flashScrollIndicators];
}

- (void)showPreviousMonth
{
  [self clearTable];
  [logic retreatToPreviousMonth];
  [[self calendarView] slideDown];
  [self reloadData];
}

- (void)showFollowingMonth
{
  [self clearTable];
  [logic advanceToFollowingMonth];
  [[self calendarView] slideUp];
  [self reloadData];
}

- (void)didSelectTitle:(UIView *)header
{
    [self.vcdelegate KalViewControllerdidSelectTitle:self titleView:header];
}

- (NSArray *) KalTileDrawDelegate: (KalTileView *) sender getIconDrawInfoWithDate: (NSDate *) date
{
    return [self.tileDelegate KalTileDrawDelegate:sender getIconDrawInfoWithDate:date];
}
// -----------------------------------------
#pragma mark KalDataSourceCallbacks protocol

- (void)loadedDataSource:(id<KalDataSource>)theDataSource;
{
  NSArray *markedDates = [theDataSource markedDatesFrom:logic.fromDate to:logic.toDate];
  NSMutableArray *dates = [markedDates mutableCopy];
  for (int i=0; i<[dates count]; i++)
    [dates replaceObjectAtIndex:i withObject:[KalDate dateFromNSDate:[dates objectAtIndex:i]]];
  
  [[self calendarView] markTilesForDates:dates];
  [self didSelectDate:self.calendarView.selectedDate];
}

// ---------------------------------------
#pragma mark -

- (void)showAndSelectDate:(NSDate *)date
{
  if ([[self calendarView] isSliding])
    return;
  
  [logic moveToMonthForDate:date];
  
#if PROFILER
  uint64_t start, end;
  struct timespec tp;
  start = mach_absolute_time();
#endif
  
  [[self calendarView] jumpToSelectedMonth];
  
#if PROFILER
  end = mach_absolute_time();
  mach_absolute_difference(end, start, &tp);
  printf("[[self calendarView] jumpToSelectedMonth]: %.1f ms\n", tp.tv_nsec / 1e6);
#endif
  
    [[self calendarView] selectDate:[KalDate dateFromNSDate:date]];
  [self reloadData];
}

- (NSDate *)selectedDate:(NSDate *) date
{
  return date;
}

- (void)changeWeekStartType:(BOOL) isStartWithMon
{
#ifdef START_MONDAY_FIXED
  KalDate *savedDate = [[self calendarView] selectedDate];
    if ([logic isCalendarStartMondayMode] == isStartWithMon)
        return;
  [logic setCalendarStartMonday:isStartWithMon];
  // KalView's logic is inverted.

  [[self calendarView] refreshWeekdayLabel:!isStartWithMon];
    // FIXME: here because it's not able to directly refrash, so workaround it
    // by move to next month and move back, pretty silly.
    [self showFollowingMonth];
    [self showPreviousMonth];
    [[self calendarView] selectDate:savedDate];

  NSLog(@"KalViewController: Calendar redraw due to the week day start changed...");
    
#endif
}



// -----------------------------------------------------------------------------------
#pragma mark UIViewController

- (void)didReceiveMemoryWarning
{
  self.initialDate = self.selectedDate; // must be done before calling super
  [super didReceiveMemoryWarning];
}

- (void)loadView
{
  if (!self.title)
    self.title = @"Calendar";


    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

#if 0
  // Patch from https://github.com/klazuka/Kal/pull/62/files#diff-0
  // Add support for iPad.
  //  CGRect popoverRect = CGRectMake(0, 0, self.contentSizeForViewInPopover.width, self.contentSizeForViewInPopover.height);
  //  CGRect windowsRect = [[UIScreen mainScreen] applicationFrame];
  //  CGRect rect = CGRectMake(0, 0, MIN(popoverRect.size.width, windowsRect.size.width), MIN(popoverRect.size.height, windowsRect.size.height));
  //  KalView *kalView = [[KalView alloc] initWithFrame:rect delegate:self logic:logic];
#else
    KalView *kalView = [[KalView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] delegate:self logic:logic];
#endif
  
  self.view = kalView;
  tableView = kalView.tableView;
  tableView.dataSource = dataSource;
  tableView.delegate = delegate;
  [kalView selectDate:[KalDate dateFromNSDate:self.initialDate]];
  [self reloadData];
}


- (int) tableViewWhiteHeight
{
    return tableView.bounds.size.height - tableView.contentSize.height;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // This empty view will stop table 's empty line
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
    emptyView.backgroundColor = [UIColor clearColor];
    [tableView setTableFooterView:emptyView];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  tableView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [tableView flashScrollIndicators];
}

#pragma mark -

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:KalDataSourceChangedNotification object:nil];
}

@end
