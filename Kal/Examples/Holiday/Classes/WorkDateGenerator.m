//
//  WorkDateGenerator.m
//  Holiday
//
//  Created by Zhang Jiejing on 11-10-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "WorkDateGenerator.h"

@interface WorkDateGenerator() 
@property (retain, nonatomic)     NSArray *workdays;
@end




@implementation WorkDateGenerator

- (NSArray *)workdays
{
    if (!workdays)
        workdays = [NSArray array];
    return workdays;
}



// ideas1 ， 只储存所有工作的日期， 在这个workdays的数组里。
//            问题： 但是问题是， 这样做了以后无法调整， 要调班的时候无法做了。
// idea2, 储存所有的日期， 一年也就365个嘛， 一百年也没多少个。 所以放的下。 
//          这样就需要把nsdate做继承。 继承或者不继承。。 继承了不用改现有代码。
// 先选择2把。
- (id) initWithWorkConfigWithStartDate: (NSDate *) startDate
                     workdayLengthWith: (int) workdaylength
                     restdayLengthWith: (int) restdayLength
                         lengthOfArray: (int) lengthOfArray
{
    NSMutableArray *days = [self.workdays mutableCopy];
    NSDate *endDate = [startDate dateWithTimeInterval: lengthOfArray * 60*60*24 
                                            sinceDate:startDate];
    [days 
    
}




@end
