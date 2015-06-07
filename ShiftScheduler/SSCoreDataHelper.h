//
//  SSCoreDataHelper.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/6/7.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SSCoreDataHelper : NSObject


+ (NSManagedObjectModel *)createShiftModel;

+ (NSPersistentStoreCoordinator *) createPersistentStoreCoordinator: (NSManagedObjectModel *)model;

+ (NSManagedObjectContext *) createContext: (NSPersistentStoreCoordinator *) coordinator;

@end
