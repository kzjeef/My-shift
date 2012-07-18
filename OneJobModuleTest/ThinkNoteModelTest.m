//
//  ThinkNoteModelTest.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-18.
//  Copyright (c) 2012年 RealLifeSoftware.llc. All rights reserved.
//

#import "ThinkNoteModelTest.h"
#import "SSThinkNoteShareAgent.h"

@implementation ThinkNoteModelTest

- (void) setUp
{
    [super setUp];
    
    _ntController = [[SSThinkNoteController alloc] init];
}

- (void) testThinkNoteLogin
{
    [_ntController loginNoteServerSyncWithName:@"zhangjeef@gmail.com" withPassword:@"123456"];
}

- (void) testThinkNotePostNote
{
    [_ntController loginNoteServerSyncWithName:@"zhangjeef@gmail.com" withPassword:@"123456"];

    [_ntController postNoteOnServerSync:@"Test1" note:@"Test 2"];
}

@end
