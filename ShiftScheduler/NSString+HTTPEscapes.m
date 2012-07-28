//
//  NSString+HTTPEscapes.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-18.
//  Copyright (c) 2012年 RealLifeSoftware.llc. All rights reserved.
//

#import "NSString+HTTPEscapes.h"

@implementation NSString (HTTPEscapes)

+ (NSString *) stringEncodeEscape: (NSString *)string
{
    CFStringRef originalString = (__bridge CFStringRef) string;
    
    CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(
                                                                        kCFAllocatorDefault,
                                                                        originalString,
                                                                        NULL,
                                                                        CFSTR(":/?#[]@!$&'()*+,;="),
                                                                        kCFStringEncodingUTF8);
    NSString * ret = (__bridge NSString *)encodedString;
    CFRelease(encodedString);
    return ret;
}

+ (NSString *) stringDecodeEscape: (NSString *)string
{
    CFStringRef encodeString = (__bridge CFStringRef) string;
    CFStringRef decodedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                                        kCFAllocatorDefault,
                                                                                        encodeString,
                                                                                        CFSTR(""),
                                                                                        kCFStringEncodingUTF8);
    
    NSString *ret =  (__bridge NSString *)decodedString;
    CFRelease(decodedString);
    return ret;
}
@end
