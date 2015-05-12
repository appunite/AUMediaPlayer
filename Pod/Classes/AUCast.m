//
//  AUCast.m
//  AUCastSDK
//
//  Created by Piotr Bernad on 21.04.2015.
//  Copyright (c) 2015 Appunite. All rights reserved.
//

#import "AUCast.h"
#import "AUMediaItem.h"
#import "AUMediaConstants.h"

NSString *const kAUMediaCastDevicesBecomeAvailableNotificationName = @"kAUMediaCastDevicesBecomeAvailableNotificationName";
NSString *const kAUMediaCastDevicesBecomeUnavailableNotificationName = @"kAUMediaCastDevicesBecomeUnavailableNotificationName";
NSString *const kAUMediaCastDevicesNearbyChanged = @"kAUMediaCastDevicesNearbyChanged";

@interface AUCast() <GCKDeviceScannerListener, GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate>

@property (nonatomic, strong) GCKDeviceScanner *deviceScanner;
@property (nonatomic, strong) GCKDeviceManager *deviceManager;
@property (nonatomic, strong) GCKMediaControlChannel *mediaControlChannel;

@property (nonatomic, strong) NSMutableArray *devices;

@property (nonatomic, strong) GCKMediaInformation *mediaToPlay;
@property (nonatomic, strong) NSString *currentMediaUid;
@property (nonatomic) NSTimeInterval momentToStartFrom;

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

- (void)startSearchingDevices {
    NSParameterAssert(self.applicationID);
    
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
}

- (void)stopSearchingDevices {
    [self.deviceScanner stopScan];
}

- (void)deviceDidComeOnline:(GCKDevice *)device {
    
    if (![self devicesContainsDevice:device]) {
        [self.devices addObject:device];
    }
    
    if (self.devicesChangeBlock) {
        self.devicesChangeBlock(device, nil, self.devices);
    }
    
    [self postDevicesAvailabilityStatusNotification];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
    
    if ([self devicesContainsDevice:device]) {
        [self.devices removeObject:device];
    }
    
    if (self.devicesChangeBlock) {
        self.devicesChangeBlock(nil, device, self.devices);
    }
    
    [self postDevicesAvailabilityStatusNotification];
}

- (AUCastStatus)status {
    GCKMediaPlayerState status = self.mediaControlChannel.mediaStatus.playerState;
    
    if (status == GCKMediaPlayerStatePaused) {
        return AUCastStatusPaused;
    } else if (status == GCKMediaPlayerStatePlaying) {
        return AUCastStatusPlaying;
    } else if (status == GCKMediaPlayerStateBuffering) {
        return AUCastStatusBuffering;
    } else if ([self isSearchingDevices]) {
        return AUCastStatusDeviceConnectionProcess;
    } else {
        return AUCastStatusOffline;
    }
}

- (AUCastDevicesAvailability)deviceAvailabilityStatus {
    return self.devices.count > 0 ? AUCastDevicesAvailabilityAvailable : AUCastDevicesAvailabilityUnavailable;
}

- (NSMutableArray *)devices {
    if (!_devices) {
        _devices = [[NSMutableArray alloc] init];
    }
    
    return _devices;
}

#pragma mark -
#pragma mark Connection

- (void)connectToDevice:(GCKDevice *)device connectionCompletionBlock:(AUCastConnectCompletionBlock)completionBlock {
    if ([self.deviceManager connectionState] == GCKConnectionStateConnected || [self.deviceManager connectionState] == GCKConnectionStateConnecting) {
        [self.deviceManager disconnect];
    }
    
    self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:device clientPackageName:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
    [self.deviceManager setDelegate:self];
    [self.deviceManager connect];
}

- (BOOL)isDeviceConnected {
    if ([self.deviceManager connectionState] == GCKConnectionStateConnected || [self.deviceManager connectionState] == GCKConnectionStateConnecting) {
        return YES;
    }
    return NO;
}

- (GCKDevice *)connectedDevice {
    return self.deviceManager.device;
}

#pragma mark -
#pragma mark Playback

