/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>
#import "KalView.h"       // for the KalViewDelegate protocol
#import "KalDataSource.h" // for the KalDataSourceCallbacks protocol

@class KalLogic, KalDate;

/*
 *  KalViewDelegate
 *  ---------------
 *  KalViewDelegate used to Let Kal as a usuful tools for choosing
 *  Date for other tools, instead of a DateTime Picker, it can more
 *  Usuful when selecting and comparing.
 */

@class  KalViewController;
@protocol KalViewControllerDelegate
- (void) KalViewController: (KalViewController *) sender selectDate: (NSDate *) date;
- (void) KalViewControllerdidSelectTitle: (KalViewController *) sender;
@end


/* about icon drawing:
 * icon drawing is checked by KalTileView, it will get the icon info list
 * from KalViewDelegate, it was KalViewController, 
 * then KalViewController will forward the message to KalTileIconDelegate
 * this Delegate should filled by your application, better filled with KalDataSource
 * then provides a icon list.
 * how the icon should be draw is implemement in KalTileView, you needs to change that
 * code if you want to change it.
 */

/*
 * KalTileIconDelegate
 * -------------------
 * KalTileIconDelegate use to let Kal to draw Icon in choosen Tile,
 * Now it support two mode:
 *   - Pass a ICON CGImage and a ICON color will lead to a CGImage
 *     as a masking image and fill with Color, simple mono view and feeling.
 *   - Pass a ICON CGImage and no ICON color, will lead to a CGImage 
 *     drawing on the tile.
 */

enum {
    KAL_TILE_DRAW_METHOD_MONO_ICON_FILL_COLOR,
    KAL_TILE_DRAW_METHOD_COLOR_ICON,
};

/*
 * add these member for support rich tile view, and communate with Wokrday Data Source.
 * @image, the image want to show
 * @color, the color of text and image
 * @draw_type, use to mono image, drapeted.
 * @is_show_text, control is show text or not, if show text, not show image.
 * @icon_text, the text draw on image.
 */
#define KAL_TILE_ICON_IMAGE_KEY @"icon_image"
#define KAL_TILE_ICON_COLOR_KEY @"icon_color"
#define KAL_TILE_ICON_DRAW_TYPE_KEY @"draw_type"
#define KAL_TILE_ICON_IS_SHOW_TEXT @"is_show_text"
#define KAL_TILE_ICON_TEXT @"icon_text"
@class KalTileView;
@protocol KalTileIconDelegate

/* return a icon array with dictory of icon peroperys. */
- (NSArray *) KalTileDrawDelegate: (KalTileView *) sender getIconDrawInfoWithDate: (NSDate *) date;
@end 

/*
 *    KalViewController
 *    ------------------------
 *
 *  KalViewController automatically creates both the calendar view
 *  and the events table view for you. The only thing you need to provide
 *  is a KalDataSource so that the calendar system knows which days to
 *  mark with a dot and which events to list under the calendar when a certain
 *  date is selected (just like in Apple's calendar app).
 *
 */
@interface KalViewController : UIViewController <KalViewDelegate, KalDataSourceCallbacks>
{
  KalLogic *logic;
  UITableView *tableView;
  id <UITableViewDelegate> __unsafe_unretained delegate;
  id <KalDataSource> __unsafe_unretained dataSource;
  id <KalViewControllerDelegate> __unsafe_unretained vcdelegate;  
  NSDate *initialDate;                    // The date that the calendar was initialized with *or* the currently selected date when the view hierarchy was torn down in order to satisfy a low memory warning.
  NSDate *selectedDate;                   // I cache the selected date because when we respond to a memory warning, we cannot rely on the view hierarchy still being alive, and thus we cannot always derive the selected date from KalView's selectedDate property.
}

@property (nonatomic, unsafe_unretained) id<UITableViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) id<KalViewControllerDelegate> vcdelegate;
@property (nonatomic, unsafe_unretained) id<KalTileIconDelegate> tileDelegate;
@property (nonatomic, unsafe_unretained) id<KalDataSource> dataSource;
@property (nonatomic, strong, readonly) NSDate *selectedDate;

- (id)initWithSelectedDate:(NSDate *)selectedDate;  // designated initializer. When the calendar is first displayed to the user, the month that contains 'selectedDate' will be shown and the corresponding tile for 'selectedDate' will be automatically selected.
- (void)reloadData;                                 // If you change the KalDataSource after the KalViewController has already been displayed to the user, you must call this method in order for the view to reflect the new data.
- (void)showAndSelectDate:(NSDate *)date;           // Updates the state of the calendar to display the specified date's month and selects the tile for that date.

- (UIImage *)captureCalendarView;  /// get the Image of Kal View.
- (NSString *)selecedMonthNameAndYear; /// get the name of selected year and month.

- (NSArray *) KalTileDrawDelegate: (KalTileView *) sender getIconDrawInfoWithDate: (NSDate *) date; // get the tile icon informations.

@end
