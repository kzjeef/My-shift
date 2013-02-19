//
//  KalDelegate.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 11-11-15.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SSKalDelegate.h"
#import "SCModalPickerView.h"
#import "NSDateAdditions.h"

@interface SSKalDelegate()
{
    SCModalPickerView *_modalDatePickerView;
    UIDatePicker *_datePicker;
}

@property (strong, readonly) UIDatePicker *datePicker;
@property (strong, readonly) SCModalPickerView *modalDatePickerView;
@end

@implementation SSKalDelegate

#pragma mark - KalViewControllerDelegate protocol.
- (void) KalViewController:(KalViewController *)sender selectDate:(NSDate *)date
{
}

- (UIDatePicker *)datePicker
{
    if (!_datePicker) {
        _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 250, 325, 250)];
        CGSize pickerSize = [_datePicker sizeThatFits:CGSizeZero];
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
        CGRect pickerRect = CGRectMake(0.0, screenRect.origin.y + screenRect.size.height - pickerSize.height - 65, pickerSize.width, pickerSize.height);
        _datePicker.frame = pickerRect;
        [_datePicker setDatePickerMode:UIDatePickerModeDate];
    }

    return _datePicker;
}

- (SCModalPickerView *)modalDatePickerView
{
    if (!_modalDatePickerView) {
        _modalDatePickerView = [[SCModalPickerView alloc] init];
    }

    return _modalDatePickerView;
}

- (void) KalViewControllerdidSelectTitle:(KalViewController *)sender
{

    [self.modalDatePickerView setPickerView:self.datePicker];
    [self.modalDatePickerView setPickerView:self.datePicker];
    __weak UIDatePicker *pdatePicker = self.datePicker;
    [self.modalDatePickerView setCompletionHandler:^(SCModalPickerViewResult result) {
            if (result == SCModalPickerViewResultDone) {
                dispatch_async(dispatch_get_main_queue(), ^{
                        [sender showAndSelectDate:[pdatePicker.date cc_dateByMovingToMiddleOfDay]];
                    });
            }
        }];

    [self.modalDatePickerView show];
}

#pragma mark UITableViewDelegate protocol conformance

// Display a details screen for the selected holiday/row.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
