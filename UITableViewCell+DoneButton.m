//
//  UIPickerView+DoneButton.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/2/1.
//
//

#import "UITableViewCell+DoneButton.h"
#import "I18NStrings.h"

//隐藏掉光标， 这样看不出来是一个TextField.
@implementation UIHideCurosrTextField
- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
}
@end

@implementation UITableViewCell (DoneButton)


- (void)addTitleButtons:(SEL)action target:(id)target tag:(int)tag field:(UITextField *)field
{
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
    doneButton.tag = tag;
    // 使用这个tag来判断是否是哪个地方点下。
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalPickerView)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, doneButton,nil]];
    
    field.inputAccessoryView = keyboardDoneButtonView;
}


-(void)addModalPickerView:(UIPickerView *)picker
                   target:(id)target done:(SEL)action tag:(int) tag
{
    UIHideCurosrTextField *field;
    field = [[UIHideCurosrTextField alloc] initWithFrame:[self bounds]];
    field.tag = FIELD_POP_TAG;
    
    [self.contentView addSubview: field];
    [field setInputView:picker];
    
    [self addTitleButtons:action target:target tag:tag field:field];
}

-(void)addModalDatePickerView:(UIDatePicker *)picker
                   target:(id)target done:(SEL)action tag:(int) tag
{
    UIHideCurosrTextField *field;
    field = [[UIHideCurosrTextField alloc] initWithFrame:[self bounds]];
    field.tag = FIELD_POP_TAG;
    
    [self.contentView addSubview: field];
    [field setInputView:picker];
    
    [self addTitleButtons:action target:target tag:tag field:field];
}


- (void) dismissModalPickerView
{
    UIView *v = [self.contentView viewWithTag:FIELD_POP_TAG];
    if (v != nil && [v isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *) v;
        if ([field isFirstResponder])
            [field resignFirstResponder];
    }
}

@end
