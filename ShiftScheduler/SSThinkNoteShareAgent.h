//
//  SSThinkNoteShareAgent.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSShareObject.h"

@class SSShareResult;

@class SSShareController;

@protocol SSThinkNoteControllerDelegate <NSObject>

- (void) thinkNoteServerUpdateState: (int) state error: (NSError *) error;

@end


@interface SSThinkNoteShareAgent : NSObject <SSThinkNoteControllerDelegate>

- (id) initWithSharedObject: (SSShareController *)shareC;
- (void) composeThinkNoteWithNagvagation: (UINavigationController *)nvc
                               withBlock: (ComposeShareViewCompleteHander) block;
- (void) thinkNoteServerUpdateState: (int) state error: (NSError *) error;

@end

enum {
    THINKNOTE_CONN_STATUS_IDLE = 1,
    THINKNOTE_CONN_STATUS_LOGIN,
    THINKNOTE_CONN_STATUS_NOTE_POST,
    THINKNOTE_CONN_STATUS_ATT_POST,
};


@interface SSThinkNoteController : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    int _status;
    NSString *_loginToken;
    NSString *_noteID;
    // Attachement is NSDirectory with name & data. 
    // after flush, clear the array.
    NSArray *_attachments;
    NSMutableData *_recvData;
    NSURLConnection *_serverConn;
    
    __unsafe_unretained id <SSThinkNoteControllerDelegate> _connectDelegate;
}

@property (assign) id <SSThinkNoteControllerDelegate> connectDelegate;

- (int) loginNoteServerSyncWithName:(NSString *)name withPassword:(NSString *)password;
- (void) loginNoteServerWithName: (NSString *) name 
                    withPassword: (NSString *) password;

- (int) postNoteOnServer: (NSString *) title note: (NSString *)note;
- (int) postNoteOnServerSync: (NSString *) title note: (NSString *)note;

//- (int) flushNoteCache;

- (int) postAttachment: (NSString *)name withData: (NSData *)data;
- (int) postAttachmoentSync: (NSString *)name withData: (NSData *)data;

- (void) disconnect;

@end
