//
//  KalDelegate.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 11-11-15.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SSKalDelegate.h"
#import "NSDateAdditions.h"
#import "UITableViewCell+DoneButton.h"


@interface SSKalDelegate()
{
    UIDatePicker *_datePicker;
    KalViewController *_controller;
    UIHideCurosrTextField *_titleField;
}

@property (strong, readonly) UIDatePicker *datePicker;
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

- (void) DateTitleSelected:(id)sender
{
    [self dismissModalPickerView:nil];
    [_controller showAndSelectDate:[self.datePicker.date cc_dateByMovingToMiddleOfDay]];
    

}

- (void) dismissModalPickerView: (id) sender
{
    if (_titleField) {
        if ([_titleField isFirstResponder])
            [_titleField resignFirstResponder];
    }
}

- (void) KalViewControllerdidSelectTitle:(KalViewController *)sender titleView:(UIView *)titleView
{
    static int FIELD_TAG = 5991;
    _controller = sender;
    [SSTrackUtil logEvent:kLogEventPopDateChoose];
    if ([titleView viewWithTag:FIELD_TAG] == nil) {
        // create the view.
        UIHideCurosrTextField *field;
        field = [[UIHideCurosrTextField alloc] initWithFrame:[titleView bounds]];
//        field.tag = FIELD_POP_TAG;
        [titleView addSubview: field];
        [field setInputView: self.datePicker];
        UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
        keyboardDoneButtonView.translucent = YES;
        keyboardDoneButtonView.tintColor = nil;
        [keyboardDoneButtonView sizeToFit];
        
        UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(DateTitleSelected:)];
        UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalPickerView:)];

        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, doneButton,nil]];

        field.inputAccessoryView = keyboardDoneButtonView;
        [field setTag:FIELD_TAG];
        
        _titleField = field; // TODO: cache a pointer here is dirty hack...
        [field becomeFirstResponder];
    } else {
        UIHideCurosrTextField *field;
        field = (UIHideCurosrTextField *)[titleView viewWithTag:FIELD_TAG];
        [field becomeFirstResponder];
    }
}

#pragma mark UITableViewDelegate protocol conformance

// Display a details screen for the selected holiday/row.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
