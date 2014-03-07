//
//  SSShiftMultipSelectTVC.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-3-2.
//
//

#import "SSShiftMultipSelectTVC.h"

@interface SSShiftMultipSelectTVC ()

@property (strong, nonatomic) NSMutableArray *statusArray;

@end

@implementation SSShiftMultipSelectTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSArray *) statusArray {
    if (_statusArray == nil) {
        _statusArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.items.count; i++) {
            BOOL state = NO;
            if ([self.delegate respondsToSelector:@selector(shiftSelect:shouldSelectItem:)]) {
                state = [self.delegate shiftSelect:self shouldSelectItem:[self.items objectAtIndex:i]];
            }
            [_statusArray addObject:[NSNumber numberWithBool:state]];
        }
    }
    return _statusArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
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
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ShiftSelectCell";
    UITableViewCellStyle type = UITableViewCellAccessoryNone;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    NSString *title = @"<DEFAULT>";
    
    if ([self.delegate respondsToSelector:@selector(shiftSelect:objectTitle:)])
        title = [self.delegate shiftSelect:self objectTitle:[self.items objectAtIndex:indexPath.row]];

    if ([[self.statusArray objectAtIndex:indexPath.row] intValue] == YES)
        type = UITableViewCellAccessoryCheckmark;

    cell.textLabel.text = title;
    cell.accessoryType = type;

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL state = [[self.statusArray objectAtIndex:indexPath.row] intValue];
    
    state = !state;
    [self.statusArray replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithInt:state]];
    
    if ([self.delegate respondsToSelector:@selector(shiftSelect:newState:)]) {
        [self.delegate shiftSelect:self newState:state];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSDictionary *) zipTwoArray:(NSArray *)keys values: (NSArray *)values {
    if (keys.count != values.count)
        return nil;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    for (int i = 0; i < keys.count; i++)
        [dict setObject:[values objectAtIndex:i] forKey:[keys objectAtIndex:i]];
    
    return dict;
}

- (void) donePressed {
    NSDictionary *state = [self zipTwoArray:self.items values:self.statusArray];
    NSAssert(state != nil, @"array is not same length ?");
    if ([self.delegate respondsToSelector:@selector(shiftSelect:doneButtonClicked:)])
        [self.delegate shiftSelect:self doneButtonClicked:state];
}

- (void) cancelPressed {
    NSDictionary *state = [self zipTwoArray:self.items values:self.statusArray];
    NSAssert(state != nil, @"array is not same legnth ?");
    
    if ([self.delegate respondsToSelector:@selector(shiftSelect:cancelButtonClicked:)])
        [self.delegate shiftSelect:self cancelButtonClicked:state];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
