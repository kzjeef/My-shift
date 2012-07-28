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

//#define LOCAL_DEBUG

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
- (int) loginNoteServerSyncWithName:(NSString *)name withPassword:(NSString *)password
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
            return -1;
        } else {
            NSLog(@"TN: login success");
        }
        
    }
    return 0;
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
        return -1;
    }
    
    _noteID = [jsonDict objectForKey:@"message"];
    if (_noteID == nil || _noteID.length == 0) {
        NSLog(@"TN: Failed to post note, no nodeid");
        return -2;
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

- (int) postAttachment: (NSString *)name withData: (NSData *)data
{
    NSURLRequest *request = [self thinknoteAttachmentRequest:name data:data];

    _serverConn = [_serverConn initWithRequest:request delegate:self];

    if (_serverConn != nil) {
       [_recvData setLength:0];
       _status = THINKNOTE_CONN_STATUS_ATT_POST;
    } else {
        NSLog(@"Error: Server Connection Error");
        return -1;
    }

    return 0;
}

- (int) postAttachmoentSync:(NSString *)name withData:(NSData *)data
{
    NSHTTPURLResponse *response;
    NSError *error;

    NSURLRequest *request = [self thinknoteAttachmentRequest:name data:data];
    if (request == nil)
        return -1;
    NSData * returnData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response
                                                            error:&error ];
    
    if (error)
        NSLog(@"error when add attach: %@", error.userInfo);
    
    NSDictionary * jsonDict = [NSJSONSerialization 
                                  JSONObjectWithData:returnData
                                             options:NSJSONReadingMutableLeaves
                                               error:&error];
    
    NSLog(@"post attach got return:%@ response:%d data:%@ error:%@",returnData,
          [response statusCode],
          jsonDict,
          error.userInfo);
    
    NSString *result = [jsonDict objectForKey:@"result"];
    
    if ([result isEqualToString:@"ok"] != YES) {
        NSLog(@"TN: post note failed");
        return -2;
    }
    
    return 0;
}

#pragma mark - Network Async Delegate
// ------------------------------------------------------------
// Network Async Delegate
// --------------------------------------------------------------
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
            NSLog(@"TN: post note failed:%@", result);
        }

        _noteID = [jsonDict objectForKey:@"message"];
        if (_noteID == nil || _noteID.length == 0) {
            NSLog(@"TN: Failed to post note, no nodeid");
        }
    } else if (_status == THINKNOTE_CONN_STATUS_ATT_POST) {
        if ([result isEqualToString:@"ok"] != YES) {
            NSLog(@"TN: post attach failed:%@", result);
        }

        // reset the state to idle
        _status == THINKNOTE_CONN_STATUS_IDLE;
    }
    
    
}

- (void) disconnect
{
    [_serverConn cancel];
}

#pragma mark - Attachment Help Func.

- (NSString *) getContentTypeFromName:(NSString *)name
{
    NSString *contentType;

    if ( [name.pathExtension isEqual:@"png"] ) {
        contentType = @"image/png";
    } else if ( [name isEqual:@"jpg"] ) {
        contentType = @"image/jpeg";
    } else if ( [name isEqual:@"gif"] ) {
        contentType = @"image/gif";
    } else {
        NSAssert(NO, @"not support file name");
        contentType = nil;          // quieten a warning
    }
    return contentType;
}


