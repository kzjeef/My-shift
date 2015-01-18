//
//  SSProfileTimeAndAlarmVC.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OneJob.h"
#import "SCModalPickerView.h"
#import "I18NStrings.h"

@class SCModalPickerView;

@interface SSProfileTimeAndAlarmVC : UITableViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSArray *itemsArray;
    OneJob *theJob;
    IBOutlet UIDatePicker *datePicker;
    IBOutlet UIPickerView *picker;
    NSDateFormatter *dateFormatter;
    NSIndexPath *firstChooseIndexPath; // the indexPath use choose when enter this UI.
    int lastChooseCell;
    NSArray *remindItemsArray;
    //    SCModalPickerView *modalPickerView;
}

@property (weak, nonatomic, readonly) NSArray *itemsArray;
@property (weak, nonatomic, readonly) NSArray *remindItemsArray;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) OneJob *theJob;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSIndexPath *firstChooseIndexPath;


+ (void) configureTimeCell: (UITableViewCell *)cell indexPath: (NSIndexPath *)indexPath Job: (OneJob *)theJob;

+ (BOOL) isItemInThisViewController: (NSString *) item;
+ (NSTimeInterval) convertRemindItemToTimeInterval:(int) item;
+ (NSString *) convertTimeIntervalToString: (NSNumber *) time;
+ (int) convertTimeIntervalToRemindItem: (NSTimeInterval) time;

@end
