//
//  OneJob.m
//  WhenWork
//
//  Created by Zhang Jiejing on 11-10-14.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "OneJob.h"
#import "NSDateAdditions.h"
#import "UIColor+HexCoding.h"
#import "UIImage+MonoImage.h"
#import "UIImageResizing.h"

#import "ShiftAlgoBase.h"
#import "ShiftAlgoFreeRound.h"
#import "ShiftAlgoFreeJump.h"

#define DAY_TO_SECONDS 60*60*24

@interface OneJob()
{
    ShiftAlgoBase *shiftAlgo;
    NSArray *jobShiftAllTypesString;
    NSCalendar *curCalender;
    NSCalendar *timezoneCalender;
    NSArray *jobFreeJumpTable;
    UIImage *iconImage;
    UIColor *iconColor;
    UIColor *defaultIconColor;
    NSString *cachedJobOnIconID;
    NSString *cachedJobOnIconColor;
    NSNumber *cachedJobOnIconColorOn;
    UIImage  *middleSizeImage;
}

@property (strong, nonatomic) ShiftAlgoBase *shiftAlgo;

// This two is shift start/end related member, if shift is regular, it function like normal.
// If the shift is X-Shift, it's the work lenght is fixed, and start time needs calculate by
// shift property and order.
@property (nonatomic, strong) NSNumber * jobEveryDayLengthSec;  // minites of every day work.
@property (nonatomic, strong) NSDate * jobEverydayStartTime;
@property (weak, nonatomic, readonly)  UIColor *defaultIconColor;

@end

@implementation OneJob
@dynamic jobName;
@dynamic jobEnable;
@dynamic jobDescription;
@dynamic jobEveryDayLengthSec;
@dynamic jobEverydayStartTime;
@dynamic jobOnDays;
@dynamic jobOffDays;
@dynamic jobStartDate;
@dynamic jobFinishDate;
@dynamic shiftdays;
@dynamic jobOnColorID;
@dynamic jobOnIconID;
@dynamic jobShiftType;
@dynamic jobRemindBeforeOff,jobRemindBeforeWork;
@dynamic jobFreeJumpCycle;
@dynamic jobFreeJumpArrayArchive;
@dynamic jobXShiftCount, jobXShiftStartShift, jobXShiftRevertOrder;
@dynamic jobShowTextInCalendar;
@synthesize curCalender, cachedJobOnIconColor, cachedJobOnIconID, shiftAlgo, jobShiftTypeString, middleSizeImage;

- (ShiftAlgoBase *)shiftAlgo;
{
    if (shiftAlgo == nil) {
        enum JobShiftAlgoType type = (enum JobShiftAlgoType)self.jobShiftType.intValue;
        switch(type) {
            case JOB_SHIFT_ALGO_FREE_ROUND:
                shiftAlgo = [[ShiftAlgoFreeRound alloc] initWithContext:self];
                break;
            case JOB_SHIFT_ALGO_FREE_JUMP:
                shiftAlgo = [[ShiftAlgoFreeJump alloc] initWithContext:self];
                break;
            default:
                shiftAlgo = [[ShiftAlgoFreeRound alloc] initWithContext:self];
                NSLog(@"OneJob: back fall the shift algo to shift round");
                break;
        }
    }
    return shiftAlgo;
}

- (void) setJobFreeJumpTable:(NSArray *) array
{
    jobFreeJumpTable = [array copy];
    self.jobFreeJumpArrayArchive = [NSKeyedArchiver archivedDataWithRootObject:jobFreeJumpTable];
    jobFreeJumpTable = nil;
    // archive the table to the core date also do here.
}

- (NSArray *)fixupArrayByLength: (NSArray *) inputarray
{
    int diff = inputarray.count - self.jobFreeJumpCycle.intValue;
    if (diff == 0)
        return inputarray;
    else if (diff < 0) {
        // oh, we needs fill the addional days with zero
        NSMutableArray *fixeda = [[NSMutableArray alloc] initWithCapacity:self.jobFreeJumpCycle.intValue];
        [fixeda setArray:inputarray];
        for (int i = 0; i < -diff; i++)
            [fixeda addObject: @0];
        return fixeda;
    } else {
        // diff < 0, we need cut the array with cycle length
        NSMutableArray *fixeda = [[NSMutableArray alloc] initWithCapacity:self.jobFreeJumpCycle.intValue];
        NSRange a = NSMakeRange(0, self.jobFreeJumpCycle.intValue);
//        NSAssert(inputarray.count == fixeda.count, @"size not equal");
        [fixeda replaceObjectsInRange:a withObjectsFromArray:inputarray range:a];
        return fixeda;
    }
}

- (void)didChangeValueForKey:(NSString *)key
{
    [super didChangeValueForKey:key];

    
    NSLog(@"Job: %@.%@ changed \n", self.jobName, key);

    if ([key isEqualToString:@"jobShiftType"])
        self.shiftAlgo = nil;
}

