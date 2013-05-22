/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <Foundation/Foundation.h>

@interface NSDate (KalAdditions)

// All of the following methods use [NSCalendar currentCalendar] to perform
// their calculations.

- (NSDate *)cc_dateByMovingToBeginningOfDay;
- (NSDate *)cc_dateByMovingToMiddleOfDay;
- (NSDate *)cc_dateByMovingToEndOfDay;
- (NSDate *)cc_dateByMovingToEndOfDayWithCalender:(NSCalendar *)cal;
- (NSDate *)cc_dateByMovingToBeginningOfDayWithCalender:(NSCalendar *) cal;
- (NSDate *)cc_dateByMovingToFirstDayOfTheMonth;
- (NSDate *)cc_dateByMovingToFirstDayOfTheMonthWithCalendar:(NSCalendar *)cal;
- (NSDate *)cc_dateByMovingToNextOrBackwardsFewDays: (int) days withCalender:(NSCalendar *)cal;
- (NSDate *)cc_dateByMovingToNextDayWithCalender: (NSCalendar *)cal;
- (NSDate *)cc_dateByMovingToFirstDayOfThePreviousMonth;
- (NSDate *)cc_dateByMovingToFirstDayOfTheFollowingMonth;
- (NSDateComponents *)cc_componentsForMonthDayAndYear;
- (NSUInteger)cc_weekday;
- (NSUInteger)cc_weekdayWithCalendar:(NSCalendar *) calendar;
- (NSUInteger)cc_numberOfDaysInMonth;

@end
