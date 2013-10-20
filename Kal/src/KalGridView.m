/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>

#import "KalGridView.h"
#import "KalView.h"
#import "KalMonthView.h"
#import "KalTileView.h"
#import "KalLogic.h"
#import "KalDate.h"
#import "KalPrivate.h"

#define SLIDE_NONE 0
#define SLIDE_UP 1
#define SLIDE_DOWN 2

const CGSize kTileSize = { 46.f, 44.f };
CGFloat const gestureMinimumTranslation = 13.0;
typedef enum : NSInteger {
    kKalViewMoveDirectionNone,
    kKalViewMoveDirectionUp,
    kKalViewMoveDirectionDown,
} CameraMoveDirection;


static NSString *kSlideAnimationId = @"KalSwitchMonths";

@interface KalGridView ()
{
    int swip_direction;
}
@property (nonatomic, strong) KalTileView *selectedTile;
@property (nonatomic, strong) KalTileView *highlightedTile;
- (void)swapMonthViews;
@end

@implementation KalGridView

@synthesize selectedTile, highlightedTile, transitioning;

- (id)initWithFrame:(CGRect)frame logic:(KalLogic *)theLogic delegate:(id<KalViewDelegate>)theDelegate
{
  // MobileCal uses 46px wide tiles, with a 2px inner stroke 
  // along the top and right edges. Since there are 7 columns,
  // the width needs to be 46*7 (322px). But the iPhone's screen
  // is only 320px wide, so we need to make the
  // frame extend just beyond the right edge of the screen
  // to accomodate all 7 columns. The 7th day's 2px inner stroke
  // will be clipped off the screen, but that's fine because
  // MobileCal does the same thing.
  frame.size.width = 7 * kTileSize.width;
  
  if (self = [super initWithFrame:frame]) {
    self.clipsToBounds = YES;
    logic = theLogic;
    delegate = theDelegate;
    
    CGRect monthRect = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
    frontMonthView = [[KalMonthView alloc] initWithFrame:monthRect delegate:theDelegate];
    backMonthView = [[KalMonthView alloc] initWithFrame:monthRect delegate:theDelegate];
    backMonthView.hidden = YES;
    [self addSubview:backMonthView];
    [self addSubview:frontMonthView];

    [self jumpToSelectedMonth];
    [self setGestureRecognizers: @[[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)]]];
  }
  return self;
}



