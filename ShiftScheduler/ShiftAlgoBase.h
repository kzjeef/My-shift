
#import <CoreData/CoreData.h>

#import "OneJob.h"

@interface ShiftAlgoBase : NSObject
{
}

@property (strong) OneJob *JobContext;
@property (weak, readonly) NSCalendar *curCalendar;


- (id) initWithContext: (OneJob *)context;
- (NSArray *) shiftCalcWorkdayBetweenStartDate: (NSDate *) startDate endDate: (NSDate *) endDate;
- (BOOL) shiftIsWorkingDay: (NSDate *)theDate;
- (void) setShiftType:(enum JobShiftAlgoType)mshiftType;
- (NSNumber *) shiftTotalCycle;
- (NSInteger)daysBetweenDateV2:(NSDate *)fromDateTime andDate:(NSDate *)toDateTime;

@end
