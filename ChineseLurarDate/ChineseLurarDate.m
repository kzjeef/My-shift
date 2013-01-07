//
//  ChineseLurarDate.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-12-28.
//
//

#import "ChineseLurarDate.h"
#import "NSDateAdditions.h"
#import "NSDate+SolarAddition.h"

#define ARRAY_SIZE(a) (sizeof(a)/sizeof(a[0]))
#define BASE_DATE_YEAR 1900
#define BASE_DATE_MONTH 1
#define BASE_DATE_DAY   31

static unsigned int yearCode[] = {
    	0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, // 1904
	0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, // 1909
	0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, // 1914
	0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, // 1919
	0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, // 1924
	0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, // 1929
	0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, // 1934
	0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, // 1939
	0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, // 1944
	0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 1949
	0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5d0, // 1954
	0x14573, 0x052d0, 0x0a9a8, 0x0e950, 0x06aa0, // 1959
	0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, // 1964
	0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, // 1969
	0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, // 1974
	0x0d250, 0x0d558, 0x0b540, 0x0b5a0, 0x195a6, // 1979
	0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, // 1984
	0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, // 1989
	0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, // 1994
	0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0, // 1999
	0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, // 2004
	0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, // 2009
	0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, // 2014
	0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, // 2019
	0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, // 2024
	0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, // 2029
	0x05aa0, 0x076a3, 0x096d0, 0x04bd7, 0x04ad0, // 2034
	0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, // 2039
	0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, // 2044
	0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0  // 2049
};

static unsigned int solarTermCode[] = {
    0, 21208, 42467, 63836, 85337, 107014,
    128867, 150921, 173149, 195551, 218072, 240693,
    263343, 285989, 308563, 331033, 353350, 375494,
    397447, 419210, 440795, 462224, 483532, 504758 
};

static unsigned int lunarMonthDays[2] = {
    29,30
};

// NSArray Month  = [
// 	'正月', '二月', '三月', '四月', '五月', '六月',
//               '七月', '八月', '九月', '十月', '十一月', '腊月'];



@interface SharedLunarData : NSObject
{
    NSArray *_monthArray;
    NSArray *_dayArray;
    NSArray *_ganArray;
    NSArray *_zhiArray;
    NSArray *_zodiacArray;
    NSArray *_solarTerm;
    NSDictionary *_solarHoliday; // chinese only.
    NSDictionary *_lunarHoliday;
}

@property (nonatomic, strong) NSArray *monthArray;
@property (nonatomic, strong) NSArray *dayArray;
@property (nonatomic, strong) NSArray *ganArray;
@property (nonatomic, strong) NSArray *zhiArray;
@property (nonatomic, strong) NSArray *zodiacArray;
@property (nonatomic, strong) NSArray *solarTerm;
@property (nonatomic, strong) NSDictionary *solarHoliday;
@property (nonatomic, strong) NSDictionary *lunarHoliday;

+ (SharedLunarData *)sharedLunarData;

@end

static SharedLunarData *_sharedData = NULL;

@implementation SharedLunarData

+ (SharedLunarData *)sharedLunarData
{
    @synchronized([SharedLunarData class]) {
        if (!_sharedData)
            _sharedData = [[self alloc] init];
        return _sharedData;
    }
    
    return nil;
}

+ (id)alloc
{
    @synchronized([SharedLunarData class])
    {
        NSAssert(_sharedData == NULL, @"attempted to allocate a second SharedLunarData");
        _sharedData = [super alloc];
        return _sharedData;
    }
    
    return nil;
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        // init stuff.
    }
    return self;
}

- (NSArray *) monthArray
{
    if (!_monthArray)
        _monthArray = @[
            @"正月", @"二月", @"三月", @"四月",
             @"五月", @"六月", @"七月", @"八月",
             @"九月", @"十月", @"十一月", @"腊月"];

    return _monthArray;
}

- (NSArray *) dayArray
{
    if (!_dayArray)
        _dayArray = @[
            @"初一", @"初二", @"初三", @"初四", @"初五", @"初六", @"初七", @"初八", @"初九", @"初十",
             @"十一", @"十二", @"十三", @"十四", @"十五", @"十六", @"十七", @"十八", @"十九", @"二十",
             @"廿一", @"廿二", @"廿三", @"廿四", @"廿五", @"廿六", @"廿七", @"廿八", @"廿九", @"三十"];
    
    return _dayArray;
}

- (NSArray *) ganArray
{
    if (!_ganArray)
        _ganArray = @[
            @"甲", @"乙", @"丙", @"丁", @"戊",
             @"己", @"庚", @"辛", @"壬", @"癸"];
    return _ganArray;
}

