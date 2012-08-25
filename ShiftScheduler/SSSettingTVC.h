//
//  SSSettingTVC.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SSSocialThinkNoteLogin.h"


@interface SSSettingTVC : UITableViewController
<NSURLConnectionDelegate, UIAlertViewDelegate>
{
    NSArray *feedbackItemsArray;
    NSURL *iTunesURL;
    NSArray *alarmSettingsArray;
    NSArray *socialAccountArray;
    
    SSSocialThinkNoteLogin *_thinknoteLogin;
    
}


@property (nonatomic, readonly) NSArray *feedbackItemsArray;
@property (nonatomic, readonly) NSArray *alarmSettingsArray;
@property (nonatomic, readonly) NSArray *socialAccountArray;
@property (nonatomic, strong) NSURL *iTunesURL;


@end
