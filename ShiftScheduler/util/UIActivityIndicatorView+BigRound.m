//
//  UIActivityIndicatorView+BigRound.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-3-7.
//
//

#import "UIActivityIndicatorView+BigRound.h"

@implementation UIActivityIndicatorView (BigRound)


- (void) setupRoundCorner: (NSInteger) viewSize {
    self.frame = CGRectMake(0, 0, viewSize, viewSize);
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.hidesWhenStopped = YES;
}

@end
