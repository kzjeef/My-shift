/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@class KalGridView, KalLogic, KalDate;
@protocol KalViewDelegate, KalDataSourceCallbacks;

/*
 *    KalView
 *    ------------------
 *
 *    Private interface
 *
 *  As a client of the Kal system you should not need to use this class directly
 *  (it is managed by KalViewController).
 *
 *  KalViewController uses KalView as its view.
 *  KalView defines a view hierarchy that looks like the following:
 *
 *       +-----------------------------------------+
 *       |                header view              |
 *       +-----------------------------------------+
 *       |                                         |
 *       |                                         |
 *       |                                         |
 *       |                 grid view               |
 *       |             (the calendar grid)         |
 *       |                                         |
 *       |                                         |
 *       +-----------------------------------------+
 *       |                                         |
 *       |           table view (events)           |
 *       |                                         |
 *       +-----------------------------------------+
 *
 */
@protocol KalTileIconDelegate;
@interface KalView : UIView
{
  UILabel *headerTitleLabel;
  KalGridView *gridView;
  UIView *headerView;
  UITableView *tableView;
  UIImageView *shadowView;
  id<KalViewDelegate> __unsafe_unretained delegate;
  KalLogic *logic;
  NSMutableArray *weekdayLabels;
}

@property (nonatomic, unsafe_unretained) id<KalViewDelegate> delegate;
@property (nonatomic, readonly) UITableView *tableView;
@property (unsafe_unretained, nonatomic, readonly) KalDate *selectedDate;


- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)delegate logic:(KalLogic *)logic;
- (void)refreshWeekdayLabel:(BOOL) sunDayStart;
- (BOOL)isSliding;
- (void)selectDate:(KalDate *)date;
- (void)markTilesForDates:(NSArray *)dates;
- (void)redrawEntireMonth;

// These 3 methods are exposed for the delegate. They should be called 
// *after* the KalLogic has moved to the month specified by the user.
- (void)slideDown;
- (void)slideUp;
- (void)jumpToSelectedMonth;    // change months without animation (i.e. when directly switching to "Today")

@end

#pragma mark -

@class KalDate;
@class KalTileView;

@protocol KalViewDelegate

- (void)showPreviousMonth;
- (void)showFollowingMonth;
- (void)didSelectDate:(KalDate *)date;
- (void)didSelectTitle:(UIView *) hitView;

- (NSArray *) KalTileDrawDelegate: (KalTileView *) sender getIconDrawInfoWithDate: (NSDate *) date;

@end
