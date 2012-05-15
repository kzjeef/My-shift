#import "ShiftAlgoFreeJump.h"
#import "NSDateAdditions.h"


@interface ShiftAlgoFreeJump()

NSArray *testArray;

@end

/**
   Free Jump shift is the shift like 
 */
@implementation ShiftAlgoFreeJump : ShiftAlgoBase

- (void) testInit()
{
    // Setup a test array for flowing case:
    // 1. 2 on 2 off, and 6 on 6 off.
    // Totally 12+4 = 16 days.
    NSMutableArray *ma = [[NSMutableArray alloc] init];
    
    [ma addObject: [NSNumber numberWithInt: 1]];
    [ma addObject: [NSNumber numberWithInt: 1]];
    [ma addObject: [NSNumber numberWithInt: 0]];
    [ma addObject: [NSNumber numberWithInt: 0]];
    for (int i = 0; i < 6; i++)
	[ma addObject: [NSNumber numberWithInt: 1]];
    for (int i = 0; i < 6; i++)
	[ma addObject: [NSNumber numberWithInt: 0]];
	
    testArray = [ma array];
}

- (NSArray *) shiftCalcWorkdayBetweenStartDate: (NSDate *) beginDate
					enDate: (NSDate *) endDate
{
    // 计算的时候使用gmt时间， 在要把date加入到时区里面的时候， 加上时区的秒数。
    NSInteger timeZoneDiff = [[NSTimeZone defaultTimeZone] secondsFromGMTForDate:beginDate];

    NSDate *jobStartGMT = [self.JobContext.jobStartDate
			      cc_dateByMovingToBeginningOfDayWithCalender:self.curCalendar];
    
    NSInteger diffBeginAndJobStartGMT = [self daysBetweenDateV2:jobStartGMT
							andDate:beginDate];
    NSInteger diffEndAndJobStartGMT = [self daysBetweenDateV2:jobStartGMT  andDate:endDate];
    NSInteger range  = [self daysBetweenDateV2:beginDate andDate:endDate];

    // 如果说都早于工作开始的时间， 就返回空
    if (diffEndAndJobStartGMT < 0 && diffBeginAndJobStartGMT < 0)
        return  [NSArray array];

    NSMutableArray *matchedArray = [[NSMutableArray alloc] init];
    NSDate *workingDate = beginDate;

    // The algo is like this:
    // 1. Calc how many days(total days) between "First day work start", and the "Test Day",
    // 2. Use "which day = Total days" % "ShiftsArray.size()"
    // 3. if  ShiftArray[WhichDay] == 1 , add the "Test Day to result array."

    for (int i = 0; i < range; i++) {
	int days;
	workingDate = [workingDate cc_dateByMovingToNextDayWithCalender:self.curCalendar];
	days = [self daysBetweenDateV2:jobStartGMT andDate:workingDate];
	if (days < 0)
	    continue;
	if ([self shiftIsWorkingDay: workingDate])
	    [matchedArray addObject:[[workingDate copy] dateByAddingTimeinterval:timeZoneDiff]];
    }

    return matchedArray;
}

- (BOOL)shiftIsWorkingDay: (NSDate *)theDate
{
    int days = [self daysBetweenDateV2:jobStartGMT andDate:workingDate];
    if (days < 0)
	return NO;
    if (days == 0)
	return [self isWorkingInFreeJumpArray: days];
}

/**
   this function is special for this algorithm, return the array if a
   working day by checking the object in the array.
   @offset is offset in the array.
 */

- (BOOL)isWorkInFreeJumpArray: (int) offset
{
    // Test version !!!
    NSAssrt (offset > testArray.size(), @"offset is biggger than array!");
    return [testArray objectAtIndex:offset].intValue == TRUE;
}
	
	
