//
//  SSMailAgent.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Kal.h"
#import "SSShareProfileListViewController.h"

@class SSAppDelegate;

// This class is mainly do all emal pop up job, should also take care of
// Setting UI's email pop up, and image setup.
@interface SSMailAgent : NSObject <MFMailComposeViewControllerDelegate>
{
    UINavigationController *nvc;
}


- (void)composeMailWithKalViewController:(KalViewController *)kal 
                                 withNVC:(UINavigationController *)nvc
                       withSSAppDelegate: (SSAppDelegate *) ssDelegate;

@end
