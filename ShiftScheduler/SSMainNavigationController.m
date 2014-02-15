
//  mainNavigationController.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-11-9.
//
//

#import "SSMainNavigationController.h"
#import "UIImageResizing.h"
#import "config.h"
#import "WSCoachMarksView.h"
#import "SSDefaultConfigName.h"
#import "SSMainMenuTableViewController.h"


CGFloat const gestureMinimumTranslation = 13.0;
typedef enum : NSInteger {
    kSSGestureDirectionNone,
    kSSGestureDirectionUp,
    kSSGestureDirectionDown,
    kSSGestureDirectionRight,
    kSSGestureDirectionLeft,
} SSGestureDirection;

@interface SSMainNavigationController ()
{
    int _swipDirection;
    WSCoachMarksView *coachMarkView;
}


@end

@implementation SSMainNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.view setGestureRecognizers: @[[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)]]];



}

- (void) viewDidAppear:(BOOL)animated
{
    // This will only show calendar view 's help, because only called once after app start.
    [self displayCoachMarks];
}

- (void)displayCoachMarks
{
    // TODO: fix the hard coded position and size, try find a better way like tag
    // finding to figure out where is the view is, but viewByTag seems not working
    NSArray *coachMarksCal = @[
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(5, 20, 40, 40)],
                              @"caption":@"Click to open Menu"
                              },
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(80, 65, 170, 35)],
                              @"caption": @"Click to quick jump to some date"},
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(260, 20, 60, 35)],
                              @"caption": @"Click to jump back to today"},
                            ];
    NSArray *coachMarksList = @[
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(5, 20, 40, 40)],
                              @"caption":@"Click to open Menu"
                              },
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(5, 170, 320, 44)],
                              @"caption": @"Click to create a new shift profile"},
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(275, 20, 40, 35)],
                              @"caption": @"Click to organize shift profiles"}];

//#define DEBUG_COACH_MARKS
#ifdef DEBUG_COACH_MARKS
    [[NSUserDefaults standardUserDefaults] setObject:@[@NO, @NO] forKey:MAIN_VIEW_COACH_KEY];
#endif

    NSArray *history = [[NSUserDefaults standardUserDefaults] arrayForKey:MAIN_VIEW_COACH_KEY];

    if (self.menuTableView.currentSelectedView > 0  && self.menuTableView.currentSelectedView <= MainViewShiftListView) {
        int i = self.menuTableView.currentSelectedView;
        NSNumber *t = [history objectAtIndex:i - 1];
        if (t.boolValue == NO) {
            NSArray *a;
            if (i == MainViewCalendarView)
                a = coachMarksCal;
            else
                a = coachMarksList;

            coachMarkView  = [[WSCoachMarksView alloc] initWithFrame:[[[UIApplication sharedApplication] keyWindow] frame]
                                                                                    coachMarks:a];


            [coachMarkView setMaskColor:[[UIColor blackColor] colorWithAlphaComponent:0.77]];
            [self.view addSubview:coachMarkView];
            [coachMarkView start];
             NSMutableArray *m = [history mutableCopy];
            [m replaceObjectAtIndex:i - 1 withObject:@YES];
            [[NSUserDefaults standardUserDefaults] setObject:m forKey:MAIN_VIEW_COACH_KEY];
        }
    }
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)gesture
{
    CGPoint translation = [gesture translationInView:self.view];
    _swipDirection = [self determineCameraDirectionIfNeeded:translation];

    if (gesture.state == UIGestureRecognizerStateBegan)
        _swipDirection = kSSGestureDirectionNone;
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        if (_swipDirection == kSSGestureDirectionNone)
            return;
        switch (_swipDirection) {

            case kSSGestureDirectionRight:
                [self.frostedViewController presentMenuViewController];
                break;
            case kSSGestureDirectionLeft:
                break;
            default:
                break;
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        switch (_swipDirection) {
            case kSSGestureDirectionDown:
                [self.kalViewController showPreviousMonth];
                NSLog(@"Start moving down");
                break;

            case kSSGestureDirectionUp:
                [self.kalViewController showFollowingMonth];
                NSLog(@"Start moving up");
                break;

            default:
                break;
        }
    }
        return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) presentMenuView {
    [self.frostedViewController presentMenuViewController];
}


// This method will determine whether the direction of the user's swipe

- (SSGestureDirection)determineCameraDirectionIfNeeded:(CGPoint)translation
{
    if (_swipDirection != kSSGestureDirectionNone)
        return _swipDirection;

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
            if (translation.x > 0.0)
                return kSSGestureDirectionRight;
            else
                return kSSGestureDirectionLeft;
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
                return kSSGestureDirectionDown;
            else
                return kSSGestureDirectionUp;
        }
    }

    return _swipDirection;
}

- (void) SSMainMenuViewStartChange
{
    [self displayCoachMarks];
}

@end
