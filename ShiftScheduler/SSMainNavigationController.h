//
//  mainNavigationController.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-11-9.
//
//

#import <UIKit/UIKit.h>
#import "REFrostedViewController.h"
#import "KalViewController.h"

@class SSMainMenuTableViewController;

@protocol SSMainMenuDelegate
- (void) SSMainMenuDelegatePopMainMenu: (id) from;
@end

@protocol SSMainMenuShareButtonDelegate
- (void) SSMainMenuShareButtonClicked: (id) from;
@end

@protocol SSMainMenuSwitchViewDelegate
- (void) SSMainMenuViewStartChange;
@end

@interface SSMainNavigationController : UINavigationController <SSMainMenuSwitchViewDelegate>

@property (strong, nonatomic) REFrostedViewController *frostedViewController;
@property (strong, nonatomic) KalViewController *kalViewController;
@property (strong, nonatomic) SSMainMenuTableViewController *menuTableView;


- (void) presentMenuView;

- (void)displayCoachMarks;

@end
