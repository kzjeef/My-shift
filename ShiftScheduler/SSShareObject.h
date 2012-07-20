//
//  SSShareObject.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KalViewController;
@class SSAppDelegate;
@class SSShareProfileListViewController;
@class SSShareResult;


typedef void (^ComposeShareViewCompleteHander)(SSShareResult *result);

@interface SSShareResult : NSObject


// result: 0, success, -1: failed, reason should in failedReason
@property int result;
@property (strong, nonatomic) NSString *failedReason;

@end

@interface SSShareController : NSObject

@property (readonly) NSString *shiftOverviewStr;
@property (readonly) NSString *shiftDetailEmailStr;
@property (readonly) UIImage *shiftCalImage;
@property (readonly) NSString *shiftCalImageName;
@property (readonly) UIImage *shiftListImage;
@property (readonly) NSString *shiftListImageName;

- (id) initWithProfilesVC:(SSShareProfileListViewController *)profilelist
        withKalController:(KalViewController *)kal;
@end
