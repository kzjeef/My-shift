
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

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self.view setGestureRecognizers: @[[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)]]];
    
    [SSTrackUtil startLogPageViews:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void) viewDidAppear:(BOOL)animated
{
    // This will only show calendar view 's help, because only called once after app start.
    [self displayCoachMarks];
    

}

- (void)tryResetCoachState
{
    // Save the Last coach app version.
    // if app version is different, reset the coach setting.
    
    NSString *last_version = [[NSUserDefaults standardUserDefaults] objectForKey:USER_COACH_LAST_VERSION];
    if (last_version == nil || [last_version compare:[self version]] != NSOrderedSame) {
        [[NSUserDefaults standardUserDefaults] setObject:@[@NO, @NO] forKey:MAIN_VIEW_COACH_KEY];
    }
}

- (void)displayCoachMarks
{
    // TODO: fix the hard coded position and size, try find a better way like tag
    // finding to figure out where is the view is, but viewByTag seems not working
    NSArray *coachMarksCal = @[
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(5, 20, 40, 40)],
                              @"caption":NSLocalizedString(@"Click to open Menu", "click to open menu")
                              },
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(80, 65, 170, 35)],
                              @"caption": NSLocalizedString(@"Click to quick jump to some date", "click jump date")
                            },
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(260, 20, 60, 35)],
                              @"caption": NSLocalizedString(@"Click to jump back to today", "jump to today")
                            }
                            ];
    NSMutableArray *mcoachMarkCal = [coachMarksCal mutableCopy];
    
    UIImage *downImage = [UIImage imageNamed:@"blueArrowDown.png"];
    NSAssert(downImage != nil, @"image should be load fine.");
    
    UIImage *upImage = [UIImage imageNamed:@"blueArrowUp.png"];
    NSAssert(upImage != nil, @"image should be load fine");
    
    UIImage *rightImage = [UIImage imageNamed:@"blueArrowRight.png"];
    NSAssert(rightImage != nil, @"image should be load fine");
    
    [mcoachMarkCal addObjectsFromArray:@[
                                        @{@"rect" : [NSValue valueWithCGRect:CGRectMake(260, 130, 0, 0)],
                                          @"caption": NSLocalizedString(@"Pull Down to next month of calendar", "pull down to next month"),
                                          @"image": downImage},
                                        @{@"rect": [NSValue valueWithCGRect:CGRectMake(260, 130, 0, 0)],
                                          @"caption" : NSLocalizedString(@"Pull Up to previous month of calendar", "pull up help"),
                                          @"image" : upImage},
                                        @{@"rect" : [NSValue valueWithCGRect:CGRectMake(260, 130, 0, 0)],
                                          @"caption" : NSLocalizedString(@"Pull right to open main menu", "pull right help"),
                                          @"image" : rightImage}]
                                        ];
    
    coachMarksCal = mcoachMarkCal;

    NSArray *coachMarksList = @[
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(5, 20, 40, 40)],
                              @"caption":NSLocalizedString(@"Click to open Menu", "click to open menu")
                              },
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(5, 170, 320, 44)],
                              @"caption": NSLocalizedString(@"Click to create a new shift profile", "new shift profile")
                            },
                            @{@"rect": [NSValue valueWithCGRect:CGRectMake(275, 20, 40, 35)],
                              @"caption": NSLocalizedString(@"Click to organize shift profiles", "organize shift profiles")
                            }];

    //#define DEBUG_COACH_MARKS
#ifdef DEBUG_COACH_MARKS
    [[NSUserDefaults standardUserDefaults] setObject:@[@NO, @NO] forKey:MAIN_VIEW_COACH_KEY];
#endif
    
    [self tryResetCoachState];
    

    NSArray *history = [[NSUserDefaults standardUserDefaults] arrayForKey:MAIN_VIEW_COACH_KEY];

    if (self.menuTableView.currentSelectedView > 0  && self.menuTableView.currentSelectedView <= kMainViewShiftListView) {
        int i = self.menuTableView.currentSelectedView;
        NSNumber *t = [history objectAtIndex:i - 1];
        if (t.boolValue == NO) {
            NSArray *a;
            if (i == kMainViewCalendarView)
                a = coachMarksCal;
            else
                a = coachMarksList;

            coachMarkView  = [[WSCoachMarksView alloc] initWithFrame:[[[UIApplication sharedApplication] keyWindow] frame]
                                                                                    coachMarks:a];


            [coachMarkView setMaskColor:[[UIColor blackColor] colorWithAlphaComponent:0.88]];
            [self.view addSubview:coachMarkView];
            [coachMarkView start];
             NSMutableArray *m = [history mutableCopy];
            [m replaceObjectAtIndex:i - 1 withObject:@YES];
            [[NSUserDefaults standardUserDefaults] setObject:m forKey:MAIN_VIEW_COACH_KEY];
            
            // save current version.
            [[NSUserDefaults standardUserDefaults] setObject:[self version] forKey:USER_COACH_LAST_VERSION];
        }
    }
}

- (NSString*) version {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@ build %@", version, build];
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
