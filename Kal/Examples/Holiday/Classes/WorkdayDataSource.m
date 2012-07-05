//
//  WorkdayDataSource.m
//  Holiday
//
//  Created by Zhang Jiejing on 11-10-1.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "WorkdayDataSource.h"

@implementation WorkdayDataSource

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

#pragma mark UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}


#pragma mark KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
    [delegate loadedDataSource:self];
}

#define ONE_DAY_SECONDS (60*60*24)
#define HALF_DAY_SECONDS (60*60*12)
- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
    return [NSArray arrayWithObjects: [NSDate date], [NSDate dateWithTimeIntervalSinceNow: HALF_DAY_SECONDS], nil];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    
}
- (void)removeAllItems
{
    
}

@end
