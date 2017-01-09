/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "NSDateAdditions.h"

@implementation NSDate (KalAdditions)

- (NSDate *)cc_dateByMovingToBeginningOfDay
{
  unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
  NSDateComponents* parts = [[NSCalendar currentCalendar] components:flags fromDate:self];
  [parts setHour:0];
  [parts setMinute:0];
  [parts setSecond:0];
  return [[NSCalendar currentCalendar] dateFromComponents:parts];
}

- (NSDate *)cc_dateByMovingToMiddleOfDay
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* parts = [[NSCalendar currentCalendar] components:flags fromDate:self];
    [parts setHour:12];
    [parts setMinute:0];
    [parts setSecond:0];
    return [[NSCalendar currentCalendar] dateFromComponents:parts];
}

- (NSDateComponents *)cc_getDateComponents
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *parts = [[NSCalendar autoupdatingCurrentCalendar] components:flags fromDate:self];
    return parts;
}

- (NSDate *)cc_dateByMovingToEndOfDay
{
  unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
  NSDateComponents* parts = [[NSCalendar currentCalendar] components:flags fromDate:self];
  [parts setHour:23];
  [parts setMinute:59];
  [parts setSecond:59];
  return [[NSCalendar currentCalendar] dateFromComponents:parts];
}


- (NSDate *)cc_dateByMovingToBeginningOfDayWithCalender:(NSCalendar *) cal
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* parts = [cal components:flags fromDate:self];
    [parts setHour:0];
    [parts setMinute:0];
    [parts setSecond:0];
    return [cal dateFromComponents:parts];
}

- (NSDate *)cc_dateByMovingToMiddleOfDayWithCalender:(NSCalendar *) cal
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* parts = [cal components:flags fromDate:self];
    [parts setHour:12];
    [parts setMinute:0];
    [parts setSecond:0];
    return [cal dateFromComponents:parts];
}

- (NSDate *)cc_convertToUTC
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* parts = [[NSCalendar currentCalendar] components:flags fromDate:self];
    return [[NSCalendar currentCalendar ] dateFromComponents:parts];
}

- (NSString *)cc_getHourMinitesFromDate
{
    
    unsigned int flags =  NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents* parts = [[NSCalendar currentCalendar] components:flags fromDate:self];
    
    return [NSString stringWithFormat:@"%ld:%ld", (long)[parts hour], (long)[parts minute]];
}


- (NSDate *)cc_dateByMovingToEndOfDayWithCalender:(NSCalendar *)cal
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* parts = [cal components:flags fromDate:self];
    [parts setHour:23];
    [parts setMinute:59];
    [parts setSecond:59];
    return [cal dateFromComponents:parts];
}

- (NSDate *)cc_dateByMovingToNextDayWithCalender: (NSCalendar *)cal
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.day = 1;
    return [cal dateByAddingComponents:c toDate:self options:0];
}

- (NSDate *)cc_dateByMovingToFirstDayOfTheMonthWithCalendar:(NSCalendar *)cal
{
    NSDate *d = nil;
    BOOL ok = [cal rangeOfUnit:NSCalendarUnitMonth startDate:&d interval:NULL forDate:self];
    NSAssert1(cal, @"calendar is null:%@", cal);
    NSAssert1(ok, @"Failed to calculate the first day the month based on cal: %@", self);
    ok =  ok; // avoid warnning
    return d;
}

- (NSDate *)cc_dateByMovingToFirstDayOfTheMonth
{
  NSDate *d = nil;
  BOOL ok = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitMonth startDate:&d interval:NULL forDate:self];
  NSAssert1(ok, @"Failed to calculate the first day the month based on %@", self);
    ok =  ok; // avoid warnning
  return d;
}

- (NSDate *)cc_dateByMovingToFirstDayOfThePreviousMonth
{
  NSDateComponents *c = [[NSDateComponents alloc] init];
  c.month = -1;
  return [[[NSCalendar currentCalendar] dateByAddingComponents:c toDate:self options:0] cc_dateByMovingToFirstDayOfTheMonth];  
}

- (NSDate *)cc_dateByMovingToNextOrBackwardsFewDays: (int) days withCalender:(NSCalendar *)cal
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.day = days;
    return [cal dateByAddingComponents:c toDate:self options:0];
}

- (NSDate *)cc_dateByMovingToFirstDayOfThePreviousMonthWithCal:(NSCalendar *)cal
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.month = 1;
    return [[cal dateByAddingComponents:c toDate:self options:0] cc_dateByMovingToFirstDayOfTheMonth];

}

- (NSDate *)cc_dateByMovingToFirstDayOfTheFollowingMonth
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
  c.month = 1;
  return [[[NSCalendar currentCalendar] dateByAddingComponents:c toDate:self options:0] cc_dateByMovingToFirstDayOfTheMonth];
}

- (NSDateComponents *)cc_componentsForMonthDayAndYearWithCal:(NSCalendar *)cal
{
    return [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self];
}


- (NSDateComponents *)cc_componentsForMonthDayAndYear
{
  return [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self];
}

- (NSUInteger)cc_weekday
{
    return [[NSCalendar currentCalendar] ordinalityOfUnit:NSCalendarUnitDay inUnit:NSWeekCalendarUnit forDate:self];
}

- (NSUInteger)cc_weekdayWithCalendar:(NSCalendar *) calendar
{
    return [calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSWeekCalendarUnit forDate:self];
}

- (NSUInteger)cc_numberOfDaysInMonth
{
  return [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self].length;
}


- (NSDate *) cc_dateBySetTimePart:(NSDate *) time withCalendar:(NSCalendar *) cal {
    
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;

    
    //unsigned int flags = NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitSecond | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitDay;
    NSDateComponents* timeparts = [cal components:flags fromDate:time];
    
    NSDateComponents *parts = [cal components:flags fromDate:self];

    [parts setHour:[timeparts hour]];
    [parts setMinute:[timeparts minute]];
    [parts setSecond:[timeparts second]];
    return [cal dateFromComponents:parts];
}

@end
