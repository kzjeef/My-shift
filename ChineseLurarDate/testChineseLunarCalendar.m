//
//  testChineseLunarCalendar.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-1-3.
//
//

#import "testChineseLunarCalendar.h"
#import "ChineseLurarDate.h"

@implementation testChineseLunarCalendar

- (void)setUp
{
    [super setUp];
    
}

- (void) testLunarCalendarAllocate
{
    ChineseLurarDate *date = [[ChineseLurarDate alloc] initWithDate:[NSDate date]];
    
    STAssertFalse(date == nil, @"can not allocate chinese lunar date object");
    
    [date solarToLunar];
    NSString *lunarDayString = [date lunarDayString];
    NSString *lunarMonthStr = [date lunarMonthString];
    NSString *ganzhiStr     = [date getGanZhiYearString];
    
    STAssertFalse(lunarDayString == nil, @"lunar da string is zero");
    STAssertFalse(lunarMonthStr == nil, @"lunar m str is nil");
    STAssertFalse(ganzhiStr == nil, @"Ganzhi str is nil");
    
    NSLog(@"Full Lunar Day: %@ %@ %@",ganzhiStr, lunarMonthStr, lunarDayString);
}

- (void) tearDown
{
    [super tearDown];
}

@end
