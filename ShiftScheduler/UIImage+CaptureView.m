//
//  UIImage+CaptureView.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "UIImage+CaptureView.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage (CaptureView)

+ (UIImage *) imageWithView:(UIView *)view
{
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
