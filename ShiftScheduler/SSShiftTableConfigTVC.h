//
//  FreeJumpProfileConfigTVC.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OneJob.h"
#import "SSShiftWorkdayConfigTVC.h"


@interface SSShiftTableConfigTVC : UITableViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) OneJob *theJob;
@property (assign, nonatomic) id<SSShiftTypePickerDelegate> __unsafe_unretained pickDelegate;
@end