// This function build all parts into a multiPart data message, 
// it can support one Blob data, and only one.
// the @fileName give the Blob 's file name, use to get the MIME type.
- (NSData *) encodeMultiPartDataWithDict:(NSDictionary *) dict dataFileName:(NSString *) fileName boundary: (NSString *)boundaryStr 
{
    // Calculate the multipart/form-data body.  For more information about the 
    // format of the prefix and suffix, see:
    //
    // o HTML 4.01 Specification
    //   Forms
    //   <http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4>
    //
    // o RFC 2388 "Returning Values from Forms: multipart/form-data"
    //   <http://www.ietf.org/rfc/rfc2388.txt>
    

    NSMutableData *resultData = [NSMutableData data];
    NSString *mimeType;
    NSString *bodyPostfix = nil;
    
    mimeType = [self getContentTypeFromName:fileName];
    
    __block NSMutableData *result_ = resultData;
    
    for (id key in dict) {
        id obj = [dict objectForKey:key];

        NSString *bodyPrefixStr;
        NSData *valueData;


        assert(boundaryStr != nil);

        assert([key isKindOfClass:[NSString class]]);
        NSString *keystr = key;
        NSString *contentType;
        

        if ([obj isKindOfClass:[NSString class]]) {
            contentType = @"text/plain";
            NSString *str = obj;
            valueData = [str dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([obj isKindOfClass:[NSData class]]) {
            contentType = mimeType;
            valueData = obj;
        }
        NSLog(@"encoding: %@ -> %@ --> length:%d", keystr, contentType, result_.length );
        
        
        if ([obj isKindOfClass:[NSString class]])
            bodyPrefixStr = [NSString stringWithFormat:
                                          @
                                      // empty preamble
                                      "\r\n"
                                      "--%@\r\n"
                                  "Content-Disposition: form-data; name=\"%@\"\r\n"
                                         "Content-Type: %@\r\n"
                                      "\r\n",
                                      boundaryStr,
                                      keystr,
                                      contentType
                ];
        else {
            bodyPrefixStr = [NSString stringWithFormat:
                                          @
                                      // empty preamble
                                      "\r\n"
                                      "--%@\r\n"
                                  "Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n"
                                         "Content-Type: %@\r\n"
                                      "\r\n",
                                      boundaryStr,
                                      keystr,
                                      fileName,
                                      contentType
                ];

        }
        assert(bodyPrefixStr != nil);
        [result_ appendData:[bodyPrefixStr dataUsingEncoding:NSUTF8StringEncoding]];
        [result_ appendData:valueData];
        
#if 0
        NSLog(@"%@", bodyPrefixStr);
        NSLog(@"%@", obj);
        if (bodyPostfix)
            NSLog(@"%@", bodyPostfix);
#endif

    } 
        
    // Finish the data transfer by append a end.
    bodyPostfix = [NSString stringWithFormat:
                                @
                            // empty preamble
                            "\r\n"
                            "--%@--\r\n",
                            boundaryStr];
    [result_ appendData:[bodyPostfix dataUsingEncoding:NSUTF8StringEncoding]];

    
    
    return result_;
}

- (NSURLRequest *)thinknoteAttachmentRequest: (NSString *)name data:(NSData *)data
{

    NSData *postBodyData;
    
    NSAssert(_loginToken != nil && [_loginToken length] != 0, @"post note without login!!");
    NSAssert(_noteID != nil, @"attachment can not post before note");
    
    if (_loginToken == nil || [_loginToken length] == 0 || _noteID == 0)
        return nil;
    
    NSString *boundaryStr = [self generateBoundaryString];
    
    NSArray *keys = [NSArray arrayWithObjects:@"appkey",
                             @"token",
                             @"noteId",
                             @"attname",
                             @"attlen",
                             @"attdata",
                             nil];

    NSArray *values = [NSArray arrayWithObjects: TN_APP_KEY,
                               _loginToken,
                               _noteID,
                               name,
                               [NSString stringWithFormat:@"%d",data.length],
                               data,
                               nil];

    NSDictionary *params = [[NSDictionary alloc] initWithObjects:values forKeys:keys];
    
    // generate the post body by this help function.
    postBodyData = [self encodeMultiPartDataWithDict:params dataFileName:name boundary:boundaryStr];

    
    // Open a connection for the URL, configured to POST the file.
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", TN_SITE_URL, TN_ATTACH_URL]];
    
#ifdef LOCAL_DEBUG
    static NSString * kDefaultPostURLText = @"http://localhost:9000/cgi-bin/PostIt.py";
    url = [NSURL URLWithString:kDefaultPostURLText];
#endif

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    assert(request != nil);
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postBodyData];
    
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryStr] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", postBodyData.length] forHTTPHeaderField:@"Content-Length"];
  
#ifdef LOCAL_DEBUG
    NSLog(@"dump the request:%@ ", request);
    NSLog(@"dump request header:%@", request.allHTTPHeaderFields);
    //    NSLog(@"dump request data:%@", request.HTTPBody);
#endif
    return request;
}

- (NSString *)generateBoundaryString
{
    CFUUIDRef       uuid;
    CFStringRef     uuidStr;
    NSString *      result;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSString stringWithFormat:@"%@", uuidStr];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}


@end
