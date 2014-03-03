//
//  SSShiftMultipSelectTVC.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-3-2.
//
//

#import <UIKit/UIKit.h>

@protocol SSShiftMultipleSelectDelegate <NSObject>


/** get title of a item. 
 */
- (NSString *) shiftSelect: (id) sender objectTitle: (id) item;

/**
   should this item be selected ? ask the sender this question.
*/
- (BOOL) shiftSelect: (id) sender shouldSelectItem: (id) item;

/**
   notify item select state changed to new state.
*/
- (void) shiftSelect: (id) sender newState: (BOOL) newState;

/**
   notify done button clicked, it will pass the state and value array.
   key will be the objects, and value would be the on/off value of checked state.
*/
- (void) shiftSelect: (id) sender doneButtonClicked: (NSDictionary *) states;

/**
   notify cancel button clicked, it will pass the last state.
*/
- (void)  shiftSelect: (id) sender cancelButtonClicked: (NSDictionary *) states;

@end


@interface SSShiftMultipSelectTVC : UITableViewController

@property (strong, nonatomic) NSArray<NSCopying> *items;
@property (weak, nonatomic)  id<SSShiftMultipleSelectDelegate> delegate;

@end
