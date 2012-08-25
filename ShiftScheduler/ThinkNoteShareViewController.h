//
//  ThinkNoteShareViewController.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-8-8.
//
//

#import <UIKit/UIKit.h>

@class SSShareController;
@class SSThinkNoteShareAgent;
@class SSSocialThinkNoteLogin;

@protocol SSShareViewControllerDelegate <NSObject>

- (void) shareViewControllerfinishShare;

@end

@interface ThinkNoteShareViewController : UIViewController <UIGestureRecognizerDelegate>
{
    __weak IBOutlet UITextView          *textView;
    
    __weak IBOutlet UINavigationItem    *titleStatusBar;
    __weak IBOutlet UIBarButtonItem     *shareButton;
    
    __weak IBOutlet UIBarButtonItem *cancelButton;

    __weak IBOutlet UIImageView     *letftImageView;
    __weak IBOutlet UIImageView     *imageViewRight;
    __weak IBOutlet UIPageControl   *_pageControl;
    __weak IBOutlet UIScrollView    *_rightScrollView;
    __weak IBOutlet UIScrollView    *_leftScrollView;
    __weak IBOutlet UIScrollView    *_mainScrollView;
    
    __weak IBOutlet UITextView  *_helpTextView;
    
    __weak IBOutlet UIActivityIndicatorView *_busyIndicator;
    
    id<SSShareViewControllerDelegate>  __unsafe_unretained _shareDelegate;
    
    UISwipeGestureRecognizer    *_swipeGesture;
    SSSocialThinkNoteLogin      *_thinkNoteLogin;
}   
- (IBAction)cancelButtonClicked:(id)sender;
- (IBAction)ShareButtonClicked:(id)sender;
- (IBAction)pageControlChanged:(id)sender;


@property( unsafe_unretained, nonatomic ) id<SSShareViewControllerDelegate> shareDelegate;


@property (weak) UITextView *textView;
@property (weak) UITextView *helpTextView;
@property (weak) UIActivityIndicatorView *busyIndicator;

@property (weak) UIScrollView *leftScrollView;
@property (weak) UIScrollView *rightScrollView;
@property (weak) UIScrollView *mainScrollView;
@property (weak) UINavigationItem *titleStatusBar;
@property (weak) UIBarButtonItem *shareButton;
@property (weak) UIBarButtonItem *cancelButton;
@property (weak) UIPageControl *pageControl;
@property (weak) UIImageView *letftImageView;
@property (weak) UIImageView *imageViewRight;

@property (strong) SSShareController *shareC;
@property (strong) SSThinkNoteShareAgent *shareAgent;

@end
