//
//  ThinkNoteShareViewController.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-8-8.
//
//

#import "ThinkNoteShareViewController.h"
#import "SSThinkNoteShareAgent.h"
#import "SSSocialThinkNoteLogin.h"
#import "SSShareObject.h"
#import "I18NStrings.h"

#import <QuartzCore/QuartzCore.h>


@interface ThinkNoteShareViewController ()
{
    SSShareController *_shareC;
    SSThinkNoteShareAgent *_shareAgent;
    
    
}

@end

@implementation ThinkNoteShareViewController

@synthesize textView, titleStatusBar, shareButton, cancelButton, letftImageView, imageViewRight;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// ZJJ Lib.

// @addBoarder
//  add boarder to a special view
// @view the view you want to add boarder
// @radius the round coner of the boarder.
// @color the color you want to add, if nil, give a gray color.
+ (void) addBorder: (UIView *) view radius: (int) radius color: (UIColor *) color
{
    UIColor *theColor = color;
    if (theColor == nil)
        theColor = [UIColor grayColor];
    [view.layer setBorderColor:[theColor CGColor]];
    [view.layer setBorderWidth:2.3];
    [view.layer setCornerRadius:radius];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    titleStatusBar.title = SHARE_STRING;

    self.shareButton.title = SHARE_TO_THINKNOTE;
    
    self.cancelButton.title = NSLocalizedString(@"Cancel", "cancel");
  
    
    self.helpTextView.text = NSLocalizedString(@"Swipe right to review the calendar images.", "share view help text");
    

    //    self.helpTextView. = [UIColor grayColor];
  
    letftImageView.hidden = YES;
    
    imageViewRight.hidden = YES;
    
    self.leftScrollView.hidden = YES;
    self.rightScrollView.hidden = YES;
    
    self.mainScrollView.pagingEnabled = YES;

    UISwipeGestureRecognizer * swipLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureLeft:)];
    swipLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipLeft.enabled = YES;
    
    UISwipeGestureRecognizer *swipRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureRight:)];
    swipRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipRight.enabled = YES;
    
    
    // add a border to these view to looks more beautiful.
    [self.class addBorder:textView radius:15 color:nil];
    [self.class addBorder:self.letftImageView radius:0 color:nil];
    [self.class addBorder:self.imageViewRight radius:0 color:nil];
    //    [self.class addBorder:self.helpTextView radius:15 color:nil];
    
    // add a seperated gesture, mix together is not good for handling direction.
    [self.mainScrollView addGestureRecognizer:swipLeft];
    [self.mainScrollView addGestureRecognizer:swipRight];
    
    _thinkNoteLogin = [[SSSocialThinkNoteLogin alloc] init];
    
}

- (void)viewDidUnload
{
    titleStatusBar = nil;
    shareButton = nil;
    cancelButton = nil;
    textView = nil;
    imageViewRight = nil;
    letftImageView = nil;
    _pageControl = nil;
    _leftScrollView = nil;
    _rightScrollView = nil;
    _mainScrollView = nil;
    _swipeGesture = nil;
    _busyIndicator = nil;
    _helpTextView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.shareC invaildCache];
    
    letftImageView.image = self.shareC.shiftCalImage;
    
    imageViewRight.image = self.shareC.shiftListImage;
    
    self.textView.text = self.shareC.shiftThinkNoteStr;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.shareC.shiftThinkNoteStr = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([_thinkNoteLogin getUserName].length == 0
        || [_thinkNoteLogin getPasswd].length == 0)
    {
        [_thinkNoteLogin showThinkNoteLoingView];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)cancelButtonClicked:(id)sender {

    [self.shareAgent disconnect];
    [self.busyIndicator stopAnimating];
    self.shareButton.enabled = YES;
    [self.shareDelegate shareViewControllerfinishShare];

}

- (IBAction)ShareButtonClicked:(id)sender {
    
    
    self.shareButton.enabled = NO;
    self.shareC.shiftThinkNoteStr = self.textView.text;
    [self.busyIndicator startAnimating];
    [self.shareAgent composeThinkNoteWithNagvagation:self.navigationController withBlock:^(SSShareResult *result) {
        // @TODO empty here.
        [self.busyIndicator stopAnimating];

        if (result.result < 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorTitle = NSLocalizedString(@"Error", "error title of think note share");
                
                NSString *errorstring = result.failedReason;
                
                if (result.result == TN_LOGIN_FAILED) {
                    errorstring = [NSString stringWithFormat:@"%@.\n%@", errorstring, TNS_SETTING_TIPS];
                }
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                            message:errorstring
                                                               delegate:nil cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
                self.shareButton.enabled = YES;
            });
        } else if (result.result == 0) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorTitle = NSLocalizedString(@"Success", "error title of think note share");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                                message: TNS_SUCCESS_SHARED
                                                               delegate:nil cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
                
                [self.shareDelegate shareViewControllerfinishShare];
                self.shareButton.enabled = YES;

            });

        }

    }];

}

- (IBAction)pageControlChanged:(id)sender {
    UIPageControl *page = sender;

    textView.hidden =YES;
    [textView resignFirstResponder];
    imageViewRight.hidden = YES;
    letftImageView.hidden = YES;
    self.leftScrollView.hidden = YES;
    self.rightScrollView.hidden = YES;
    
    
    switch (page.currentPage) {
        case 0:
            textView.hidden = NO;
            break;
        case 1:
            letftImageView.hidden = NO;
            self.leftScrollView.hidden = NO;
            break;
        case 2:
            imageViewRight.hidden = NO;
            self.rightScrollView.hidden = NO;
        default:
            break;
    }

}


- (IBAction) swipeGestureLeft:(id)sender
{
    if (self.pageControl.currentPage == self.pageControl.numberOfPages - 1)
        return;
    
    if (self.pageControl.currentPage != self.pageControl.numberOfPages - 1)
        self.pageControl.currentPage = self.pageControl.currentPage + 1;


    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight  forView:self.mainScrollView cache:YES];
    [UIView commitAnimations];

    [self pageControlChanged:self.pageControl];
}

- (IBAction) swipeGestureRight:(id)sender
{
    if (self.pageControl.currentPage == 0)
        return;
    
    if (self.pageControl.currentPage != 0)
        self.pageControl.currentPage = self.pageControl.currentPage - 1;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft  forView:self.mainScrollView cache:YES];
    [UIView commitAnimations];

    [self pageControlChanged:self.pageControl];
}
@end
