/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalView.h"
#import "KalGridView.h"
#import "KalLogic.h"
#import "KalPrivate.h"



@interface KalView ()
- (void)addSubviewsToHeaderView:(UIView *)headerView;
- (void)addSubviewsToContentView:(UIView *)contentView;
- (void)setHeaderTitleText:(NSString *)text;
@end


static const CGFloat kHeaderHeight = 44.f;
static const CGFloat kMonthLabelHeight = 17.f;


@implementation KalView

@synthesize delegate, tableView;

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate logic:(KalLogic *)theLogic
{
  if ((self = [super initWithFrame:frame])) {


    delegate = theDelegate;
    logic = theLogic;
    [logic addObserver:self forKeyPath:@"selectedMonthNameAndYear" options:NSKeyValueObservingOptionNew context:NULL];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, kHeaderHeight)];
    headerView.backgroundColor = [UIColor colorWithWhite:.92f alpha:.9f];
    [self addSubviewsToHeaderView:headerView];
    [self addSubview:headerView];

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, kHeaderHeight, frame.size.width, frame.size.height - kHeaderHeight)];

    [self addSubviewsToContentView:contentView];
    [self addSubview:contentView];


  }
  return self;
}


- (id)initWithFrame:(CGRect)frame
{
  [NSException raise:@"Incomplete initializer" format:@"KalView must be initialized with a delegate and a KalLogic. Use the initWithFrame:delegate:logic: method."];
  return nil;
}

- (void)redrawEntireMonth { [self jumpToSelectedMonth]; }

- (void)slideDown { [gridView slideDown]; }
- (void)slideUp { [gridView slideUp]; }



- (void)showPreviousMonth
{
  if (!gridView.transitioning)
    [delegate showPreviousMonth];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    UIView *hitView  = [self hitTest:location withEvent:event];
    
    if (hitView == headerView) {
        [self.delegate didSelectTitle];
    }
}

- (void)showFollowingMonth
{
  if (!gridView.transitioning)
    [delegate showFollowingMonth];
}

- (void)addSubviewsToHeaderView:(UIView *)pheaderView
{

/*
  const CGFloat kChangeMonthButtonWidth = 46.0f;
  const CGFloat kChangeMonthButtonHeight = 30.0f;
 */
  const CGFloat kMonthLabelWidth = 200.0f;
  const CGFloat kHeaderVerticalAdjust = 3.f;
  
  // Header background gradient
  UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"]];
  CGRect imageFrame = pheaderView.frame;
  imageFrame.origin = CGPointZero;
  backgroundView.frame = imageFrame;

    //  [pheaderView addSubview:backgroundView];
  
  // Create the previous month button on the left side of the view
    /*
    CGRect previousMonthButtonFrame = CGRectMake(self.left,
                                               kHeaderVerticalAdjust,
                                               kChangeMonthButtonWidth,
                                               kChangeMonthButtonHeight);

    CGRect previousMonthButtonFrame = CGRectMake(0,
                                                 0,
                                                 kChangeMonthButtonWidth,
                                                 kChangeMonthButtonHeight);
*/
/*
  UIButton *previousMonthButton = [[UIButton alloc] initWithFrame:previousMonthButtonFrame];
  [previousMonthButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_left_arrow.png"] forState:UIControlStateNormal];
  previousMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  previousMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  [previousMonthButton addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
  [pheaderView addSubview:previousMonthButton];
*/
  // Draw the selected month name centered and at the top of the view
  CGRect monthLabelFrame = CGRectMake((self.width/2.0f) - (kMonthLabelWidth/2.0f),
                                      kHeaderVerticalAdjust,
                                      kMonthLabelWidth,
                                      kMonthLabelHeight);
    // Header and Title label.
  headerTitleLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
  headerTitleLabel.backgroundColor = [UIColor clearColor];
    //headerTitleLabel.font = [UIFont boldSystemFontOfSize:22.f];
    headerTitleLabel.font = [UIFont systemFontOfSize:22.f];
    headerTitleLabel.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_header_text_fill.png"]];
    //  headerTitleLabel.shadowColor = [UIColor whiteColor];
    //  headerTitleLabel.shadowOffset = CGSizeMake(0.f, 1.f);
    [self setHeaderTitleText:[logic selectedMonthNameAndYear]];
    
    [headerTitleLabel sizeToFit];

    [headerView addSubview:headerTitleLabel];
/*
  // Create the next month button on the right side of the view
  CGRect nextMonthButtonFrame = CGRectMake(self.width - kChangeMonthButtonWidth,
                                           kHeaderVerticalAdjust,
                                           kChangeMonthButtonWidth,
                                           kChangeMonthButtonHeight);
  UIButton *nextMonthButton = [[UIButton alloc] initWithFrame:nextMonthButtonFrame];
  [nextMonthButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_right_arrow.png"] forState:UIControlStateNormal];
  nextMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  nextMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  [nextMonthButton addTarget:self action:@selector(showFollowingMonth) forControlEvents:UIControlEventTouchUpInside];
  [headerView addSubview:nextMonthButton];
*/
  // if needs, change it later.
    [self refreshWeekdayLabel:YES];
}

