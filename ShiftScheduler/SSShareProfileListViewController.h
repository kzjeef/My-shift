//
//  SSShareProfileListViewController.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OneJob.h"
@interface SSShareProfileListViewController : UITableViewController
<NSFetchedResultsControllerDelegate>
{
NSManagedObjectContext *managedObjectContext;
NSFetchedResultsController *fetchedResultsController;
NSDateFormatter *timeFormatter;

}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSDateFormatter *timeFormatter;

- (id)initWithManagedContext:(NSManagedObjectContext *)context;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end
