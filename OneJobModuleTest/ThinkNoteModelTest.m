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
    int ret =    [_ntController loginNoteServerSyncWithName:@"zhangjeef@gmail.com" withPassword:@"123456"];
    STAssertTrue(ret == 0 , @"login failed");
}

- (void) testThinkNotePostNote
{
    int ret;
    
    ret = [_ntController loginNoteServerSyncWithName:@"zhangjeef@gmail.com" withPassword:@"123456"];
    STAssertTrue(ret == 0, @"login failed");

    ret = [_ntController postNoteOnServerSync:@"Test1" note:@"Test 2"];
    STAssertTrue(ret == 0, @"post note failed: ret:%d", ret);
}

@end
