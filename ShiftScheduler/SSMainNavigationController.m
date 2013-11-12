//
//  mainNavigationController.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-11-9.
//
//

#import "SSMainNavigationController.h"
#import "UIImageResizing.h"
#import "config.h"

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
@end
