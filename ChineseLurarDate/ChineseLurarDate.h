//
//  ChineseLurarDate.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-12-28.
//
//

#import <Foundation/Foundation.h>

@interface ChineseLurarDate : NSObject

// ----------------
// Init Fcuntions part.

- (id) initWithDate:(NSDate *) date;
- (id) initWithDate:(NSDate *)date calendar: (NSCalendar *)calendar;


// ----------------
// String function parts.
- (void) solarToLunar;
- (int) getLunarLeapMonth;
- (int) getLunarDaysInMonth:(int)month;
- (void) calcLunarDaysInMonth;
- (int) getLunarYearDays;
- (NSString *) getGanZhiYearString;
- (NSString *) zodiacString;
- (NSString *) lunarMonthString;
- (NSString *) lunarDayString;
- (NSString *) lunarHoliday;

@end