- (void) jobFreeJumpTableCacheInvalid
{
    jobFreeJumpTable = nil;
    [self createEmptyJumpTable];
}

/** this function should do the job convert all jump work information
 * to an array can be process by the modale
 */
- (NSArray *) jobFreeJumpTable
{
    if (jobFreeJumpTable != nil)
        return jobFreeJumpTable;
    if (self.jobFreeJumpArrayArchive != nil) {
        jobFreeJumpTable = [NSKeyedUnarchiver
                                 unarchiveObjectWithData:self.jobFreeJumpArrayArchive];
#ifdef DEBUG_FIXUP_TABLE
        NSLog(@"old cycle:%@ table: %@", self.jobFreeJumpCycle, jobFreeJumpTable);
#endif
        jobFreeJumpTable = [self fixupArrayByLength: jobFreeJumpTable];

#ifdef DEBUG_FIXUP_TABLE
        NSLog(@"cycle:%@ new table: %@", self.jobFreeJumpCycle, jobFreeJumpTable);
#endif
    } else
        [self createEmptyJumpTable];
    return jobFreeJumpTable;
}

- (void) createEmptyJumpTable
{
    NSLog(@"Create new jump table with cycle: %@", self.jobFreeJumpCycle);
    NSMutableArray *t = [[NSMutableArray alloc] initWithCapacity:self.jobFreeJumpCycle.intValue];
    for (int i = 0; i < self.jobFreeJumpCycle.intValue; i++) {
        [t addObject:[NSNumber numberWithBool:0]];
    }
    jobFreeJumpTable = [t copy];
}

#define FREE_ROUND_STRING NSLocalizedString(@"Regular Work Day", "")
#define FREE_JUMP_STRING NSLocalizedString(@"Customize Work Day", "")

//#define HOUR_ROUND_STRING NSLocalizedString(@"Hour Round", "")
#define NA_SHITF_STRING   NSLocalizedString(@"N/A", "")

- (NSArray *) jobShiftAllTypesString
{
    if (jobShiftAllTypesString == nil) {
	jobShiftAllTypesString = @[FREE_ROUND_STRING,
				  FREE_JUMP_STRING];
    }
    return jobShiftAllTypesString;
}

- (Boolean) shiftTypeValied
{
    NSInteger n = self.jobShiftType.intValue;
    if (n > 0 && n <= [[self jobShiftAllTypesString] count]) {
	return YES;
    }
    return NO;
}

- (Boolean) isShiftDateValied
{
    return  self.jobFinishDate == nil || ([self.jobStartDate compare:self.jobFinishDate] == NSOrderedAscending) ;
}

- (NSNumber *) shiftTotalCycle
{
    return [self.shiftAlgo shiftTotalCycle];
}

- (NSString *) jobShiftTypeString
{

    if ([self shiftTypeValied])
	return [[self jobShiftAllTypesString]
		   objectAtIndex:(self.jobShiftType.intValue - 1)];
    //    NSAssert(NO, @"shiftType return with empty string, should not happen");
    return NA_SHITF_STRING;
}

- (void) trydDfaultSetting
// will reset to default setting if not set.
{
    if (!self.jobOnDays)
	self.jobOnDays = @JOB_DEFAULT_ON_DAYS;

    if (!self.jobOffDays)
	self.jobOffDays = @JOB_DEFAULT_OFF_DAYS;

    if (!self.jobStartDate)
	self.jobStartDate = [NSDate date];

    if (!self.jobOnIconID)
    self.jobOnIconID = JOB_DEFAULT_ICON_FILE;

    if (!self.jobEnable)
	self.jobEnable = @(YES);

    if (!self.jobOnColorID)
	self.jobOnColorID = JOB_DEFAULT_COLOR_VALUE;

    NSDateComponents *defaultOnTime = [[NSDateComponents alloc] init];
    [defaultOnTime setHour:8];
    [defaultOnTime setMinute:0];
    if (!self.jobEverydayStartTime)
	self.jobEverydayStartTime =  [[NSCalendar currentCalendar] dateFromComponents:defaultOnTime];

    if (!self.jobEveryDayLengthSec)
	self.jobEveryDayLengthSec = @JOB_DEFAULT_EVERYDAY_ON_LENGTH; // 8 hour a day default

    if (!self.jobRemindBeforeOff)
	self.jobRemindBeforeOff = @JOB_DEFAULT_REMIND_TIME_BEFORE_OFF;

    if (!self.jobRemindBeforeWork)
	self.jobRemindBeforeWork = @JOB_DEFAULT_REMIND_TIME_BEFORE_WORK;

    if (!self.jobShowTextInCalendar)
	self.jobShowTextInCalendar = @0;

    if (!self.jobShiftType || self.jobShiftType.intValue == JOB_SHIFT_ALGO_NON_TYPE)
	self.jobShiftType = @(JOB_SHIFT_ALGO_FREE_JUMP);
}


