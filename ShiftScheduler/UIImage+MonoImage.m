//
//  UIImage+MonoImage.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-2-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "UIImage+MonoImage.h"

@implementation UIImage (MonoImage)

+ (UIImage *) generateMonoImage: (UIImage *)icon withColor:(UIColor *)color
{
    UIImage *finishImage;
    CGImageRef alphaImage = CGImageRetain(icon.CGImage);
    CGColorRef colorref = CGColorRetain(color.CGColor);
    
    UIGraphicsBeginImageContext(icon.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGRect imageArea = CGRectMake (0, 0,
                                   icon.size.width, icon.size.height);
    
    // Don't know why if I don't translate the CTM, the image will be a *bottom* up
    // aka, head on bottom shape, so I need use TranlateCTM and ScaleCTM to let
    // all y-axis to be rotated.
    CGFloat height = icon.size.height;
	CGContextTranslateCTM(ctx, 0.0, height);
	CGContextScaleCTM(ctx, 1.0, -1.0);
    
    CGContextClipToMask(ctx, imageArea , alphaImage);
    
    CGContextSetFillColorWithColor(ctx, colorref);
    CGContextFillRect(ctx, imageArea);
    CGImageRelease(icon.CGImage);
    CGColorRelease(color.CGColor);
    
    finishImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finishImage;
}


@end
