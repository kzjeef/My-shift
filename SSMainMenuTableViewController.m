//
//  MainMenuTableViewController.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 13-11-9.
//
//

#import "SSMainMenuTableViewController.h"
#import "SSAppDelegate.h"

@interface SSMainMenuTableViewController ()

@property (strong, nonatomic) NSDateFormatter *formatter;
@end

@implementation SSMainMenuTableViewController

- (NSDateFormatter *) formatter
{
    if (_formatter == nil){
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateStyle:NSDateFormatterMediumStyle];
    }
    return _formatter;
    
}

- (id) initWithStyle:(UITableViewStyle)style nameArray: (NSArray *) nameArray iconArray: (NSArray *)iconArray
{
    self = [super initWithStyle:style];
    if (self) {
        self.menuItemIconPathList = iconArray;
        self.menuItemNameList = nameArray;
        _currentSelectedView = kMainViewCalendarView;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorColor = UIColorFromRGB(0xCAD1D4);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];

    // This empty view will stop table 's empty label.
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
    emptyView.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:emptyView];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{


    //    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
        self.tableView.tableHeaderView = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 80.0f)];
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(70, 40, 0, 24)];
                label.text = [self.formatter stringFromDate:[NSDate date]];
                label.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
                [label sizeToFit];
                
                cell.textLabel.textColor = self.navigationController.tabBarController.tabBar.barTintColor;
                cell.backgroundColor = [UIColor clearColor];
                label.textColor = UIColorFromRGB(0xFFFFFF);
                [view setBackgroundColor:[UIColorFromRGB(0x0466C0) colorWithAlphaComponent:0.9f]];
                
                /* TODO: add lunar calendar text show here. */
                /* TODO: add holiday here. */
                [view addSubview:label];
            }
            view;
        });

    /*
    self.tableView.tableHeaderView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 184.0f)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 40, 100, 100)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        imageView.image = [UIImage imageNamed:@"AppIcon.png"];
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = 50.0;
        imageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        imageView.layer.borderWidth = 1.0f;
        imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        imageView.layer.shouldRasterize = YES;
        imageView.clipsToBounds = YES;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, 0, 24)];
        label.text = APP_NAME_STR;
     label.font = [UIFont fontWithName:@"HelveticaNeue" size:21];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithRed:62/255.0f green:68/255.0f blue:75/255.0f alpha:1.0f];
        [label sizeToFit];
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        [view addSubview:imageView];
        [view addSubview:label];
        view;
    });
     */

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuItemNameList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    if (indexPath.section == 0) {
        // -1 is to remove the first item, the big logo.
        cell.textLabel.text = [self.menuItemNameList objectAtIndex:(indexPath.row)];

        NSString *str = [self.menuItemIconPathList objectAtIndex:(indexPath.row)];

        if (str != NULL && str.length > 0) {
            UIImage *i = [UIImage imageWithContentsOfFile:str];
            if ([i respondsToSelector:@selector(imageWithRenderingMode:)])
                i = [i imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imageView.image = i;
        } else
            cell.imageView.image = NULL;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UINavigationController *navigationController = (UINavigationController *)self.frostedViewController.contentViewController;

    if (indexPath.section == 0) {
        if(indexPath.row == 0) {
            navigationController.viewControllers = @[self.kalController];
            _currentSelectedView = kMainViewCalendarView;
            [self.switchDelegate SSMainMenuViewStartChange];

        } else if (indexPath.row == 1) {
            navigationController.viewControllers = @[self.shiftListTVC];
            _currentSelectedView = kMainViewShiftListView;
            [self.switchDelegate SSMainMenuViewStartChange];

        } else if (indexPath.row == 2) {
            navigationController.viewControllers = @[self.settingTVC];
            _currentSelectedView = kMainViewSettingView;
            [self.switchDelegate SSMainMenuViewStartChange];

        } else if (indexPath.row == 3) {
            navigationController.viewControllers = @[self.calendarSyncTVC];
            _currentSelectedView =  kMainViewCalendarSyncView;
            [self.switchDelegate SSMainMenuViewStartChange];
        } else if (indexPath.row == 4) {
            if (self.shareDelegate) {
                navigationController.viewControllers = @[self.kalController];
                _currentSelectedView = kMainViewCalendarView;
                [self.shareDelegate SSMainMenuShareButtonClicked:self];
                [self.switchDelegate SSMainMenuViewStartChange];
            }
        }    }

    [self.frostedViewController hideMenuViewController];
}


/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
