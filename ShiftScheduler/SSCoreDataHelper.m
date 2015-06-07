//
//  SSCoreDataHelper.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/6/7.
//
//

#import "SSCoreDataHelper.h"

@implementation SSCoreDataHelper

+ (NSManagedObjectModel *)createShiftModel
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ShiftScheduler" withExtension:@"momd"];
    return  [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

+ (NSManagedObjectContext *) createContext: (NSPersistentStoreCoordinator *) coordinator
{
    NSManagedObjectContext * context;
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [context setPersistentStoreCoordinator:coordinator];

    return context;
}

+ (NSPersistentStoreCoordinator *) createPersistentStoreCoordinator: (NSManagedObjectModel *)model
{
    bool needMigrate = false;
    bool needDeleteOld  = false;
    
    NSPersistentStoreCoordinator *coordinator;
    
    NSString *kDbName = @"ShiftScheduler.sqlite";
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kDbName];
    
    NSURL *groupURL = [[self applicationGroupDocumentDirectory] URLByAppendingPathComponent:kDbName];
    
    NSURL *targetURL =  nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:[storeURL path]]) {
        NSLog(@"old single app db exist.");
        targetURL = storeURL;
        needMigrate = true;
    }
    
    
    if ([fileManager fileExistsAtPath:[groupURL path]]) {
        NSLog(@"group db exist");
        needMigrate = false;
        targetURL = groupURL;
        
        if ([fileManager fileExistsAtPath:[storeURL path]]) {
            needDeleteOld = true;
        }
    }
    
    if (targetURL == nil)
        targetURL = groupURL;
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                              NSInferMappingModelAutomaticallyOption: @(YES)};
    
    NSError *error = nil;
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    
    NSPersistentStore *store;
    store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:targetURL options:options error:&error];
    
    if (!store)
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // do the migrate job from local store to a group store.
    if (needMigrate) {
        NSError *error = nil;
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [context setPersistentStoreCoordinator:coordinator];
        [coordinator migratePersistentStore:store toURL:groupURL options:options withType:NSSQLiteStoreType error:&error];
        if (error != nil) {
            NSLog(@"Error when migration to groupd url %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return coordinator;
    
}

/**
 Returns the URL to the application's Documents directory.
 */
+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    
}

+ (NSURL *)applicationGroupDocumentDirectory
{
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.kzjeef.shitf.scheduler"];
}




@end
