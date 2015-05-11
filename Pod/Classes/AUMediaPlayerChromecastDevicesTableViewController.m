//
//  PCDLChromecastDevicesTableViewController.m
//  PCDL
//
//  Created by Dev on 4/30/15.
//  Copyright (c) 2015 AppUnite.com. All rights reserved.
//

#import "AUMediaPlayerChromecastDevicesTableViewController.h"
#import "PCDLMediaManager.h"
#import "UILabel+NavigationBarLabel.h"
#import "AUMediaPlayer.h"

static NSString *const kAUCastTableCellId = @"kAUCastTableCellId";

@interface AUMediaPlayerChromecastDevicesTableViewController ()

@property (nonatomic, strong) NSMutableArray *devices;

@end

@implementation AUMediaPlayerChromecastDevicesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"SELECT CHROMECAST", nil);

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kAUCastTableCellId];

    [self setupDataSource];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(hide)];
    [self.navigationItem setLeftBarButtonItem:doneButton];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[PCDLMediaManager sharedInstance].chromecastManager setSearchDevices:YES];
}

- (void)hide {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupDataSource {
    _devices = [[NSMutableArray alloc] init];

    __weak __typeof__(self) welf = self;
    
    [[PCDLMediaManager sharedInstance].chromecastManager setDevicesChangeBlock:^(GCKDevice *inDevice, GCKDevice *outDevice, NSArray *allDevices) {
        if (!inDevice && !outDevice) {
            welf.devices = [allDevices mutableCopy];
            [self.tableView reloadData];
            return;
        }

        [self.tableView beginUpdates];

        if (inDevice && ![welf.devices containsObject:inDevice]) {
            [welf.devices insertObject:inDevice atIndex:0];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }

        if (outDevice && [welf.devices containsObject:outDevice]) {
            NSUInteger idx = [welf.devices indexOfObject:outDevice];
            [welf.devices removeObject:outDevice];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(NSInteger)idx inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }

        [self.tableView endUpdates];
        
        if (welf.devices.count != allDevices.count) {
            welf.devices = [NSMutableArray arrayWithArray:allDevices];
            [self.tableView reloadData];
        }

    }];
}

- (void)viewWillDisappear:(BOOL)animated {

    [[PCDLMediaManager sharedInstance].chromecastManager setSearchDevices:NO];

    [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return (NSInteger)_devices.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAUCastTableCellId forIndexPath:indexPath];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAUCastTableCellId];
    }

    NSObject *device = [self.devices objectAtIndex:(NSUInteger)indexPath.row];

    [cell.textLabel setText:[device valueForKey:@"friendlyName"]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GCKDevice *device = [self.devices objectAtIndex:(NSUInteger)indexPath.row];
    
    [AUMediaPlayerChromecastDevicesTableViewController]

    [[PCDLMediaManager sharedInstance].chromecastManager connectToDevice:device];

    [self hide];

}

@end
