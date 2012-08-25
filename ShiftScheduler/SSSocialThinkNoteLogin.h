//
//  SSSocialThinkNoteLogin.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-8-18.
//
//

#import <Foundation/Foundation.h>

@interface SSSocialThinkNoteLogin : NSObject <UIAlertViewDelegate>

#define kThinkNoteLoginName @"ThinkNoteLoginName"
#define kThinkNoteLoginPassword @"ThinkNoteLoginPassword"
#define LOGIN_STR  NSLocalizedString(@"Login", "login")
#define REGISTER_STR  NSLocalizedString(@"Register", "register a new account for thinknote")

#define SSSocialAccountChangedNotification @"SSSocialAccountChangedNotification"

- (void)        showThinkNoteLoingView;

- (NSString *)  getUserName;
- (NSString *)  getPasswd;


@end
