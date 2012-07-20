//
//  SSMailAgent.m
//  ShiftScheduler
//
//  Created by 洁靖 张 on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SSMailAgent.h"
#import "SSAppDelegate.h"
#import "SSShareObject.h"


@implementation SSMailAgent

- (id) initWithShareController: (SSShareController *) shareController
{
    self = [super init];
    shareC = shareController;
    return self;
}

- (void)composeMailWithAppDelegate: (SSAppDelegate *) ssDelegate
                           withNVC:(UINavigationController *)pnvc

{
    MFMailComposeViewController *picker;
    
    [ssDelegate rightButtonSwitchToShareOrBusy:NO];
    
    picker = [[MFMailComposeViewController alloc] init];
    __block MFMailComposeViewController  *picker_ = picker;

    dispatch_queue_t prepare_q = dispatch_queue_create("create mail queue", nil);
    dispatch_async(prepare_q, ^{ 
        picker_.mailComposeDelegate = self;
        [picker_ setSubject: shareC.shiftOverviewStr];
        // 1. first add calendar view image,
        NSData *data = UIImageJPEGRepresentation(shareC.shiftCalImage, 90.9f);
        
        [picker_ addAttachmentData:data mimeType:@"image/jpeg" 
                          fileName:shareC.shiftCalImageName];
        // 2. then add shift list views image
        
        NSData *listdata = UIImageJPEGRepresentation(shareC.shiftListImage, 90.9f);
        [picker_ addAttachmentData:listdata mimeType:@"image/jpeg" 
                          fileName:shareC.shiftListImageName];
        // 3. then body of the mail.
        [picker_ setMessageBody:shareC.shiftDetailEmailStr
                        isHTML:YES];
        
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
