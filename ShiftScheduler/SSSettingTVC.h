//
//  SSSettingTVC.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SSSocialThinkNoteLogin.h"
#import "SSMainNavigationController.h"

@interface SSSettingTVC : UITableViewController
<NSURLConnectionDelegate, UIAlertViewDelegate>
{
    NSArray *sections;

    NSArray *appConfigArray;
    NSArray *appConfigHelpArray;
    NSArray *alarmSettingsArray;
    NSArray *feedbackItemsArray;

    NSArray *socialAccountArray;
    

    NSURL *iTunesURL;
    UIActionSheet *_resetAS;
    NSManagedObjectContext *_managedObjectContext;
    SSSocialThinkNoteLogin *_thinknoteLogin;
    
}


@property (weak, nonatomic, readonly) NSArray *alarmSettingsArray;
@property (weak, nonatomic, readonly) NSArray *appConfigArray;
@property (weak, nonatomic, readonly) NSArray *appConfigHelpArray;
@property (weak, nonatomic, readonly) NSArray *socialAccountArray;
@property (weak, nonatomic, readonly) NSArray *feedbackItemsArray;
@property (nonatomic, strong) NSURL *iTunesURL;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) id<SSMainMenuDelegate> menuDelegate;


@end
