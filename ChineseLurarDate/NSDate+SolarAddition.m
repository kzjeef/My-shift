//
//  NSDate+SolarAddition.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-12-29.
//
//

#import "NSDate+SolarAddition.h"

@implementation NSDate (SolarAddition)

- (BOOL) sa_isSolarLeapYear: (NSCalendar *)calendar
{
    unsigned int flags = NSYearCalendarUnit;
    NSDateComponents* parts = [calendar components:flags fromDate:self];

    // eg, 200 not leap year, 400 is leap year, 2004 is leap year.
    if ((parts.year % 4 == 0 && parts.year % 100 != 0) || (parts.year % 400 == 0))
        return YES;
    else
        return NO;
}

- (int)  sa_solarDaysInMonth: (NSCalendar *) calendar
{
    return [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:self].length;
}

- (NSDate *)sa_dateByMovingToBeginningOfDay: (NSCalendar *) calendar
{
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents* parts = [calendar components:flags fromDate:self];
    [parts setHour:0];
    [parts setMinute:0];
    [parts setSecond:0];
    return [calendar dateFromComponents:parts];
}


- (int) sa_solarDaysFromBaseDate: (NSCalendar *) calendar
{
    NSDate *baseDate = [NSDate date];
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents* parts = [calendar components:flags fromDate:baseDate];
    [parts setHour:0];
    [parts setMinute:0];
    [parts setSecond:0];
    [parts setDay:31];
    [parts setYear:1900];
    [parts setMonth:1];
    baseDate = [calendar dateFromComponents:parts];
    
    NSDate *endDate = [self sa_dateByMovingToBeginningOfDay:calendar];
    
    return [calendar components:NSDayCalendarUnit fromDate:baseDate toDate:endDate options:0].day;
}


@end
