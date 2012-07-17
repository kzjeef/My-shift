//
//  SSShareObject.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  KalViewController;
@class  SSAppDelegate;
@class  SSShareProfileListViewController;

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
