//
//  AlarmPickerViewController.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-10-31.
//
//

#import <AVFoundation/AVFoundation.h>

#import "AlarmPickerViewController.h"
#import "SSDefaultConfigName.h"


@interface AlarmPickerViewController ()
{
    NSArray *items;
    AVAudioPlayer *avSound;
    NSString *alarmFileNameSaved;
    int pickedRow;
}
@end

@implementation AlarmPickerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        pickedRow = -1;
    }
    return self;
}

- (void)loadAlarmList
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AlarmList" ofType:@"plist"];
    NSData *plistData = [NSData dataWithContentsOfFile:path];
    NSString *error;
    NSPropertyListFormat format;
    id plist;
 
    plist = [NSPropertyListSerialization propertyListFromData:plistData
                                             mutabilityOption:NSPropertyListImmutable
                                                       format:&format
                                             errorDescription:&error];
    if(!plist){
        NSLog(@"loadAlarm generate alarm list error%@", error);
    }

   items = plist;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadAlarmList];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    alarmFileNameSaved = [[NSUserDefaults standardUserDefaults] stringForKey:USER_CONFIG_APP_DEFAULT_ALERT_SOUND];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    NSString *newFile = [[NSUserDefaults standardUserDefaults] stringForKey:USER_CONFIG_APP_DEFAULT_ALERT_SOUND];
    if (![newFile isEqualToString:alarmFileNameSaved]) {
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc postNotificationName:@"ALARM_SOUND_CHANGED" object:nil];
    }

    if (avSound && [avSound isPlaying])
        [avSound stop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AlarmCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    

    NSString *name = [[items objectAtIndex:indexPath.row] objectForKey:@"name"];
    cell.textLabel.text = name;

    NSString *filename = [[items objectAtIndex:indexPath.row] objectForKey:@"file"];

    NSString *currentDefault = [[NSUserDefaults standardUserDefaults] stringForKey:USER_CONFIG_APP_DEFAULT_ALERT_SOUND];
    if ([currentDefault isEqualToString:filename])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL onlyStop = false;
    // choose selected item,
    // 1. update the index,
    if (pickedRow == indexPath.row)
        onlyStop = true;
    pickedRow = indexPath.row;

    // 2. store the name of alarm file.
    NSString *filename = [[items objectAtIndex:indexPath.row] objectForKey:@"file"];
    NSString *name = [[items objectAtIndex:indexPath.row] objectForKey:@"name"];

    [[NSUserDefaults standardUserDefaults] setObject:filename forKey:USER_CONFIG_APP_DEFAULT_ALERT_SOUND];
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:USER_CONFIG_APP_ALERT_SOUND_FILE];

    
    [self.tableView reloadData];
    // 3. play the alarm file, if already playing, stop play.
    // TODO
    
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
    
    if (avSound && [avSound isPlaying])
        [avSound stop];
    
    if (!onlyStop) {
        avSound = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:soundURL error:nil];
        [avSound play];
    }

}

@end
