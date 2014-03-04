#ifndef CONFIG_H
#define CONFIG_H

/* work day type config show as modal view or nagviation view. */
#define CONFIG_WORKDAY_CONFIG_MODAL_VIEW 0

/* Shift change functions. */
#define CONFIG_SS_ENABLE_SHIFT_CHANGE_FUNCTION 0

/* Use tab bar view controller in main screen.
 * otherwise use a tabbar.*/
#define CONFIG_MAIN_UI_USE_TAB_BAR_CONTROLLER 1

/* Use ThinkNote share. */
#define ENABLE_THINKNOTE_SHARE  1

/* Use single shift config table mode. */
#define CONFIG_SINGLE_SHIFT_CONFIG_MODE 1

#define TAB_ICON_SIZE CGSizeMake(32, 32)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#endif

