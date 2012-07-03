//
//  SSShiftTypePickerTVC.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-5-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "config.h"
#import "OneJob.h"

@class SSShiftWorkdayConfigTVC;

@protocol SSShiftTypePickerDelegate 

- (void) SSItemPickerChoosewithController: (SSShiftWorkdayConfigTVC *) sender itemIndex: (NSInteger) index;

- (void) SSShiftTypePickerClientFinishConfigure: (id) sender;

@end

@interface SSShiftWorkdayConfigTVC : UITableViewController <SSShiftTypePickerDelegate>

@property (strong) NSArray *items;
@property (nonatomic, strong) OneJob *theJob;		   
@property (assign, nonatomic)     id<SSShiftTypePickerDelegate> __unsafe_unretained pickDelegate;



@end
