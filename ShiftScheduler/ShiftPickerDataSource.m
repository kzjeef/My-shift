//
//  ShiftPickerView.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 11-12-8.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ShiftPickerDataSource.h"
#import "OneJob.h"

@implementation ShiftPickerViewDataSource

@synthesize  fetchResults;


- (NSArray *) fetchResults
{
    if (fetchResults)
        return fetchResults;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneJob" inManagedObjectContext:managedcontext];
    [request setEntity:entity];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"jobName"  ascending:YES]];
    
    request.predicate = nil;
    request.fetchBatchSize = 20;
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] 
                                       initWithFetchRequest:request
                                       managedObjectContext:managedcontext
                                       sectionNameKeyPath:@"jobName" 
                                       cacheName:Nil];
    NSError *error;
    
    [frc performFetch:&error];

    fetchResults = [frc.fetchedObjects copy];    
    return fetchResults;
}


- initWithContext:(NSManagedObjectContext *)context
{
    managedcontext = context;

    return self;
}

- (NSInteger) count
{
    return self.fetchResults.count;
}

- (OneJob *) retrunOneJob
{
    return [self.fetchResults lastObject];
}

- (OneJob *) returnJobAt:(NSInteger) n
{
    OneJob *job = [fetchResults objectAtIndex:n];
    return job;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat componentWidth = 0.0;
    
    componentWidth = 40.0;	// first column size is wider to hold names
    return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [fetchResults count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

@end
