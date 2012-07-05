/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

@class KalTileView, KalDate;
@protocol KalViewDelegate;

@interface KalMonthView : UIView
{
    NSUInteger numWeeks;
    id<KalViewDelegate> delegate;  // Assigned.

}

@property (nonatomic) NSUInteger numWeeks;

- (id)initWithFrame:(CGRect)rect delegate:(id<KalViewDelegate>)theDelegate; // designated initializer
- (void)showDates:(NSArray *)mainDates leadingAdjacentDates:(NSArray *)leadingAdjacentDates trailingAdjacentDates:(NSArray *)trailingAdjacentDates;
- (KalTileView *)firstTileOfMonth;
- (KalTileView *)tileForDate:(KalDate *)date;
- (void)markTilesForDates:(NSArray *)dates;

@end
