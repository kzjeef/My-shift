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


@interface SSMainMenuTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) KalViewController *kalController;
@property (nonatomic, strong) SSSettingTVC      *settingTVC;
@property (nonatomic, strong) ShiftListProfilesTVC *shiftListTVC;
@property (strong, nonatomic) REFrostedViewController *frostedViewController;

@end
