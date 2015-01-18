//
//  AlarmPickerViewController.m
//  ShiftScheduler
//
//  Created by Jiejing Zhang on 12-10-31.
//
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "SSSettingAlarmPickerVC.h"
#import "SSDefaultConfigName.h"
#import "I18NStrings.h"

@interface SSSettingAlarmPickerVC ()
{
    NSArray *shortItems;
    NSArray *longItems;
    AVAudioPlayer *avSound;
    NSString *alarmFileNameSaved;
    UIImage *selected_icon;
    int pickedRow;
    int pickedSection;
}
@end

@implementation SSSettingAlarmPickerVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (NSArray *)loadAlarmList: (NSString *) name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
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

    return plist;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    shortItems = [self loadAlarmList: @"AlarmList"];
    longItems = [self loadAlarmList:@"LongAlarmList"];


    selected_icon = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"strike_icon" ofType:@"png"]];

    pickedRow = -1;
    pickedSection = -1;

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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 1)
        return shortItems.count;
    else
        return longItems.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return LONG_ALARM_STR;
    else
        return SHORT_ALARM_STR;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AlarmCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    NSArray *alarmArray;

    if (indexPath.section == 1)
        alarmArray = shortItems;
    else
        alarmArray = longItems;



    NSString *name = [[alarmArray objectAtIndex:indexPath.row] objectForKey:@"name"];
    cell.textLabel.text = name;

    NSString *filename = [[alarmArray objectAtIndex:indexPath.row] objectForKey:@"file"];

    NSString *currentDefault = [[NSUserDefaults standardUserDefaults] stringForKey:USER_CONFIG_APP_DEFAULT_ALERT_SOUND];


    if ([currentDefault isEqualToString:filename]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:selected_icon];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }




    // get the length of alarm.
    /*
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:soundURL options:nil];
    CMTime time = asset.duration;
    double durationInSeconds = CMTimeGetSeconds(time);
    int dur = (int)durationInSeconds;
     */
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *alarmArray;
    BOOL onlyStop = false;
    // choose selected item,
    // 1. update the index,

    if (indexPath.section == 1)
        alarmArray = shortItems;
    else
        alarmArray = longItems;

    if (pickedRow == indexPath.row && pickedSection == indexPath.section)
        onlyStop = true;

    pickedRow = indexPath.row;
    pickedSection = indexPath.section;

    // 2. store the name of alarm file.
    NSString *filename = [[alarmArray objectAtIndex:indexPath.row]  objectForKey:@"file"];
    NSString *name = [[alarmArray objectAtIndex:indexPath.row]      objectForKey:@"name"];

    [[NSUserDefaults standardUserDefaults] setObject:filename   forKey:USER_CONFIG_APP_DEFAULT_ALERT_SOUND];
    [[NSUserDefaults standardUserDefaults] setObject:name       forKey:USER_CONFIG_APP_ALERT_SOUND_FILE];

    
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