- (void)drawRect:(CGRect)rect
{
  [[UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"] drawInRect:rect];
  [[UIColor colorWithRed:0.63f green:0.65f blue:0.68f alpha:1.f] setFill];
  CGRect line;
  line.origin = CGPointMake(0.f, self.height - 1.f);
  line.size = CGSizeMake(self.width, 1.f);
  CGContextFillRect(UIGraphicsGetCurrentContext(), line);
}

- (void)sizeToFit
{
  self.height = frontMonthView.height;
}

#pragma mark -
#pragma mark Gesture



- (void)handleSwipe:(UIPanGestureRecognizer *)gesture
{
    CGPoint translation = [gesture translationInView:self];

    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        swip_direction = kKalViewMoveDirectionNone;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged && swip_direction == kKalViewMoveDirectionNone)
    {
        swip_direction = [self determineCameraDirectionIfNeeded:translation];

        // ok, now initiate movement in the direction indicated by the user's gesture

        switch (swip_direction) {
            case kKalViewMoveDirectionDown:
                [delegate showPreviousMonth];
                NSLog(@"Start moving down");
                break;

            case kKalViewMoveDirectionUp:
                [delegate showFollowingMonth];
                NSLog(@"Start moving up");
                break;

            // case kKalViewMoveDirectionRight:
            //     break;

            // case kKalViewMoveDirectionLeft:

                // NSLog(@"Start moving left");
                break;

            default:
                break;
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        // now tell the camera to stop
        NSLog(@"Stop");
    }
}

// This method will determine whether the direction of the user's swipe

- (CameraMoveDirection)determineCameraDirectionIfNeeded:(CGPoint)translation
{
    if (swip_direction != kKalViewMoveDirectionNone)
        return swip_direction;

    // determine if horizontal swipe only if you meet some minimum velocity

    if (fabs(translation.x) > gestureMinimumTranslation)
    {
        BOOL gestureHorizontal = NO;

        if (translation.y == 0.0)
            gestureHorizontal = YES;
        else
            gestureHorizontal = (fabs(translation.x / translation.y) > 5.0);

        if (gestureHorizontal)
        {
            // if (translation.x > 0.0)
            //     return kKalViewMoveDirectionRight;
            // else
            //     return kKalViewMoveDirectionLeft;
        }
    }
    // determine if vertical swipe only if you meet some minimum velocity

    else if (fabs(translation.y) > gestureMinimumTranslation)
    {
        BOOL gestureVertical = NO;

        if (translation.x == 0.0)
            gestureVertical = YES;
        else
            gestureVertical = (fabs(translation.y / translation.x) > 5.0);

        if (gestureVertical)
        {
            if (translation.y > 0.0)
                return kKalViewMoveDirectionDown;
            else
                return kKalViewMoveDirectionUp;
        }
    }

    return swip_direction;
}


#pragma mark -
#pragma mark Touches

- (void)setHighlightedTile:(KalTileView *)tile
{
  if (highlightedTile != tile) {
    highlightedTile.highlighted = NO;
    highlightedTile = tile;
    tile.highlighted = YES;
    [tile setNeedsDisplay];
  }
}

- (void)setSelectedTile:(KalTileView *)tile
{
  if (selectedTile != tile) {
    selectedTile.selected = NO;
    selectedTile = tile;
    tile.selected = YES;
    [delegate didSelectDate:tile.date];
  }
}

- (void)receivedTouches:(NSSet *)touches withEvent:event
{
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self];
  UIView *hitView = [self hitTest:location withEvent:event];
  
  if (!hitView)
    return;

  if (swip_direction != kKalViewMoveDirectionNone)
      return;
  
  if ([hitView isKindOfClass:[KalTileView class]]) {
    KalTileView *tile = (KalTileView*)hitView;
    if (tile.belongsToAdjacentMonth) {
      self.highlightedTile = tile;
    } else {
      self.highlightedTile = nil;
      self.selectedTile = tile;
    }
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self receivedTouches:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self receivedTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self];
  UIView *hitView = [self hitTest:location withEvent:event];

  
  if ([hitView isKindOfClass:[KalTileView class]]) {
    KalTileView *tile = (KalTileView*)hitView;
    if (tile.belongsToAdjacentMonth) {
      if ([tile.date compare:[KalDate dateFromNSDate:logic.baseDate]] == NSOrderedDescending) {
        [delegate showFollowingMonth];
      } else {
        [delegate showPreviousMonth];
      }
      self.selectedTile = [frontMonthView tileForDate:tile.date];
    } else {
      self.selectedTile = tile;
    }
  }
  self.highlightedTile = nil;
}

#pragma mark -
#pragma mark Slide Animation

- (void)swapMonthsAndSlide:(int)direction keepOneRow:(BOOL)keepOneRow
{
  backMonthView.hidden = NO;
  
  // set initial positions before the slide
  if (direction == SLIDE_UP) {
    backMonthView.top = keepOneRow
      ? frontMonthView.bottom - kTileSize.height
      : frontMonthView.bottom;
  } else if (direction == SLIDE_DOWN) {
    NSUInteger numWeeksToKeep = keepOneRow ? 1 : 0;
    NSInteger numWeeksToSlide = [backMonthView numWeeks] - numWeeksToKeep;
    backMonthView.top = -numWeeksToSlide * kTileSize.height;
  } else {
    backMonthView.top = 0.f;
  }

  // trigger the slide animation
  [UIView beginAnimations:kSlideAnimationId context:NULL]; {
    [UIView setAnimationsEnabled:direction!=SLIDE_NONE];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    
    frontMonthView.top = -backMonthView.top;
    backMonthView.top = 0.f;

    frontMonthView.alpha = 0.f;
    backMonthView.alpha = 1.f;
    
    self.height = backMonthView.height;
    
    [self swapMonthViews];
  } [UIView commitAnimations];
 [UIView setAnimationsEnabled:YES];
}

- (void)slide:(int)direction
{
  transitioning = YES;
  
  [backMonthView showDates:logic.daysInSelectedMonth
      leadingAdjacentDates:logic.daysInFinalWeekOfPreviousMonth
     trailingAdjacentDates:logic.daysInFirstWeekOfFollowingMonth];
  
  // At this point, the calendar logic has already been advanced or retreated to the
  // following/previous month, so in order to determine whether there are 
  // any cells to keep, we need to check for a partial week in the month
  // that is sliding offscreen.
  
  BOOL keepOneRow = (direction == SLIDE_UP && [logic.daysInFinalWeekOfPreviousMonth count] > 0)
                 || (direction == SLIDE_DOWN && [logic.daysInFirstWeekOfFollowingMonth count] > 0);
  
  [self swapMonthsAndSlide:direction keepOneRow:keepOneRow];
  
  self.selectedTile = [frontMonthView firstTileOfMonth];
}

- (void)slideUp { [self slide:SLIDE_UP]; }
- (void)slideDown { [self slide:SLIDE_DOWN]; }

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
  transitioning = NO;
  backMonthView.hidden = YES;
}

#pragma mark -

- (void)selectDate:(KalDate *)date
{
  self.selectedTile = [frontMonthView tileForDate:date];
}

- (void)swapMonthViews
{
  KalMonthView *tmp = backMonthView;
  backMonthView = frontMonthView;
  frontMonthView = tmp;
  [self exchangeSubviewAtIndex:[self.subviews indexOfObject:frontMonthView] withSubviewAtIndex:[self.subviews indexOfObject:backMonthView]];
}

- (void)jumpToSelectedMonth
{
  [self slide:SLIDE_NONE];
}

- (void)markTilesForDates:(NSArray *)dates { [frontMonthView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return selectedTile.date; }

#pragma mark -


@end