- (void) forceDefaultSetting
// will reset to default setting if not set.
{
    self.jobOnDays = @JOB_DEFAULT_ON_DAYS;

    self.jobOffDays = @JOB_DEFAULT_OFF_DAYS;

    self.jobStartDate = [NSDate date];

    self.jobOnIconID = JOB_DEFAULT_ICON_FILE;

    self.jobOnColorID = JOB_DEFAULT_COLOR_VALUE;

    self.jobEnable = @(YES);

    NSDateComponents *defaultOnTime = [[NSDateComponents alloc] init];
    [defaultOnTime setHour:8];
    [defaultOnTime setMinute:0];
    self.jobEverydayStartTime =  [[NSCalendar currentCalendar] dateFromComponents:defaultOnTime];

    self.jobEveryDayLengthSec = @JOB_DEFAULT_EVERYDAY_ON_LENGTH; // 8 hour a day default
    self.jobRemindBeforeOff = @JOB_DEFAULT_REMIND_TIME_BEFORE_OFF;
    self.jobRemindBeforeWork = @JOB_DEFAULT_REMIND_TIME_BEFORE_WORK;
    self.jobFreeJumpCycle = @JOB_DEFAULT_JUMP_CYCLE;
}

- (int)getXShiftCount
{
    if (self.jobXShiftCount == nil || self.jobXShiftCount.intValue == 0)
	return 0;
    else
	return self.jobXShiftCount.intValue;
}

-(NSNumber *)getJobEveryDayLengthSec
{
    int v = [self getXShiftCount];
    if (v != 0)
        return @(DAY_TO_SECONDS / v);
    else
        return self.jobEveryDayLengthSec;
}

-(void)mysetJobEveryDayLengthSec:(NSNumber *)number
{
    self.jobEveryDayLengthSec = number;
}


-(NSDate *)getJobEverydayStartTime
{
	return self.jobEverydayStartTime;
}

-(void)mysetJobEverydayStartTime:(NSDate *)time
{
    self.jobEverydayStartTime = time;
}

-(NSDate *)getJobEverydayEndTime
{
    return [self.jobEverydayStartTime dateByAddingTimeInterval:self.jobEveryDayLengthSec.intValue];
}

- (NSString *)jobEverydayStartTimeWithFormatter:(NSDateFormatter *)formatter
{
    return [formatter stringFromDate:self.jobEverydayStartTime];
}


- (NSString *)jobEverydayOffTimeWithFormatter:(NSDateFormatter *)formatter
{
    return [formatter stringFromDate: [self getJobEverydayEndTime]];
}

- (UIImage *) middleSizeImage
{
#define LIST_ICON_SIZE CGSizeMake(25,25)

    if (middleSizeImage == nil || ![cachedJobOnIconID isEqualToString:self.jobOnIconID]) {
        middleSizeImage = [[self.iconImage copy] scaleAndCropToSize:LIST_ICON_SIZE onlyIfNeeded:YES];
    }
    
    return middleSizeImage;
}

- (UIImage *) iconImage
{
    if (!iconImage
	|| ![cachedJobOnIconID isEqualToString:self.jobOnIconID]
#ifdef ENABLE_COLOR_ENABLE_CHOOSE
	|| ![cachedJobOnIconColorOn isEqualToNumber:self.jobOnIconColorOn]
#endif
	) {

	if (self.jobOnIconID == nil)
	    self.jobOnIconID = JOB_DEFAULT_ICON_FILE;

	NSString *iconpath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"jobicons.bundle/%@", self.jobOnIconID] ofType:nil];

	iconImage = [UIImage imageWithContentsOfFile:iconpath];
	cachedJobOnIconID = self.jobOnIconID;
	if (!iconImage) {
	    NSLog(@"ICON: can't found icon %@", self.jobOnIconID);
	}

	// disable cholor enable or not choose by user;
#ifdef ENABLE_COLOR_ENABLE_CHOOSE
	cachedJobOnIconColorOn = self.jobOnIconColorOn;
       if (self.jobOnIconColorOn.intValue == TRUE) {
	    iconImage = [OneJob processIconImageWithColor:iconImage withColor:self.iconColor];
	}
#else
	iconImage = [UIImage generateMonoImage:iconImage withColor:self.iconColor];
#endif
    }
    return iconImage;
}

// Always have a color of Icon,
// for this application, color can use to notice different tasks,
// so different color make sense, no color not make sense.
// instread of return NULL, Return a default COLOR

#define DEFAULT_ALPHA_VALUE_OF_JOB_ICON 0.9f

