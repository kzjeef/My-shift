//
//  NSDate+SolarAddition.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-12-29.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (SolarAddition)

- (BOOL) sa_isSolarLeapYear: (NSCalendar *)calendar;
- (int)  sa_solarDaysInMonth: (NSCalendar *) calendar;
- (int) sa_solarDaysFromBaseDate: (NSCalendar *) calendar;

@end
