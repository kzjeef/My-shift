//
//  SSSingleSelectTVC.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 14-3-2.
//
//

#import "SSSingleSelectTVC.h"

@interface SSSingleSelectTVC ()

@end

@implementation SSSingleSelectTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - Table view data source

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Cancel", "cancel") style:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SingleSelectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc]  initWithStyle: UITableViewCellStyleSubtitle 
                                       reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.row == self.selectedRow)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
    if ([self.delegate respondsToSelector:@selector(singleSelect:itemSelectedatRow:)]) {
      [self.delegate singleSelect:self itemSelectedatRow:indexPath.row];
      [self dismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark - Actions

- (IBAction)cancelPressed:(id)sender
{
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


@end
