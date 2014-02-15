//
//  MainMenuTableViewController.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-11-9.
//
//

#import <UIKit/UIKit.h>
#import "KalViewController.h"
#import "SSSettingTVC.h"
#import "ShiftListProfilesTVC.h"
#import "REFrostedViewController.h"
#import "UIImageResizing.h"
#import "SSMainMenuTableViewController.h"

#define     MainViewCalendarView  1
#define     MainViewShiftListView 2
#define     MainViewSettingView  3

@interface SSMainMenuTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) KalViewController *kalController;
@property (nonatomic, strong) SSSettingTVC      *settingTVC;
@property (nonatomic, strong) ShiftListProfilesTVC *shiftListTVC;
@property (strong, nonatomic) REFrostedViewController *frostedViewController;

@property (strong, nonatomic) NSArray *menuItemNameList; // a list of string of the menu items.

@property (strong, nonatomic) NSArray *menuItemIconPathList; // a list of path of menu item list, if no, pass "" to it.

@property (weak, nonatomic) id<SSMainMenuDelegate> menuDelegate;
@property (weak, nonatomic) id<SSMainMenuShareButtonDelegate> shareDelegate;
@property (readonly, nonatomic) int currentSelectedView;
@property (weak, nonatomic)  id<SSMainMenuSwitchViewDelegate> switchDelegate;


- (id) initWithStyle:(UITableViewStyle)style nameArray: (NSArray *) nameArray iconArray: (NSArray *)iconArray;

@end
