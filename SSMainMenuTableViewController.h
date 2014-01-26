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

@interface SSMainMenuTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) KalViewController *kalController;
@property (nonatomic, strong) SSSettingTVC      *settingTVC;
@property (nonatomic, strong) ShiftListProfilesTVC *shiftListTVC;
@property (strong, nonatomic) REFrostedViewController *frostedViewController;

@property (strong, nonatomic) NSArray *menuItemNameList; // a list of string of the menu items.

@property (strong, nonatomic) NSArray *menuItemIconPathList; // a list of path of menu item list, if no, pass "" to it.

- (id) initWithStyle:(UITableViewStyle)style nameArray: (NSArray *) nameArray iconArray: (NSArray *)iconArray;
@end
