//
//  CalendarSyncTVC.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-2-20.
//
//

#import <UIKit/UIKit.h>
#import "SSMainMenuTableViewController.h"
#import "SSMainNavigationController.h"
#import "SSSingleSelectTVC.h"
#import "SSShiftMultipSelectTVC.h"

@class SSCalendarSyncController;

@interface CalendarSyncTVC : UITableViewController <SSSingleSelectTVCDelegate, SSShiftMultipleSelectDelegate>

@property (nonatomic, strong) SSCalendarSyncController *calendarSyncController;
@property (weak, nonatomic) id<SSMainMenuDelegate> menuDelegate;

@end
