//
//  SSHolidayHelper.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/1/31.
//
//

#import <Foundation/Foundation.h>

@interface SSHolidayHelper : NSObject

+ (NSArray *) getHolidayForDate:(NSDate *) date holidayManagers: (NSArray *) managers;
+ (NSArray *) getHolidayFromDateToDate:(NSDate *) fromDate  endDate:(NSDate *) toDate holidayManagers: (NSArray *) managers;

@end
