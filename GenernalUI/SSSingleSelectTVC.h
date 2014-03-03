//
//  SSSingleSelectTVC.h
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-3-2.
//
//

#import <UIKit/UIKit.h>

@protocol SSSingleSelectTVCDelegate<NSObject>
- (void)singleSelect: (id) sender itemSelectedatRow:(NSInteger) row;
@end

@interface SSSingleSelectTVC : UITableViewController

@property (strong, nonatomic) NSArray *tableData;
@property (weak, nonatomic) id<SSSingleSelectTVCDelegate> delegate;
@property int selectedRow;

@end