- (void)playItem:(id<AUMediaItem>)item fromMoment:(NSTimeInterval)moment {
    
    NSString *path = [item remotePath];
    
    GCKMediaMetadataType type = GCKMediaMetadataTypeGeneric;
    if ([item itemType] == AUMediaTypeAudio) {
        type = GCKMediaMetadataTypeMusicTrack;
    } else if ([item itemType] == AUMediaTypeVideo) {
        type = GCKMediaMetadataTypeMovie;
    }
    
    GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] initWithMetadataType:type];
    [metadata setString:[item author] forKey:kGCKMetadataKeyArtist];
    [metadata setString:[item title] forKey:kGCKMetadataKeyTitle];
    
    if ([item coverImagePath]) {
        NSURL *imageURL = [NSURL URLWithString:[item coverImagePath]];
        [metadata addImage:[[GCKImage alloc] initWithURL:imageURL width:200 height:200]];
    }
    
    _mediaToPlay = [[GCKMediaInformation alloc] initWithContentID:path
                                                       streamType:GCKMediaStreamTypeNone
                                                      contentType:@""
                                                         metadata:metadata
                                                   streamDuration:0
                                                       customData:nil];
    _momentToStartFrom = moment;
    _currentMediaUid = [item uid];
    
    if ([self.deviceManager applicationConnectionState] == GCKConnectionStateConnected) {
        [self play];
    }
}



- (void)resume {
    if (self.status == AUCastStatusPaused) {
        [self.mediaControlChannel play];
    }
}

- (void)pause {
    if (self.status == AUCastStatusPlaying) {
        [self.mediaControlChannel pause];
    }
}

- (void)play {
    [self.mediaControlChannel loadMedia:_mediaToPlay autoplay:YES playPosition:_momentToStartFrom];
    _momentToStartFrom = 0.0;
}

- (void)stop {
    [self.mediaControlChannel stop];
    
    [self.deviceManager stopApplication];
    
    [self.deviceManager disconnect];
}

- (void)seekToMoment:(double)moment {
    
    double momentToSeek = moment > 1.0 ? 1.0 : moment;

    double duration = [self getCurrentItemDuration];
    if (duration > 0.0) {
        NSTimeInterval timeToSeekTo = momentToSeek * duration;
        [self.mediaControlChannel seekToTimeInterval:timeToSeekTo];
    }
}

- (BOOL)isItemCurrentlyPlayedOnChromecast:(id<AUMediaItem>)item {
    if ([[item uid] isEqualToString:_currentMediaUid]) {
        return YES;
    }
    
    return NO;
}

- (NSTimeInterval)getCurrentPlaybackProgressTime {
    if (self.mediaControlChannel.mediaStatus) {
        return self.mediaControlChannel.approximateStreamPosition;
    }
    return -1.0;
}

- (NSTimeInterval)getCurrentItemDuration {
    if (self.mediaControlChannel.mediaStatus.mediaInformation) {
        return self.mediaControlChannel.mediaStatus.mediaInformation.streamDuration;
    }
    return -1.0;
}

#pragma mark -
#pragma mark Device Manager Delegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager  {
    
    if (_afterConnectBlock) {
        _afterConnectBlock(deviceManager.device, nil);
    }
    
    [self.deviceManager launchApplication:self.applicationID];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectWithError:(NSError *)error {
    if (_afterConnectBlock) {
        _afterConnectBlock(nil, error);
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication {
    
    self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
    self.mediaControlChannel.delegate = self;
    [self.deviceManager addChannel:self.mediaControlChannel];
    
    if (_mediaToPlay) {
        [self play];
    }
}

#pragma mark -
#pragma mark Media control cahnnel delegate

- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel {
    
    GCKMediaStatus *status = mediaControlChannel.mediaStatus;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlaybackStateDidChangeNotification object:nil];
    
    if (status.idleReason == GCKMediaPlayerIdleReasonFinished) {
        [self.delegate playbackDidReachEnd];
    }
}

#pragma mark -
#pragma mark Helpers

- (void)postDevicesAvailabilityStatusNotification {
    if (self.deviceAvailabilityStatus == AUCastDevicesAvailabilityAvailable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaCastDevicesBecomeAvailableNotificationName object:nil];
    } else if (self.deviceAvailabilityStatus == AUCastDevicesAvailabilityUnavailable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaCastDevicesBecomeUnavailableNotificationName object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaCastDevicesNearbyChanged object:nil userInfo:@{@"devices": self.devices}];
}

- (BOOL)devicesContainsDevice:(GCKDevice *)device {
    for (GCKDevice *d in self.devices) {
        if ([device.deviceID isEqualToString:d.deviceID]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray *)availableDevices {
    return [self.devices copy];
}

@end
