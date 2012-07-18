//
//  SSThinkNoteShareAgent.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSThinkNoteShareAgent.h"
#import "SSShareObject.h"
#import "NSString+HTTPEscapes.h"

@interface SSThinkNoteShareAgent()
{
    SSShareController *_shareC;
}

@end

@implementation SSThinkNoteShareAgent

- (id) initWithSharedObject:(SSShareController *)shareC
{
    self = [super init];
    _shareC = shareC;
    return self;
}

- (void) composeThinkNoteWithNagvagation:(UINavigationController *)nvc withBlock:(ComposeShareViewCompleteHander)block
{
    // 0. start a block.
    
    // 1. first login with user/password.
    // 2. then parser the result JSON, got the "token"
    // 3. call "addnote" function, and post the shareController 's note text.
    // 4. got the "noteid"
    // 5. post the attachment with 2 pictures with "noteid"
    // 6. close the connection.
}
@end

@implementation SSThinkNoteController

@synthesize connectDelegate = _connectDelegate;

#define TN_APP_KEY @"7F4E06A130880A10A8E2D7B3AC37CCF9"
#define TN_SITE_URL @"http:www.qingbiji.cn"
#define TN_LOGIN_URL @"/open/login"
#define TN_ADDNOTE_URL @"/open/addnote"
#define TN_ATTACH_URL @"/open/addattach"
#define TN_GETNOTE_URL @"/open/getnote"

// sync interface for testcase
- (void) loginNoteServerSyncWithName:(NSString *)name withPassword:(NSString *)password
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", TN_SITE_URL, TN_LOGIN_URL]]];
    

     NSString *requestData = [NSString stringWithFormat:@"appkey=%@&username=%@&password=%@",
                              TN_APP_KEY, name, password];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSData dataWithBytes:[requestData UTF8String]
                                        length:[requestData length]]];
 
    NSURLResponse *response;
    NSError *error;
    NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];

#ifdef DEBUG
    NSLog(@"request: %@ reponse:%@", request, response);
#endif
    NSDictionary * jsonDict = [NSJSONSerialization 
                               JSONObjectWithData:data
                               options:NSJSONReadingMutableLeaves
                               error:&error];
#ifdef DEBUG
    NSLog(@"ThinkNote-Login: got data:%@", jsonDict);
#endif
    
    _status = THINKNOTE_CONN_STATUS_LOGIN;
    
    
    if (_status == THINKNOTE_CONN_STATUS_LOGIN) {
        NSString *result = [jsonDict objectForKey:@"result"];
        _loginToken = [NSString stringWithString: [jsonDict objectForKey:@"token"]];
        // the result not ok, and not get the login token, failed.
        if ((![result isEqualToString:@"ok"]) || _loginToken == nil) {
            NSLog(@"TN: login failed");
        } else {
            NSLog(@"TN: login success");
        }
        
    }
}

//- (void) postNoteServerWithNotesSync

- (void) loginNoteServerWithName:(NSString *) name withPassword:(NSString *)password
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: 
                                    [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", TN_SITE_URL, TN_LOGIN_URL]]];
    
    
    NSString *requestData = [NSString stringWithFormat:@"appkey=%@&username=%@&password=%@",
                             TN_APP_KEY, name, password];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSData dataWithBytes:[requestData UTF8String]
                                        length:[requestData length]]];

    _serverConn = [[NSURLConnection alloc] 
                                initWithRequest:request delegate:self];
    if (_serverConn) {
        _status = THINKNOTE_CONN_STATUS_LOGIN;
        _recvData = [NSMutableData data];
    } else {
        _status = THINKNOTE_CONN_STATUS_IDLE;
        NSLog(@"login failed\n");
    }
}

- (int) postNoteOnServerSync: (NSString *) title note: (NSString *)note
{

    NSAssert(_loginToken != nil && [_loginToken length] != 0, @"post note without login!!");
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: 
                                    [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", TN_SITE_URL, TN_ADDNOTE_URL]]];
    
    
    NSString *requestData = [NSString stringWithFormat:@"appkey=%@&token=%@&title=%@&content=%@&folderId=%d",
                             TN_APP_KEY, 
                             _loginToken,
                             [NSString stringEncodeEscape:title],
                             [NSString stringEncodeEscape:note],
                             0];
    [request setHTTPMethod:@"POST"];
    
    NSMutableData *body = [NSMutableData dataWithBytes:[requestData UTF8String]
                                  length:[requestData length]];
    [request setHTTPBody:body];
    
    NSURLResponse *response;
    NSError *error;

    NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];

    NSDictionary * jsonDict = [NSJSONSerialization 
                               JSONObjectWithData:data
                               options:NSJSONReadingMutableLeaves
                                            error:&error];
    
    NSLog(@"got data:%@", jsonDict);
    
    NSString *result = [jsonDict objectForKey:@"result"];

    if ([result isEqualToString:@"ok"] != YES) {
        NSLog(@"TN: post note failed");
    }
    
    _noteID = [jsonDict objectForKey:@"noteid"];
    if (_noteID == nil || _noteID.length == 0) {
        NSLog(@"TN: Failed to post note, no nodeid");
    }
    
    return 0;
}

- (int) postNoteOnServer: (NSString *) title note: (NSString *)note
{
    NSAssert(_loginToken != nil && [_loginToken length] != 0, @"post note without login!!");
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: 
                                    [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", TN_SITE_URL, TN_ADDNOTE_URL]]];
    
    
    NSString *requestData = [NSString stringWithFormat:@"appkey=%@&token=%@&title=%@&content=%@&folderId=%@",
                             TN_APP_KEY, 
                             _loginToken,
                             [NSString stringEncodeEscape:title],
                             [NSString stringEncodeEscape:note],
                             [NSNumber numberWithInt:0]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSData dataWithBytes:[requestData UTF8String]
                                        length:[requestData length]]];

    
    _serverConn = [_serverConn initWithRequest:request delegate:self];
    
    if (_serverConn != 0) {
        [_recvData setLength:0];
        _status = THINKNOTE_CONN_STATUS_NOTE_POST;
    } else {
        NSLog(@"Error: Server Connection Error");
    }
    
    return 0;
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"got response:%@", response);
    [_recvData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSError *error;
    NSDictionary * jsonDict = [NSJSONSerialization 
                               JSONObjectWithData:data
                               options:NSJSONReadingMutableLeaves
                                            error:&error];
    
    NSLog(@"got data:%@", jsonDict);
    
    NSString *result = [jsonDict objectForKey:@"result"];
    
    if (_status == THINKNOTE_CONN_STATUS_LOGIN) {

        _loginToken = [jsonDict objectForKey:@"token"];
        
        // the result not ok, and not get the login token, failed.
        if ((![result isEqualToString:@"ok"]) || _loginToken == nil) {
            NSLog(@"TN: login failed");
        } else {
            NSLog(@"TN: login success");
        }
        // call some delegate the login success
    } else if (_status == THINKNOTE_CONN_STATUS_NOTE_POST) {
        if ([result isEqualToString:@"ok"] != YES) {
            NSLog(@"TN: post note failed");
        }

        _noteID = [jsonDict objectForKey:@"noteid"];
        if (_noteID == nil || _noteID.length == 0) {
            NSLog(@"TN: Failed to post note, no nodeid");
        }
    }
    
    
}


- (void) disconnect
{
    [_serverConn cancel];
}

@end
