/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>
#import "KalView.h"

enum {
  KalTileTypeRegular   = 0,
  KalTileTypeAdjacent  = 1 << 0,
  KalTileTypeToday     = 1 << 1,
};
typedef char KalTileType;


@class KalDate;
@protocol KalViewDelegate;

@interface KalTileView : UIView
{
  KalDate *date;
  id<KalViewDelegate> delegate;  // Assigned.
  CGPoint origin;
    unsigned int holiday;

  struct {
    unsigned int selected : 1;
    unsigned int highlighted : 1;
    unsigned int marked : 1;
    unsigned int type : 2;
  } flags;
}

@property (nonatomic, strong) KalDate *date;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isMarked) BOOL marked;
@property (nonatomic) KalTileType type;

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate;
- (void)resetState;
- (BOOL)isToday;
- (BOOL)belongsToAdjacentMonth;

@end
