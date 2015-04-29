//
//  AUCast.m
//  AUCastSDK
//
//  Created by Piotr Bernad on 21.04.2015.
//  Copyright (c) 2015 Appunite. All rights reserved.
//

#import "AUCast.h"

@interface AUCast() <GCKDeviceScannerListener, GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate>

@property (nonatomic, strong) GCKDeviceScanner *deviceScanner;

@property (nonatomic, strong) GCKDeviceManager *deviceManager;

@property (nonatomic, strong) NSMutableArray *devices;

@property (nonatomic, strong) GCKMediaControlChannel *mediaControlChannel;

@property (nonatomic, strong) GCKMediaInformation *mediaToPlay;

@property (nonatomic, copy) AUCastConnectCompletionBlock afterConnectBlock;

@end

@implementation AUCast

#pragma mark -
#pragma mark Setup

- (void)setApplicationID:(NSString *)applicationID {
    _applicationID = applicationID;
    
    [self initializeDeviceScanner];
}

#pragma mark -
#pragma mark Scanning

- (void)initializeDeviceScanner {
    GCKFilterCriteria *filterCriteria = [GCKFilterCriteria criteriaForAvailableApplicationWithID:self.applicationID];
    
    self.deviceScanner = [[GCKDeviceScanner alloc] init];
    [self.deviceScanner setFilterCriteria:filterCriteria];
}

- (void)setSearchDevices:(BOOL)searchDevices {
    
    if (_searchDevices == searchDevices) {
        return;
    }
    
    _searchDevices = searchDevices;
    
    if (_searchDevices) {
        [self startSearchingDevices];
    } else {
        [self stopSearchingDevices];
    }
}

- (void)setDevicesChangeBlock:(AUCastDeviceScannerChangeBlock)devicesChangeBlock {
    _devicesChangeBlock = devicesChangeBlock;
    
    if (_devicesChangeBlock) {
        _devicesChangeBlock(nil, nil, self.devices);
    }
}

- (void)setObserveDevicesStatusBlock:(AUCastDeviceScannerStatusChangeBlock)observeDevicesStatusBlock {
    _observeDevicesStatusBlock = observeDevicesStatusBlock;
    
    if (_observeDevicesStatusBlock) {
        _observeDevicesStatusBlock(self.deviceScanner.devices.count > 0 ? AUCastDeviceScannerStatusDevicesAvailable : AUCastDeviceScannerStatusDevicesNotAvailable);
    }
}

- (void)startSearchingDevices {
    NSParameterAssert(self.applicationID);
    
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
}

- (void)stopSearchingDevices {
    [self.deviceScanner stopScan];
}

- (void)deviceDidComeOnline:(GCKDevice *)device {
    
    if (![self.devices containsObject:device]) {
        [self.devices addObject:device];
    }
    
    if (self.devicesChangeBlock) {
        self.devicesChangeBlock(device, nil, self.devices);
    }
    
    if (self.observeDevicesStatusBlock) {
        self.observeDevicesStatusBlock(self.deviceStatus);
    }
}

- (void)deviceDidGoOffline:(GCKDevice *)device {

    if ([self.devices containsObject:device]) {
        [self.devices removeObject:device];
    }
    
    if (self.devicesChangeBlock) {
        self.devicesChangeBlock(nil, device, self.devices);
    }
    
    if (self.observeDevicesStatusBlock) {
        self.observeDevicesStatusBlock(self.deviceStatus);
    }
}

//- (void)showAvailableDevicesFromController:(UIViewController *)controller completionBlock:(AUCastConnectCompletionBlock)completion {
//    
//    _afterConnectBlock = completion;
//    
//    AUCastDevicesTableViewController *searchController = [[AUCastDevicesTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
//    
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:searchController];
//    
//    [controller presentViewController:navigationController animated:YES completion:nil];
//}



- (AUCastDeviceScannerStatus)deviceStatus {
    return self.devices.count > 0 ? AUCastDeviceScannerStatusDevicesAvailable : AUCastDeviceScannerStatusDevicesNotAvailable;
}

- (NSMutableArray *)devices {
    if (!_devices) {
        _devices = [[NSMutableArray alloc] init];
    }
    
    return _devices;
}

#pragma mark -
#pragma mark Connection

- (void)connectToDevice:(GCKDevice *)device {
    if ([self.deviceManager connectionState] == GCKConnectionStateConnected || [self.deviceManager connectionState] == GCKConnectionStateConnecting) {
        [self.deviceManager disconnect];
    }
    
    self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:device clientPackageName:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
    [self.deviceManager setDelegate:self];
    [self.deviceManager connect];
}

#pragma mark -
#pragma mark Playback

- (void)playURL:(NSURL *)url contentType:(NSString *)contentType {
    
    _mediaToPlay = [[GCKMediaInformation alloc] initWithContentID:[url absoluteString]
                                                       streamType:GCKMediaStreamTypeNone
                                                      contentType:contentType
                                                         metadata:nil
                                                   streamDuration:0
                                                       customData:nil];
    
    
    [self.deviceManager launchApplication:self.applicationID];
}

- (void)play {
    [self.mediaControlChannel loadMedia:_mediaToPlay autoplay:YES playPosition:0];
}

- (void)stop {
    [self.mediaControlChannel stop];
    
    [self.deviceManager stopApplication];
    
    [self.deviceManager disconnect];
}

#pragma mark -
#pragma mark Device Manager Delegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager  {
    
    if (_afterConnectBlock) {
        _afterConnectBlock(deviceManager.device, nil);
    }
    
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectWithError:(NSError *)error {
    if (_afterConnectBlock) {
        _afterConnectBlock(nil, error);
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication {
    
    if (launchedApplication) {
        self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
        self.mediaControlChannel.delegate = self;
        [self.deviceManager addChannel:self.mediaControlChannel];
        
        [self play];
    }
}

#pragma mark -
#pragma mark Media control cahnnel delegate

- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel {
    GCKMediaStatus *status = mediaControlChannel.mediaStatus;
    
    if (status.idleReason == GCKMediaPlayerIdleReasonFinished) {
        [self stop];
    }
}

@end
