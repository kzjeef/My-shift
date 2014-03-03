//
//  UISwitch+AdjustForTableViewCell.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-2-22.
//
//

#import "UISwitch+AdjustForTableViewCell.h"

@implementation UISwitch (AdjustForTableViewCell)

- (void) adjustFrameForTableViewCell: (UITableViewCell *)cell
{
  CGSize switchSize = [self sizeThatFits:CGSizeZero];
  self.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 5.0f,
                          (cell.contentView.bounds.size.height - switchSize.height) / 2.0f,
                          switchSize.width,
                          switchSize.height);
  
  self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
}

@end
