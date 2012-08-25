//
//  SSSocialThinkNoteLogin.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-8-18.
//
//

#import "SSSocialThinkNoteLogin.h"
#import "SSThinkNoteShareAgent.h"
#import <UIKit/UIKit.h>

#define LOGIN_THINKNOTE_ITEM    NSLocalizedString(@"Login ThinkNote", "thinkNote Login")

#define USER_PASSWD_WRONG_STR   NSLocalizedString(@"User Name or Password is not correct, failed to login to server, please double again", "user/password wrong message")


@implementation SSSocialThinkNoteLogin

- (void) showThinkNoteLoingView
{
    UIAlertView *login = [[UIAlertView alloc] initWithTitle:LOGIN_THINKNOTE_ITEM
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles: REGISTER_STR, LOGIN_STR, nil];

    login.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    NSString *loginName = [[NSUserDefaults standardUserDefaults] objectForKey:kThinkNoteLoginName];
    NSString *loginPasswd = [[NSUserDefaults standardUserDefaults] objectForKey:kThinkNoteLoginPassword];
    
    if (loginName)
        [login textFieldAtIndex:0].text = loginName;
    
    if (loginPasswd)
        [login textFieldAtIndex:1].text = loginPasswd;
    
    [login show];
}

- (NSString *) getUserName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kThinkNoteLoginName];
}

- (NSString *) getPasswd
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kThinkNoteLoginPassword];
}

#pragma mark - TextField delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
    case 0:
            
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.qingbiji.cn/register" ]];
        break;
            
    case 1:

        dispatch_async(dispatch_queue_create("login", nil), ^(void) {
                SSThinkNoteController *tncontroll = [[SSThinkNoteController alloc]  init];
                NSString *username = [alertView textFieldAtIndex:0].text;
                NSString *passwd = [alertView textFieldAtIndex:1].text;

                if (![tncontroll loginNoteServerSyncWithName:username withPassword:passwd]) {
                    [[NSUserDefaults standardUserDefaults] setObject:[alertView textFieldAtIndex:0].text
                                                              forKey:kThinkNoteLoginName];
                    [[NSUserDefaults standardUserDefaults] setObject:[alertView textFieldAtIndex:1].text
                                                              forKey:kThinkNoteLoginPassword];
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:SSSocialAccountChangedNotification object:self];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                    UIAlertView *login = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", "error title of think note share")
                                                                    message:USER_PASSWD_WRONG_STR
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                        [login show];
                    });

                }
            });
        break;
    }
}

@end
