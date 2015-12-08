//
//  AUCast.h
//  AUCastSDK
//
//  Created by Piotr Bernad on 21.04.2015.
//  Copyright (c) 2015 Appunite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCKDevice;

extern NSString *const kAUMediaCastDevicesAvailabilityStatusChangeNotificationName;
extern NSString *const kAUMediaCastDevicesAvailabilityStatusChangeNotificationUserInfoKey;

@protocol AUMediaItem;

@protocol AUCastDelegate <NSObject>

- (void)playbackDidReachEnd;

@end

typedef NS_ENUM(NSUInteger, AUCastDevicesAvailability) {
    AUCastDevicesAvailabilityAvailable,
    AUCastDevicesAvailabilityUnavailable,
};

typedef NS_ENUM(NSUInteger, AUCastStatus) {
    AUCastStatusPlaying,
    AUCastStatusPaused,
    AUCastStatusBuffering,
    AUCastStatusDeviceConnectionProcess,
    AUCastStatusOffline
};

typedef void (^AUCastDeviceScannerChangeBlock)(GCKDevice *inDevice, GCKDevice *outDevice, NSArray *allDevices);
typedef void (^AUCastConnectCompletionBlock)(GCKDevice *connectedDevice, NSError *error);

@interface AUCast : NSObject

@property (nonatomic, strong) NSString *applicationID;
@property (nonatomic, weak) id<AUCastDelegate> delegate;

@property (nonatomic, readonly) BOOL isDeviceConnected;
@property (nonatomic, readonly) AUCastStatus status;
@property (nonatomic, readonly) AUCastDevicesAvailability deviceAvailabilityStatus;
@property (nonatomic, readonly) GCKDevice *connectedDevice;

#pragma mark - Scanning for devices

@property (nonatomic, assign, getter=isSearchingDevices) BOOL searchDevices;
@property (nonatomic, copy) AUCastDeviceScannerChangeBlock devicesChangeBlock;
@property (nonatomic, copy) AUCastConnectCompletionBlock afterConnectBlock;

- (NSArray *)availableDevices;

#pragma mark - Connecting

- (void)connectToDevice:(GCKDevice *)device;

#pragma mark - Playing Media

- (void)playItem:(id<AUMediaItem>)item fromMoment:(NSTimeInterval)moment;
- (BOOL)isItemCurrentlyPlayedOnChromecast:(id<AUMediaItem>)item;
- (void)resume;
- (void)pause;
- (void)stop;

- (void)seekToMoment:(double)moment;
- (NSTimeInterval)getCurrentPlaybackProgressTime;
- (NSTimeInterval)getCurrentItemDuration;

@end
