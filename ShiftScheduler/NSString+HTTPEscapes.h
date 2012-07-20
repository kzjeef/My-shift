//
//  NSString+HTTPEscapes.h
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-18.
//  Copyright (c) 2012年 RealLifeSoftware.llc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HTTPEscapes)

+ (NSString *) stringEncodeEscape: (NSString *)string;
+ (NSString *) stringDecodeEscape: (NSString *)string;

@end
