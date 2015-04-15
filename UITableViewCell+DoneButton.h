//
//  UIPickerView+DoneButton.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/2/1.
//
//

#import <UIKit/UIKit.h>

#define FIELD_POP_TAG 2002

@interface UIHideCurosrTextField : UITextField
@end

@interface UITableViewCell (DoneButton)

-(void)addModalPickerView:(UIPickerView *)picker
                   target:(id)target done:(SEL)action tag:(int) tag;

-(void)addModalDatePickerView:(UIDatePicker *)picker
                   target:(id)target done:(SEL)action tag:(int) tag;

- (void) dismissModalPickerView;


@end
