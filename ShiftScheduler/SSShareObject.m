//
//  SSShareObject.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSShareObject.h"
#import "SSAppDelegate.h"
#import "SSShareProfileListViewController.h"
#import "KalViewController.h"
#import "UIImage+CaptureView.h"
#import "I18NStrings.h"

@interface SSShareResult ()
{
    int _result;
    NSString *_failedReason;
}

@end

@implementation SSShareResult

@synthesize result = _result;
@synthesize failedReason = _failedReason;

@end

@interface SSShareController () 
{
    KalViewController *_kal;
    SSAppDelegate *_appDelegate;
    SSShareProfileListViewController *_profileListVC;
    
    UIImage *_shiftCalImage;
    UIImage *_shiftListImage;
    NSString *_shiftThinkNoteStr;
}
@end

@implementation SSShareController


- (id) initWithProfilesVC:(SSShareProfileListViewController *)profilelist
        withKalController:(KalViewController *)kal
{
    self = [super init];
    
    _kal = kal;
    _profileListVC = profilelist;
    
    return self;
}

- (NSString *)shiftOverviewStr
{
    NSString *shiftMonthstr = [_kal selecedMonthNameAndYear];
    
    return [NSString stringWithFormat:@"%@-%@", 
            NSLocalizedString(@"Shift Scheduler", ""),
            shiftMonthstr];
}

- (NSString *)shiftThinkNoteStr
{
    
    if (!_shiftThinkNoteStr) {
        NSString *shiftMonthstr = [_kal selecedMonthNameAndYear];
        NSString *template = NSLocalizedString(@"My shift schedule at %@, the following images are shift calendar and shift profile.", "shift Str of think Note");
        _shiftThinkNoteStr =  [NSString stringWithFormat:template,
                               shiftMonthstr];
    }
    return _shiftThinkNoteStr;
        
}

- (NSString *) shiftDetailEmailStr
{
    /* Hi, <p> I want to share you with my shift schedule, here is my shift schedule at %@, you can check the shift of this month by attachment: \"%@\", and each shift's work time by attachment: \"%@\". <p> <p> About Shift Sheduler：<a href='http://itunes.apple.com/en/app//id482061308?mt=8'>Click Here</a>
     */
    NSString *emailBody = NSLocalizedString(@"__SHARE_EMAIL_BODY_STRINGS__", "email body in share object");
    
    NSString *shiftMonthstr = [_kal selecedMonthNameAndYear];
    
    return [NSString stringWithFormat:emailBody,
            shiftMonthstr,
            NSLocalizedString(@"Shift Scheduler", ""),
            self.shiftListImageName];
    
}

+ (UIImage*) addStarToThumb:(UIImage*)thumb
{
   CGSize size = CGSizeMake(50, 50);
   UIGraphicsBeginImageContext(size);

   CGPoint thumbPoint = CGPointMake(0, 25 - thumb.size.height / 2);
   [thumb drawAtPoint:thumbPoint];

   UIImage* starred = [UIImage imageNamed:@"starred.png"];

   CGPoint starredPoint = CGPointMake(0, 0);
   [starred drawAtPoint:starredPoint];

   UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();

   return result;
}

- (NSString *) timedate {
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    return [formatter stringFromDate:[NSDate date]];
}

- (UIImage *) shiftCalendarWithListImage {

    UIImage *imageCalendar = [self shiftCalendarSnapshot];
    UIImage *imageList = [self shiftListImage];
    CGSize calSize = imageCalendar.size;
    
    int gap = 20;
    int calendarHeightOffset = [_kal tableViewWhiteHeight];
  
    CGSize size = imageCalendar.size;
    size.height += imageList.size.height;

    calSize.height -= calendarHeightOffset;
    size.height -= calendarHeightOffset;

    int textHeight, textWidth;
    NSString *copyright = [NSString stringWithFormat:@"%@ @ %@", APP_NAME_STR, APP_URL];
    if ([copyright respondsToSelector:@selector(sizeWithAttributes:)]) {
        textHeight = [copyright sizeWithAttributes:nil].height;
        textWidth = [copyright sizeWithAttributes:nil].width;
        
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        textHeight = [copyright sizeWithFont:[UIFont systemFontOfSize:UIFont.systemFontSize]].height;
        textWidth = [copyright sizeWithFont:[UIFont systemFontOfSize:UIFont.systemFontSize]].width;
#pragma clang diagnostic pop
    }
    NSString * timestr = [self timedate];
    
    size.height += 2 * textHeight;
    size.height += gap;

    UIGraphicsBeginImageContextWithOptions(size, 0, 0.0);
  
    [imageCalendar drawInRect:CGRectMake(0, 0, calSize.width, imageCalendar.size.height )];

    [imageList drawInRect:CGRectMake(0, calSize.height, imageList.size.width, imageList.size.height)];
    
    if ([copyright respondsToSelector:@selector(drawAtPoint:withAttributes:)]) {
        [copyright drawAtPoint:CGPointMake(size.width - textWidth, size.height -  (2 * textHeight)) withAttributes:nil];
        [timestr drawAtPoint:CGPointMake(size.width - [timestr sizeWithAttributes:nil].width, (size.height - textHeight)) withAttributes:nil];
    }

    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
  
    UIGraphicsEndImageContext();  
  
    return resultingImage;  
}

- (UIImage *)shiftCalendarSnapshot {
    return [self shiftCalImage];
}

- (UIImage *)shiftCalImage
{
    UIImage *image = [_kal captureCalendarView];
    if (!image) {
        NSLog(@"shift Cal image generate failed\n");
        return nil;
    }

    return image;
}

- (NSString *) shiftCalImageName
{
    NSString *shiftMonthstr = [_kal selecedMonthNameAndYear];

    return [NSString stringWithFormat:@"%@ @ %@.%@", 
            NSLocalizedString(@"Shift Scheduler", ""),
                     shiftMonthstr, @"jpg"];
}

- (UIImage *) shiftListImage
{
    NSAssert(_profileListVC != nil, @"shareProfileViewController == nil");
    UIImage *listImage = [UIImage imageWithView:_profileListVC.tableView size:_profileListVC.tableView.contentSize];
    _shiftListImage = listImage;
    return _shiftListImage;
}

- (NSString *) shiftListImageName
{
    return [NSString stringWithFormat:@"%@.%@", 
                     NSLocalizedString(@"Shift-On-Off Time", "on-off time in mail attachment"),
                     @"jpg"];
}
- (void) invaildCache
{
    _shiftCalImage = nil;
    _shiftListImage = nil;
    _shiftThinkNoteStr = nil;
    
}

@end
