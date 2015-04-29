//
//  AUCast.h
//  AUCastSDK
//
//  Created by Piotr Bernad on 21.04.2015.
//  Copyright (c) 2015 Appunite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleCast.h"

@protocol AUMediaItem;

typedef enum : NSUInteger {
    AUCastDeviceScannerStatusDevicesNotAvailable,
    AUCastDeviceScannerStatusDevicesAvailable
} AUCastDeviceScannerStatus;

typedef void (^AUCastDeviceScannerChangeBlock)(GCKDevice *inDevice, GCKDevice *outDevice, NSArray *allDevices);
typedef void (^AUCastDeviceScannerStatusChangeBlock)(AUCastDeviceScannerStatus status);
typedef void (^AUCastConnectCompletionBlock)(GCKDevice *connectedDevice, NSError *error);

@interface AUCast : NSObject

@property (nonatomic, strong) NSString *applicationID;

#pragma mark - Scanning for devices

@property (nonatomic, assign, getter=isSearchingDevices) BOOL searchDevices;
@property (nonatomic, copy) AUCastDeviceScannerChangeBlock devicesChangeBlock;
@property (nonatomic, copy) AUCastDeviceScannerStatusChangeBlock observeDevicesStatusBlock;

- (AUCastDeviceScannerStatus)deviceStatus;

#pragma mark - Connecting

- (void)connectToDevice:(GCKDevice *)device;

#pragma mark - Playing Media

- (void)playURL:(NSURL *)url contentType:(NSString *)contentType;
- (void)stop;

@end
