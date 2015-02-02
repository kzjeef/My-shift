//
//  UIPickerView+DoneButton.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 15/2/1.
//
//

#import "UITableViewCell+DoneButton.h"
#import "I18NStrings.h"

@implementation UITableViewCell (DoneButton)

#define FIELD_POP_TAG 2002

-(void)addModalPickerView:(UIPickerView *)picker
                   target:(id)target done:(SEL)action
{
    UITextField *field;
    field = [[UITextField alloc] initWithFrame:[self bounds]];
    field.tag = FIELD_POP_TAG;
    
    [self.contentView addSubview: field];
    [field setInputView:picker];
    
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];

    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalPickerView)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];


    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, doneButton,nil]];
    
    field.inputAccessoryView = keyboardDoneButtonView;
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
