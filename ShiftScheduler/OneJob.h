//
//  OneJob.h
//  WhenWork
//
//  Created by Zhang Jiejing on 11-10-14.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#include "ShiftDay.h"


#define JOB_DEFAULT_ON_DAYS                     5
#define JOB_DEFAULT_OFF_DAYS                    2
#define JOB_DEFAULT_ICON_FILE                   @"bag32.png"
#define JOB_DEFAULT_COLOR_VALUE                 @"366BCF"
#define JOB_DEFAULT_EVERYDAY_ON_LENGTH          (60*60*8)
#define JOB_DEFAULT_REMIND_TIME_BEFORE_WORK     -1
#define JOB_DEFAULT_REMIND_TIME_BEFORE_OFF      -1
#define JOB_DEFAULT_JUMP_CYCLE 7

enum JobShiftAlgoType {
  JOB_SHIFT_ALGO_NON_TYPE = 0,	// Report assert here.
  JOB_SHIFT_ALGO_FREE_ROUND, // X on X off round robin shift.
  JOB_SHIFT_ALGO_FREE_JUMP,	 // X on/off self check in Y days.
  JOB_SHIFT_ALGO_HOUR_ROUND ,	 // three shift system. 
};

@interface OneJob : NSManagedObject

// Common
@property (nonatomic, strong) NSString  *jobName;       // the job's name
@property (nonatomic, strong) NSNumber  *jobEnable;   // bool enable the job display on the cal or not
@property (nonatomic, strong) NSString  *jobDescription; //the detail describe of this job
@property (nonatomic, strong) NSDate    *jobStartDate;
@property (nonatomic, strong) NSDate    *jobFinishDate;
@property (nonatomic, strong) NSNumber  *jobShiftType;
@property (weak, nonatomic, readonly) NSString        *jobShiftTypeString;
@property (nonatomic, strong) NSCalendar        *curCalender;

// For (legency/Most common) On/Off Days work shift.
@property (nonatomic, strong) NSNumber  *jobOnDays; // how long works once
@property (nonatomic, strong) NSNumber  *jobOffDays; // how long rest once.

// For support ICON of Shift Day.
@property (nonatomic, strong) NSNumber  *jobShowTextInCalendar;
@property (nonatomic, strong) NSString  *jobOnColorID;
@property (nonatomic, strong) NSString  *jobOnIconID;
@property (nonatomic, strong) NSString  *cachedJobOnIconColor;
@property (nonatomic, strong) NSString  *cachedJobOnIconID;
@property (weak, nonatomic, readonly) UIImage  *iconImage;
@property (weak, nonatomic, readonly) UIColor  *iconColor;

// For reminder support
@property (nonatomic, strong) NSNumber *jobRemindBeforeOff;
@property (nonatomic, strong) NSNumber *jobRemindBeforeWork;

// Choose able work days Table.
@property (nonatomic, strong) NSArray  *jobFreeJumpTable;
@property (nonatomic, strong) NSNumber *jobFreeJumpCycle;
@property (nonatomic, strong) NSData * jobFreeJumpArrayArchive;

// X Shift Support...
@property (nonatomic, strong) NSNumber *jobXShiftCount; // X shift a day, for the 3-shift like work schedule.
@property (nonatomic, strong) NSNumber *jobXShiftStartShift; // X shift, what's you shart shift.
@property (nonatomic, strong) NSNumber *jobXShiftRevertOrder; // True If it's revert order.


// init the work date generator with these input.
- (id) initWithWorkConfigWithStartDate: (NSDate *) startDate
                     workdayLengthWith: (int) workdaylength
                     restdayLengthWith: (int) restdayLength
                         lengthOfArray: (int) lengthOfArray
                              withName: (NSString *)name;

- (NSArray *) returnWorkdaysWithInStartDate:(NSDate *) startDate endDate: (NSDate *) endDate;
- (BOOL) isDayWorkingDay:(NSDate *)theDate;

- (UIColor *) iconColor;
- (void) trydDfaultSetting;
- (void) forceDefaultSetting;
-(NSNumber *)getJobEveryDayLengthSec;
-(void)mysetJobEveryDayLengthSec:(NSNumber *)number;
-(NSDate *)getJobEverydayStartTime;
-(void)mysetJobEverydayStartTime:(NSDate *)time;
-(NSDate *)getJobEverydayEndTime;
- (NSString *)jobEverydayStartTimeWithFormatter:(NSDateFormatter *)formatter;
- (NSString *) jobEverydayOffTimeWithFormatter:(NSDateFormatter *) formatter;

- (NSArray *) jobShiftAllTypesString;
- (Boolean) shiftTypeValied;
- (Boolean) isShiftDateValied;
- (NSNumber *) shiftTotalCycle;
+ (BOOL) IsDateBetweenInclusive:(NSDate *)date begin: (NSDate *) begin end: (NSDate *)end;
- (void) jobFreeJumpTableCacheInvalid;

@property (nonatomic, strong) NSSet *shiftdays;
@end

@interface OneJob (CoreDataGeneratedAccessors)

//  should check whether the shiftday is allowed. if the shift day is now allowed, return -Error Code;

//  eg, if the shift day is exchange shift day, one of "From" or "To" must has one "on day"
//      in a overwork shift day: it must added to a "off day"
//      in a vacation shift day: it must be on a "on day"

// return value:
// failed: return -X; is error number
// success: return 0;
- (NSInteger)addShiftdaysObject:(ShiftDay *)value;

- (void)removeShiftdaysObject:(ShiftDay *)value;
- (void)addShiftdays:(NSSet *)values;
- (void)removeShiftdays:(NSSet *)values;

@end



