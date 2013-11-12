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

@interface SSMainNavigationController : UINavigationController

@property (strong, nonatomic) REFrostedViewController *frostedViewController;
@property (strong, nonatomic) KalViewController *kalViewController;

@end
