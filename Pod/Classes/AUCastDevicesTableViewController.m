//
//  AUCastDevicesTableViewController.m
//  Pods
//
//  Created by Dev on 4/29/15.
//
//

#import "AUCastDevicesTableViewController.h"

@interface AUCastDevicesTableViewController ()

@end

@implementation AUCastDevicesTableViewController

////if ([[AUCast sharedInstance] deviceStatus] == AUCastDeviceScannerStatusDevicesAvailable) {
////    [blurredActionSheet addButtonWithTitle:NSLocalizedString(@"Play on Chromecast", nil) type:AHKActionSheetButtonTypeDestructive handler:^(PCDLBlurredActionSheet *actionSheet) {
////        [[AUCast sharedInstance] showAvailableDevicesFromController:self.controller completionBlock:^(GCKDevice *connectedDevice, NSError *error) {
////            if (!error && connectedDevice) {
////                if ([media ]) {
////                    <#statements#>
////                }
////                [[AUCast sharedInstance] playURL:[NSURL URLWithString:media.remotePath] contentType:<#(NSString *)#>]
////            }
////        }];
////    }];
////}
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    
//    self.title = NSLocalizedString(@"Select Chrome Cast", nil);
//    
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kAUCastTableCellId];
//    
//    [self setupDataSource];
//    
//    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
//                                                                                target:self
//                                                                                action:@selector(hide)];
//    [self.navigationItem setLeftBarButtonItem:doneButton];
//    
//}
//
//- (void)hide {
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
//
//- (void)setupDataSource {
//    _devices = [[NSMutableArray alloc] init];
//    
//    __weak AUCastDevicesTableViewController *welf = self;
//    
//    [[AUCast sharedInstance] setDevicesChangeBlock:^(GCKDevice *inDevice, GCKDevice *outDevice, NSArray *allDevices) {
//        if (!inDevice && !outDevice) {
//            welf.devices = [allDevices mutableCopy];
//            [self.tableView reloadData];
//            return;
//        }
//        
//        [self.tableView beginUpdates];
//        
//        if (inDevice && ![welf.devices containsObject:inDevice]) {
//            [welf.devices insertObject:inDevice atIndex:0];
//            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
//        }
//        
//        if (outDevice && [welf.devices containsObject:outDevice]) {
//            NSUInteger idx = [welf.devices indexOfObject:outDevice];
//            [welf.devices removeObject:outDevice];
//            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
//        }
//        
//        [self.tableView endUpdates];
//        
//    }];
//}
//
//- (void)viewWillDisappear:(BOOL)animated {
//    
//    [[AUCast sharedInstance] setSearchDevices:NO];
//    
//    [super viewWillDisappear:animated];
//}
//
//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    // Return the number of sections.
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    // Return the number of rows in the section.
//    return _devices.count;
//}
//
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAUCastTableCellId forIndexPath:indexPath];
//    
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAUCastTableCellId];
//    }
//    
//    NSObject *device = [self.devices objectAtIndex:indexPath.row];
//    
//    [cell.textLabel setText:[device valueForKey:@"friendlyName"]];
//    
//    return cell;
//}
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    GCKDevice *device = [self.devices objectAtIndex:indexPath.row];
//    
//    [[AUCast sharedInstance] connectToDevice:device];
//    
//    [self hide];
//    
//}

@end
