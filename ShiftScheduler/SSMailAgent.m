//
//  SSMailAgent.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSMailAgent.h"
#import <QuartzCore/QuartzCore.h>
#import "SSAppDelegate.h"


@implementation SSMailAgent


+ (UIImage *) imageWithView:(UIView *)view
{
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)composeMailWithKalViewController:(KalViewController *)kal 
                                 withNVC:(UINavigationController *)pnvc
                       withSSAppDelegate:(SSAppDelegate *)ssDelegate
{
    MFMailComposeViewController *picker;

    [ssDelegate rightButtonSwitchToShareOrBusy:NO];
    
    __block KalViewController *kal_ = kal;
    __block SSAppDelegate *ssDelegate_ = ssDelegate;

    picker = [[MFMailComposeViewController alloc] init];
    __block MFMailComposeViewController  *picker_ = picker;

    dispatch_queue_t prepare_q = dispatch_queue_create("create mail queue", nil);
    dispatch_async(prepare_q, ^{ 
        NSString *shiftMonthstr = [kal_ selecedMonthNameAndYear];
    
        picker_.mailComposeDelegate = self;
        [picker_ setSubject: [NSString stringWithFormat:@"%@-%@", 
                             NSLocalizedString(@"Shift Scheduler", ""),
                             shiftMonthstr]];
        
        // 1. first add calendar view image,
        UIImage *image = [kal_ captureCalendarView];
        if (!image)
            NSLog(@"image is null by [kal:%@]", kal_);
        NSData *data = UIImageJPEGRepresentation(image, 90.9f);
        
        [picker_ addAttachmentData:data mimeType:@"image/jpeg" 
                     fileName:[NSString stringWithFormat:@"%@-%@", 
                               NSLocalizedString(@"Shift Scheduler", ""),
                               shiftMonthstr]];
        // 2. then add shift list views image
        
        UIImage *shiftlistImage = [self.class imageWithView:ssDelegate_.shareProfilesVC.view];
        if (!image)
            NSLog(@"image from shift list is null");
        NSData *listdata = UIImageJPEGRepresentation(shiftlistImage, 90.9f);
        [picker_ addAttachmentData:listdata mimeType:@"image/jpeg" 
                         fileName:NSLocalizedString(@"on-off-time", "on-off time in mail attachment")];
        // 3. then body of the mail.
        NSString *emailBody = NSLocalizedString(@"It's the shift schedule at %@, you can check the shift of this month by attachment %@, and each shift's work time by %@", "email body of shift forward ui");
        
        
        [picker_ setMessageBody:[NSString stringWithFormat:emailBody, 
                                shiftMonthstr,
                                NSLocalizedString(@"Shift Scheduler", ""),
                                NSLocalizedString(@"on-off-time", "on-off time in mail attachment")]
                        isHTML:NO];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [ssDelegate rightButtonSwitchToShareOrBusy:YES];
            nvc = pnvc;
            [nvc presentModalViewController:picker_ animated:YES];
        });
    });
}
                   
// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the 
// message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller 
		didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
    NSString *resstring;
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			resstring = @"Result: Mail sending canceled";
			break;
		case MFMailComposeResultSaved:
			resstring = @"Result: Mail saved";
			break;
		case MFMailComposeResultSent:
			resstring = @"Result: Mail sent";
			break;
		case MFMailComposeResultFailed:
			resstring = @"Result: Mail sending failed";
			break;
		default:
			resstring = @"Result: Mail not sent";
			break;
	}
        NSLog(@"mail result:%@", resstring);
	[nvc dismissModalViewControllerAnimated:YES];
}

@end
