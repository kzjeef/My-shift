#import "ShiftAlgoFreeJump.h"
#import "NSDateAdditions.h"

//#define SAFDEBUG

#ifdef SAFDEBUG
#define dbg(x...) NSLog(x)
#else
#define dbg(x...) do {} while (0)
#endif

@interface ShiftAlgoFreeJump() {
    NSDateFormatter *formatter;
}

@end

/**
   Free Jump shift is the shift like 
 */
@implementation ShiftAlgoFreeJump : ShiftAlgoBase

- (id) initWithContext: (OneJob *) job
{
     self = [super initWithContext:job];
     [self setShiftType:JOB_SHIFT_ALGO_FREE_JUMP];

     return self;
}

- (NSNumber *) shiftTotalCycle
{
    return @([self getCountOfJumpArray]);
}

- (NSArray *) shiftCalcWorkdayBetweenStartDate: (NSDate *) beginDate endDate: (NSDate *) endDate
{
    // 计算的时候使用gmt时间， 在要把date加入到时区里面的时候， 加上时区的秒数。

    dbg(@"shiftCalcWorkday: begin:%@ end:%@",
	[formatter stringFromDate:beginDate],
	[formatter stringFromDate:endDate]);

    NSDate *jobStartGMT = [self.JobContext.jobStartDate
                           cc_dateByMovingToBeginningOfDayWithCalender:self.curCalendar];

    NSInteger diffBeginAndJobStartGMT = [self daysBetweenDateV2:jobStartGMT
							andDate:beginDate];
    NSInteger diffEndAndJobStartGMT = [self daysBetweenDateV2:jobStartGMT  andDate:endDate];
    NSInteger range  = [self daysBetweenDateV2:beginDate andDate:endDate];

    // 如果说都早于工作开始的时间， 就返回空
    if (diffEndAndJobStartGMT < 0 && diffBeginAndJobStartGMT < 0)
        return  @[];

    NSMutableArray *matchedArray = [[NSMutableArray alloc] init];
    NSDate *workingDate = beginDate;

    // The algo is like this:
    // 1. Calc how many days(total days) between "First day work start", and the "Test Day",
    // 2. Use "which day = Total days" % "ShiftsArray.size()"
    // 3. if  ShiftArray[WhichDay] == 1 , add the "Test Day to result array."

    dbg(@"range: %d\n", range);
    for (int i = 0; i < range; i++) {
        if ([self shiftIsWorkingDay: workingDate])
            [matchedArray addObject:[[workingDate copy] cc_dateByMovingToMiddleOfDay]];

        workingDate = [workingDate cc_dateByMovingToNextDayWithCalender:self.curCalendar];
    }

    return matchedArray;
}

- (BOOL)shiftIsWorkingDay: (NSDate *)theDate
{
    NSAssert([self getCountOfJumpArray] > 0, @"The jump array must > 0");
    NSDate *jobStartGMT = [self.JobContext.jobStartDate
                              cc_dateByMovingToBeginningOfDayWithCalender:self.curCalendar];
    NSDate *jobFinishGMT = [self.JobContext.jobFinishDate
                               cc_dateByMovingToBeginningOfDayWithCalender:self.curCalendar];

    if (![OneJob IsDateBetweenInclusive: theDate begin:jobStartGMT end:jobFinishGMT])
        return NO;

    int days = [self daysBetweenDateV2:jobStartGMT andDate:theDate];

    if (days < 0)
        return NO;
    else
        return [self isWorkInFreeJumpArray:days % [self getCountOfJumpArray]];
}

- (int)getCountOfJumpArray
{
    return self.JobContext.jobFreeJumpTable.count;
}
                
/**
   this function is special for this algorithm, return the array if a
   working day by checking the object in the array.
   @offset is offset in the array.
 */

- (BOOL)isWorkInFreeJumpArray: (int) offset
{
    // Test version !!!
    NSAssert(offset < [self.JobContext.jobFreeJumpTable count], @"offset is biggger than array!offset:%d count:%lu ", offset, (unsigned long)[self.JobContext.jobFreeJumpTable count]);
    return [[self.JobContext.jobFreeJumpTable objectAtIndex:offset] intValue] == TRUE;
}
	
	
@end
