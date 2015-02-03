//
//  UIPickerView+DoneButton.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/2/1.
//
//

#import <UIKit/UIKit.h>

@interface UITableViewCell (DoneButton)

-(void)addModalPickerView:(UIPickerView *)picker
                   target:(id)target done:(SEL)action tag:(int) tag;

-(void)addModalDatePickerView:(UIDatePicker *)picker
                   target:(id)target done:(SEL)action tag:(int) tag;

- (void) dismissModalPickerView;

@end
