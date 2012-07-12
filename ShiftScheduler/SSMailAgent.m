//
//  SSMailAgent.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSMailAgent.h"
#import <QuartzCore/QuartzCore.h>


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
                     withShareProfilesVC:(SSShareProfileListViewController *)sharevc
{
    NSString *shiftMonthstr = [kal selecedMonthNameAndYear];
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    
    picker.mailComposeDelegate = self;
    [picker setSubject: [NSString stringWithFormat:@"%@-%@", 
                                        NSLocalizedString(@"Shift Scheduler", ""),
                                  shiftMonthstr]];
    
    // 1. first add calendar view image,
    UIImage *image = [kal captureCalendarView];
    if (!image)
        NSLog(@"image is null by [kal:%@]", kal);
    NSData *data = UIImageJPEGRepresentation(image, 90.9f);
    
    [picker addAttachmentData:data mimeType:@"image/jpeg" 
                     fileName:[NSString stringWithFormat:@"%@-%@", 
                                        NSLocalizedString(@"Shift Scheduler", ""),
                                        shiftMonthstr]];
    // 2. then add shift list views image
    
    UIImage *shiftlistImage = [self.class imageWithView:sharevc.view];
    if (!image)
        NSLog(@"image from shift list is null");
    NSData *listdata = UIImageJPEGRepresentation(shiftlistImage, 90.9f);
    [picker addAttachmentData:listdata mimeType:@"image/jpeg" fileName:@"test"];
    
    // 3. then body of the mail.
    
    NSString *emailBody = NSLocalizedString(@"It's the shift schedule at %@", "email body of shift forward ui");
    [picker setMessageBody:[NSString stringWithFormat:emailBody, shiftMonthstr]
                    isHTML:NO];
    nvc = pnvc;
    [nvc presentModalViewController:picker animated:YES];
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