- (NSArray *) zhiArray
{
    if (!_zhiArray)
        _zhiArray = @[
            @"子", @"丑", @"寅", @"卯", @"辰",
            @"巳", @"午", @"未", @"申", @"酉",
            @"戌", @"亥"];
    return _zhiArray;
}

- (NSArray *) zodiacArray
{
    if (!_zodiacArray)
        _zodiacArray = @[
            @"鼠", @"牛", @"虎", @"兔", @"龙",
            @"蛇", @"马", @"羊", @"猴", @"鸡",
            @"狗", @"猪"];
    return _zodiacArray;
}

- (NSArray *) solarTerm
{
    if (!_solarTerm)
        _solarTerm = @[
            @"立春", @"雨水", @"清明", @"春分", @"惊蛰", @"谷雨",
             @"立夏", @"小满", @"芒种", @"夏至", @"小暑", @"大暑",
             @"立秋", @"处暑", @"白露", @"秋分", @"寒露", @"霜降",
             @"立冬", @"小雪", @"大雪", @"冬至", @"小寒", @"大寒"];

    return _solarTerm;
}

- (NSDictionary *) solarHoliday
{
    if (!_solarHoliday)
        _solarHoliday = @{
            @"0101":@"元旦",
            @"0214":@"情人节",
            @"0308":@"妇女节",
            @"0312":@"植树节",
            @"0401":@"愚人节",
            @"0501":@"劳动节",
            @"0504":@"青年节",
            @"0601":@"儿童节",
            @"0701":@"建党节",
            @"0801":@"建军节",
            @"0910":@"教师节",
            @"1001":@"国庆节",
            @"1225":@"圣诞节"
        };

    return _solarHoliday;
}

- (NSDictionary *) lunarHoliday
{
    if (!_lunarHoliday)
        _lunarHoliday = @{
          @"0101":@"春节",
          @"0115":@"元宵",
          /* TODO deal with "清明" */
          @"0505":@"端午",
          @"0707":@"七夕",
          @"0815":@"中秋",
          @"0909":@"重阳",
          @"1208":@"腊八"
        };

    return _lunarHoliday;
}

@end

// should start with # 1900年1月31日星期三（庚子年正月初一壬寅日）


@interface ChineseLurarDate() {
    SharedLunarData *_data;
    NSDate          *_date;
    NSCalendar      *_calendar;

    int              _solarYear;
    int              _solarMonth;
    int              _solarDay;

    int              _lunarYear;
    int              _lunarMonth;
    int              _lunarDay;
    int              _lunarYearDays;

    int              _lunarDaysInMonth[13];
}
@end

@implementation ChineseLurarDate


- (id) init
{
    self = [super init];
    if (self != nil) {
        _data = [SharedLunarData sharedLunarData];
        memset(_lunarDaysInMonth, 0, sizeof(_lunarDaysInMonth));
    }
    
    return self;
}

- (void) initSolarMember
{
    unsigned int flags = NSYearCalendarUnit
        | NSMonthCalendarUnit
        | NSDayCalendarUnit;
    NSDateComponents *parts = [_calendar components:flags fromDate:_date];

    NSAssert(parts != nil, @"date components return null");

    _solarYear = parts.year;
    _solarMonth = parts.month;
    _solarDay = parts.day;
}

- (id) initWithDate:(NSDate *) date
{
    self = [self initWithDate:date calendar:[NSCalendar currentCalendar]];
    return self;
}

- (id) initWithDate:(NSDate *)date calendar: (NSCalendar *)calendar
{
    self = [self init];
    if (self != nil) {
        _date = [date copy];
        _calendar = calendar;
        [self initSolarMember];
        [self solarToLunar];
    }
    return self;
}

- (id) initWithYear:(int) year
{
    self = [self initWithYear:year month:0 day:0];
    return self;
}

- (id) initWithYear:(int) year month: (int) month
{
    self = [self initWithYear:year month:month day:0];
    return self;
}

- (id) initWithYear:(int) year month: (int) month day:(int)day
{
    self = [self init];
    if (self) {
        _solarYear = year;
        _solarMonth = month;
        _solarDay = day;
    }
    return self;
}


