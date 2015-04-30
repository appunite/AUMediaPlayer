//
//  AUCast.h
//  AUCastSDK
//
//  Created by Piotr Bernad on 21.04.2015.
//  Copyright (c) 2015 Appunite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleCastBridge.h"

extern NSString *const kAUMediaCastDevicesBecomeAvailableNotificationName;
extern NSString *const kAUMediaCastDevicesBecomeUnavailableNotificationName;

@protocol AUMediaItem;

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

@property (nonatomic, readonly) AUCastStatus status;
@property (nonatomic, readonly) AUCastDevicesAvailability deviceAvailabilityStatus;

#pragma mark - Scanning for devices

@property (nonatomic, assign, getter=isSearchingDevices) BOOL searchDevices;
@property (nonatomic, copy) AUCastDeviceScannerChangeBlock devicesChangeBlock;

#pragma mark - Connecting

- (void)connectToDevice:(GCKDevice *)device;

#pragma mark - Playing Media

- (void)playItem:(id<AUMediaItem>)item fromMoment:(NSTimeInterval)moment waitingForDevice:(void (^)(BOOL waiting))waitingBlock connectionCompletionBlock:(AUCastConnectCompletionBlock)completionBlock;
- (void)resume;
- (void)pause;
- (void)stop;

@end
