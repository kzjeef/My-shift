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

#define TN_LOGIN_FAILED -100
#define TN_SERVER_FAILED -200

@interface SSShareResult : NSObject


// result: 0, success, -1: failed, reason should in failedReason
@property int result;
@property (strong, nonatomic) NSString *failedReason;

@end



@interface SSShareController : NSObject

@property (weak, readonly) NSString *shiftOverviewStr;
@property (strong, nonatomic) NSString *shiftThinkNoteStr;
@property (weak, readonly) NSString *shiftDetailEmailStr;
@property (strong, nonatomic) UIImage *shiftCalImage;
@property (strong, nonatomic) NSString *shiftCalImageName;
@property (weak, readonly) UIImage *shiftListImage;
@property (weak, readonly) NSString *shiftListImageName;

- (id) initWithProfilesVC:(SSShareProfileListViewController *)profilelist
        withKalController:(KalViewController *)kal;
- (void) invaildCache;
@end
