//
//  UIImage+Blur.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-10-20.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Blur)
- (UIImage *)imageWithBlurredCircleWithCenter:(CGPoint)center radius:(CGFloat)circleRadius blur:(CGFloat)blurRadius luminosity:(CGFloat)luminosity;
@end
