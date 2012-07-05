//
//  WorkDateGenerator.h
//  Holiday
//
//  Created by Zhang Jiejing on 11-10-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// Full time work day
#define WORKDAY_TYPE_FULL   0  
// half work day
#define WORKDAY_TYPE_HALF   1
// full time rest day
#define WORKDAY_TYPE_NOT    2

// nsdate + work day type class
@interface WorkDate : NSDate {
@public
    int workdayType;
}
@end

@interface WorkDateGenerator : NSObject
{
    NSArray *workdays;
  
}

// init the work date generator with these input.
- (id) initWithWorkConfigWithStartDate: (NSDate *) startDate
                     workdayLengthWith: (int) workdaylength
                     restdayLengthWith: (int) restdayLength
                         lengthOfArray: (int) lengthOfArray;

// return a array with nsdata object between a range of date
- (NSArray *) returnWorkdaysWithInStartDate:(NSDate *) startDate endDate: (NSDate *) endDate;


@end