- (void) solarToLunar
{
    int offset = [_date sa_solarDaysFromBaseDate:_calendar];

    // 1. Loop from the yearCode's begining to end, from 1900,
    // descrease offset from 1900 by each year's luran day count,
    // until offset less than lunar days count, it means loop to the
    // target year.
    for (int i = 0; i < ARRAY_SIZE(yearCode); i++) {
        _lunarYearDays = [[[ChineseLurarDate alloc] initWithYear: i + 1900] getLunarYearDays];

        if (offset < _lunarYearDays) {
            _lunarYear = i + 1900;
            break;
        }

        offset -= _lunarYearDays;
    }

    // 2. Loop from 1st to 13th month (leap year have 13 months, will
    // be zero for not leap month), and minus until offset less than
    // month day count, means we have reach the target month.
    for (int i = 0; i < 13; i++) {
        ChineseLurarDate *a = [[ChineseLurarDate alloc] initWithYear: _lunarYear
                                                          month: i + 1];
        [a calcLunarDaysInMonth];
        if (offset < [a getLunarDaysInMonth:i]) {
            _lunarMonth = i;
            break;
        }
        offset -= [a getLunarDaysInMonth:i];
    }

    // 3. After year, and month minus, only day left.
    _lunarDay = offset;

    if ([self getLunarLeapMonth] > 0 && _lunarMonth >= [self getLunarLeapMonth])
        _lunarMonth -= 1;

    // back to 1 start
    _lunarYear++;
    _lunarMonth++;
    _lunarDay++;

}


- (int) getLunarLeapMonth
{
    return yearCode[_solarYear - BASE_DATE_YEAR] & 0xf;
}

- (int) getLunarDaysInMonth:(int)month
{
    NSAssert(month < ARRAY_SIZE(_lunarDaysInMonth), @"out off the array size");
    return _lunarDaysInMonth[month];
}


- (void) calcLunarDaysInMonth
{
    unsigned int code = yearCode[_solarYear - BASE_DATE_YEAR];

    code >>= 4;
    
    for (int imonth = 0; imonth < 12; imonth++) {
        _lunarDaysInMonth[11 - imonth] = lunarMonthDays[code & 0x1];
        code >>= 1;
    }

    if ([self getLunarLeapMonth] > 0) {
        int month = [self getLunarLeapMonth];
        memmove(&_lunarDaysInMonth[month],
                &_lunarDaysInMonth[month - 1],
                (13 - month) * sizeof(_lunarDaysInMonth[0]));
        // why 13, the lunar month here is a number, 4 is April
        // eg, 12 needs move one unit.

        _lunarDaysInMonth[month] = lunarMonthDays[code & 0x1];
    }
}

- (int) getLunarYearDays
{
    [self calcLunarDaysInMonth];
    int monthNum =  ([self getLunarLeapMonth] == 0) ? 12 : 13;
    for (int i = 0; i < monthNum; i++)
        _lunarYearDays += _lunarDaysInMonth[i];
    return _lunarYearDays;
}


- (NSString *) getGanZhiYearString
{
    int x = _solarYear % 60 - 4;
    int y = (x >= 0) ? x : x + 60;

    return [NSString stringWithFormat:@"%@%@",
                     [_data.ganArray objectAtIndex:x % 12],
            [_data.zhiArray objectAtIndex:y % 12]];
}

- (NSString *) zodiacString
{
    int x = _solarYear % 60 - 4;
    int y = (x >= 0) ? x : x + 60;

    return [_data.zodiacArray objectAtIndex:y % 12];
}

- (NSString *) lunarMonthString
{
    return [_data.monthArray objectAtIndex:_lunarMonth - 1];
}

- (NSString *) lunarDayString
{
    
    NSAssert(_lunarDay != 0, @"lunar day not init, call SolarToLunar first.");
    NSAssert(_lunarMonth != 0, @"lunar month not init, call SolarToLunar first.");
    NSAssert(_lunarYear != 0, @"lunar year not init, call SolarToLunar first.");
    if (_lunarDay == 1 && [self getLunarLeapMonth] > 0) {
        int lm = [self getLunarLeapMonth];
        if (lm == _lunarMonth)
            return [NSString stringWithFormat:@"%@%@",
                             @"闰",
                             [_data.monthArray objectAtIndex: lm - 1]];
        else
            return [self lunarMonthString];
    }

    if (_lunarDay == 1)
        return [self lunarMonthString];

    return [_data.dayArray objectAtIndex:_lunarDay - 1];
}


- (NSString *) lunarHoliday
{
    NSString *month;
    NSString *day;
    
    if (_lunarMonth < 10)
        month = [NSString stringWithFormat:@"0%d", _lunarMonth];
    else
        month = [NSString stringWithFormat:@"%d", _lunarMonth];

    if (_lunarDay < 10)
        day = [NSString stringWithFormat:@"%0d", _lunarDay];
    else
        day = [NSString stringWithFormat:@"%d", _lunarDay];

    
    return [_data.lunarHoliday
               objectForKey:[NSString stringWithFormat:@"%@%@", month, day]];
}

- (NSString *) getSolarTerm
{
    for (int i = 0; i < 12; i++) {
        
    }
}


@end
