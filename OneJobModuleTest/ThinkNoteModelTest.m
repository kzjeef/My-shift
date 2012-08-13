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
    

}

- (void) testThinkNoteLogin
{
    
    SSThinkNoteController *_ntController;

    
    _ntController = [[SSThinkNoteController alloc] init];
    
    int ret =    [_ntController loginNoteServerSyncWithName:@"kzjeef@gmail.com" withPassword:@"123456"];
    STAssertTrue(ret == 0 , @"login failed");
    [_ntController disconnect];
}

- (void) testThinkNotePostNote
{
    int ret;
    
    SSThinkNoteController *_ntController;


    _ntController = [[SSThinkNoteController alloc] init];
    
    ret = [_ntController loginNoteServerSyncWithName:@"kzjeef@gmail.com" withPassword:@"123456"];
    STAssertTrue(ret == 0, @"login failed");

    ret = [_ntController postNoteOnServerSync:@"Test1" note:@"Test 2"];
    STAssertTrue(ret == 0, @"post note failed: ret:%d", ret);
    
    [_ntController disconnect];
}

- (void) testThinkNoteAddAttachment
{
    int ret;
    
    SSThinkNoteController *_ntController;

    
    _ntController = [[SSThinkNoteController alloc] init];
    
    ret = [_ntController loginNoteServerSyncWithName:@"kzjeef@gmail.com" withPassword:@"123456"];
    STAssertTrue(ret == 0, @"login failed");
    
    ret = [_ntController postNoteOnServerSync:@"Test1" note:@"Test 2"];
    STAssertTrue(ret == 0, @"post note failed: ret:%d", ret);

    NSLog(@"post note finished");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"Default" ofType:@"png"];

    NSData *imageData1 = [NSData dataWithContentsOfFile:path];
    
    STAssertTrue([imageData1 length] > 0, @"image data failed to get");
    
    ret = [_ntController postAttachmoentSync:@"Default.png" withData:imageData1];
    
    STAssertTrue(ret == 0, @"post attach failed: ret:%d", ret);
    
    [_ntController disconnect];
    
}

@end
