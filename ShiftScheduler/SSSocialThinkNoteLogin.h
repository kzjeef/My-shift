//
//  SSSocialThinkNoteLogin.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-8-18.
//
//

#import <Foundation/Foundation.h>

@interface SSSocialThinkNoteLogin : NSObject <UIAlertViewDelegate>

#define SSSocialAccountChangedNotification @"SSSocialAccountChangedNotification"

- (void)        showThinkNoteLoingView;

- (NSString *)  getUserName;
- (NSString *)  getPasswd;


@end
