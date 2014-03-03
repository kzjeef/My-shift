//
//  InfoNode.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-2-17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OneJob;

@interface InfoNode : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSDate * create;
@property (nonatomic, retain) NSDate * modify;
@property (nonatomic, retain) OneJob *shift;

@end
