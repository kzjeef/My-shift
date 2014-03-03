//
//  SyncEvent.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-2-24.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OneJob;

@interface SyncEvent : NSManagedObject

@property (nonatomic, retain) NSString * ekId;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * alarmOne;
@property (nonatomic, retain) NSNumber * alarmTwo;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) OneJob *shift;

@end
