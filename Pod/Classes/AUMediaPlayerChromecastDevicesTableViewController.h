//
//  PCDLChromecastDevicesTableViewController.h
//  PCDL
//
//  Created by Dev on 4/30/15.
//  Copyright (c) 2015 AppUnite.com. All rights reserved.
//

#import "PCDLTableViewController.h"

@interface AUMediaPlayerChromecastDevicesTableViewController : PCDLTableViewController

@property (nonatomic, copy) AUCastDeviceScannerChangeBlock deviceBlock;

@end
