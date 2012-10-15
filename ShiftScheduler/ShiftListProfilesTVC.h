//
//  ProfilesViewController.h
//  
//
//  Created by Zhang Jiejing on 11-10-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OneJob.h"

@class ShiftProfileChangeViewController;

@protocol ProfileViewDelegate
- (void) didChangeProfile:(ShiftProfileChangeViewController *) addController
        didFinishWithSave:(BOOL) finishWithSave;
@end

@protocol ProfileEditFinishDelegate
- (void) didFinishEditingSetting;
@end


@interface ShiftListProfilesTVC : UITableViewController <NSFetchedResultsControllerDelegate, ProfileViewDelegate>
{
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectContext *addingManagedObjectContext;
    NSFetchedResultsController *fetchedResultsController;
    UIBarButtonItem *addButton;
    UIImage *plusImage;
    NSDateFormatter *timeFormatter;
    id <ProfileEditFinishDelegate> parentViewDelegate;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext *addingManagedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) NSDateFormatter *timeFormatter;

@property (strong, nonatomic) id <ProfileEditFinishDelegate> parentViewDelegate;

- (id)initWithManagedContext:(NSManagedObjectContext *)context;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath ;
- (IBAction)insertNewProfile:(id) sender;
- (NSInteger) profileuNumber;

@end


