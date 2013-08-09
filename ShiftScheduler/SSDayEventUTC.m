//
//  SSDayEventUTC.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-7-3.
//
//

#import "SSDayEventUTC.h"

@implementation SSDayEventUTC

@synthesize holidayTextView = _holidayTextView, lunarTextView = _lunarTextView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