-(void)refreshWeekdayLabel:(BOOL) sunDayStart
{
  if (weekdayLabels == nil)
    weekdayLabels = [[NSMutableArray alloc] initWithCapacity:7];

  // Remove all week day label.
  for (UILabel *l in weekdayLabels)
    [l removeFromSuperview];

  [weekdayLabels removeAllObjects];

  // Add column labels for each weekday (adjusting based on the current locale's first weekday)
  NSArray *weekdayNames = [[[NSDateFormatter alloc] init]
                            shortWeekdaySymbols];
  NSCalendar *cal = [NSCalendar currentCalendar];
    
#if MONDAY_START_FIXED
  if (sunDayStart)
    [cal setFirstWeekday:1];
  else
    [cal setFirstWeekday:2];
#endif
  NSUInteger firstWeekday = [cal firstWeekday];
  NSUInteger i = firstWeekday - 1;
  for (CGFloat xOffset = 0.f;
       xOffset < headerView.width;
       xOffset += 46.f, i = (i+1)%7) {
    CGRect weekdayFrame = CGRectMake(xOffset, 30.f, 46.f, kHeaderHeight - 29.f);
    UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
    weekdayLabel.backgroundColor = [UIColor clearColor];
    weekdayLabel.font = [UIFont boldSystemFontOfSize:10.f];
    weekdayLabel.textColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.f];
    weekdayLabel.shadowColor = [UIColor whiteColor];
    weekdayLabel.shadowOffset = CGSizeMake(0.f, 1.f);
    weekdayLabel.text = [weekdayNames objectAtIndex:i];
    [headerView addSubview:weekdayLabel];
    [weekdayLabels addObject:weekdayLabel];
  }
}

- (void)addSubviewsToContentView:(UIView *)contentView
{
  // Both the tile grid and the list of events will automatically lay themselves
  // out to fit the # of weeks in the currently displayed month.
  // So the only part of the frame that we need to specify is the width.
  CGRect fullWidthAutomaticLayoutFrame = CGRectMake(0.f, 0.f, self.width, 0.f);

  // The tile grid (the calendar body)
  gridView = [[KalGridView alloc] initWithFrame:fullWidthAutomaticLayoutFrame logic:logic delegate:delegate];
  [gridView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
  [contentView addSubview:gridView];

  // The list of events for the selected day
  tableView = [[UITableView alloc] initWithFrame:fullWidthAutomaticLayoutFrame style:UITableViewStylePlain];
  tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [contentView addSubview:tableView];
  
  // Drop shadow below tile grid and over the list of events for the selected day

#if 0
  shadowView = [[UIImageView alloc] initWithFrame:fullWidthAutomaticLayoutFrame];
  shadowView.image = [UIImage imageNamed:@"Kal.bundle/kal_grid_shadow.png"];
  shadowView.height = shadowView.image.size.height;
  [contentView addSubview:shadowView];
#endif
  // Trigger the initial KVO update to finish the contentView layout
  [gridView sizeToFit];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (object == gridView && [keyPath isEqualToString:@"frame"]) {
    
    /* Animate tableView filling the remaining space after the
     * gridView expanded or contracted to fit the # of weeks
     * for the month that is being displayed.
     *
     * This observer method will be called when gridView's height
     * changes, which we know to occur inside a Core Animation
     * transaction. Hence, when I set the "frame" property on
     * tableView here, I do not need to wrap it in a
     * [UIView beginAnimations:context:].
     */
    CGFloat gridBottom = gridView.top + gridView.height;
    CGRect frame = tableView.frame;
    frame.origin.y = gridBottom;
    frame.size.height = tableView.superview.height - gridBottom;
    tableView.frame = frame;
    shadowView.top = gridBottom;
    
  } else if ([keyPath isEqualToString:@"selectedMonthNameAndYear"]) {
    [self setHeaderTitleText:[change objectForKey:NSKeyValueChangeNewKey]];
    
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setHeaderTitleText:(NSString *)text
{
    //    NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
    
    //headerTitleLabel.attributedText  = [[NSAttributedString alloc] initWithString:text
    // attributes:nil];
    headerTitleLabel.text = text;
    
  [headerTitleLabel sizeToFit];
  headerTitleLabel.left = floorf(self.width/2.f - headerTitleLabel.width/2.f);
}

- (void)jumpToSelectedMonth { [gridView jumpToSelectedMonth]; }

- (void)selectDate:(KalDate *)date { [gridView selectDate:date]; }

- (BOOL)isSliding { return gridView.transitioning; }

- (void)markTilesForDates:(NSArray *)dates { [gridView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return gridView.selectedDate; }

- (void)dealloc
{
  [logic removeObserver:self forKeyPath:@"selectedMonthNameAndYear"];
  
  [gridView removeObserver:self forKeyPath:@"frame"];
}

@end
