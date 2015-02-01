//
//  SSHolidayHelper.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/1/31.
//
//

#import "SSHolidayHelper.h"
#import "SSHolidayManager.h"

@implementation SSHolidayHelper



+ (NSArray *) getHolidayForDate:(NSDate *) date holidayManagers: (NSArray *) managers
{
    NSAssert(date != nil, @"Date not should nil");
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (SSHolidayManager *m in managers) {
        NSArray *a = [m getHolidayListForDate:date];
        if (a != nil && [a lastObject] != nil)
            [result addObjectsFromArray:a];
    }
    
    return result;
}

+ (NSArray *) getHolidayFromDateToDate:(NSDate *) fromDate  endDate:(NSDate *) toDate holidayManagers: (NSArray *) managers {

    NSDate *d = [fromDate copy];
    NSMutableArray *res = [[NSMutableArray alloc] init];
    while (true) {
        NSArray *a = [SSHolidayHelper getHolidayForDate:d holidayManagers:managers];
        if ([a lastObject] != nil)
            [res addObject:[d copy]];
        d = [d dateByAddingTimeInterval:ONE_DAY_SECONDS];
        if ([d compare:toDate] == NSOrderedDescending)
            break;
    }
    return res;
}



@end