- (UIColor *) defaultIconColor
{
    if (defaultIconColor == nil) {
	// 39814c is green one
	// B674C2 is light purple one
	defaultIconColor = [UIColor colorWithHexString:JOB_DEFAULT_COLOR_VALUE withAlpha:DEFAULT_ALPHA_VALUE_OF_JOB_ICON];
    }
    return defaultIconColor;
}

- (UIColor *) iconColor
{
    if (!iconColor || ![cachedJobOnIconColor isEqualToString:self.jobOnColorID]) {
	if (self.jobOnColorID == nil)
	    return self.defaultIconColor;
	NSLog(@"%@", self.jobOnColorID);
	iconColor = [UIColor colorWithHexString:self.jobOnColorID
				      withAlpha:DEFAULT_ALPHA_VALUE_OF_JOB_ICON];

	if (cachedJobOnIconColor != self.jobOnIconID)
	    cachedJobOnIconID = nil;
	cachedJobOnIconColor = self.jobOnColorID;

    }

#ifdef ENABLE_COLOR_ENABLE_CHOOSE
    if (self.jobOnIconColorOn.intValue == FALSE)
       return nil;
#endif

    return iconColor;
}


// ideas1 ， 只储存所有工作的日期， 在这个workdays的数组里。
//            问题： 但是问题是， 这样做了以后无法调整， 要调班的时候无法做了。
// idea2, 储存所有的日期， 一年也就365个嘛， 一百年也没多少个。 所以放的下。
//          这样就需要把nsdate做继承。 继承或者不继承。。 继承了不用改现有代码。
// 先选择2把。
- (id) initWithWorkConfigWithStartDate: (NSDate *) thestartDate
		     workdayLengthWith: (int) workdaylength
		     restdayLengthWith: (int) restdayLength
			 lengthOfArray: (int) lengthOfArray
			      withName:(NSString *)name
{
    self = [self init];

    self.jobName = name;
    self.jobOnDays = @(workdaylength);
    self.jobOffDays = @(restdayLength);
    self.jobStartDate = thestartDate;
    return self;
}


+ (BOOL) IsDateBetweenInclusive:(NSDate *)date begin: (NSDate *) begin end: (NSDate *)end;
{
    return [date compare:begin] != NSOrderedAscending && [date compare:end] != NSOrderedDescending;
}

- (NSDate *) dateByMovingForwardDays:(NSInteger) i withDate:(NSDate *) theDate
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.day = i;
    return [self.curCalender dateByAddingComponents:c toDate:theDate options:0];
}


- (NSArray *)returnWorkdaysWithInStartDate:(NSDate *) beginDate endDate:(NSDate *) endDate
{
    return [self.shiftAlgo shiftCalcWorkdayBetweenStartDate:beginDate endDate:endDate];
}

- (BOOL) isDayWorkingDay:(NSDate *)theDate
{
    return [self.shiftAlgo shiftIsWorkingDay:theDate];
}


- (BOOL) isShiftAlreadyOutdated
{
    if (self.jobFinishDate == nil) return NO;
    if ([[self.jobFinishDate cc_dateByMovingToMiddleOfDay]
         timeIntervalSinceDate:[[NSDate date] cc_dateByMovingToMiddleOfDay]] >= 0)
         return NO;
    else
        return YES;
}

// migrate old round shift to jump table shift to unify shift model.
- (BOOL) convertShiftRoundToJump
{
    if (self.jobShiftType.intValue == JOB_SHIFT_ALGO_FREE_JUMP)
      return YES;
    
    if (self.jobShiftType.intValue == JOB_SHIFT_ALGO_FREE_ROUND) {
        if (self.jobOnDays < 0 || self.jobOffDays < 0) {
            NSLog(@"invalid shift on convert shift round to jump...: %@", self);
            return NO;
        }

	@try {
	    self.jobShiftType = @(JOB_SHIFT_ALGO_FREE_JUMP);
	    
	    self.jobFreeJumpCycle = [NSNumber numberWithInt:self.jobOnDays.intValue
					      + self.jobOffDays.intValue];

	    NSMutableArray *a = [[NSMutableArray alloc]
                             initWithCapacity:self.jobFreeJumpCycle.intValue];

	    for (int i = 0; i < self.jobOnDays.intValue; i++)
            [a setObject:@1 atIndexedSubscript:i];
	    for (int i = self.jobOnDays.intValue; i < self.jobFreeJumpCycle.intValue; i++)
            [a setObject:@0 atIndexedSubscript:i];
        
	    [self setJobFreeJumpTable:a];
        
	    NSLog(@"Convert: contert a shift %@ to jump cycle shift", self);
        
	    return YES;
	}

	@catch (NSException *e) { // deal with exception ,and return false, if return false, db reset, and continue.
	    NSLog(@"Got Exception:%@ when process shift %@", e, self);
	    return NO;
	}
    }

    return YES;
}

@end
