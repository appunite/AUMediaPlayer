//
//  AUMediaConstants.h
//  AUMedia
//
//  Created by Dev on 2/15/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>

//Errors
#define kAUMediaItemNotFoundInLibraryErrorCode 1
#define kAUMediaItemPathNotFoundError 2
#define kAUMediaChromecastDeviceUnavailableErrorCode 3
#define kAUMediaLibraryFailedToWriteItemToDiskErrorCode 4

extern NSString *const AUMediaErrorDomain;

// Library notifications
extern NSString *const kAUMediaDownloadDidStartNotification;
extern NSString *const kAUMediaDownloadDidFinishNotification;
extern NSString *const kAUMediaDownloadDidFailToFinishNotification;
extern NSString *const kAUMediaDidFinishLocallyWritingItemToLibrary;

// Player notifications
extern NSString *const kAUMediaPlaybackStateDidChangeNotification;
extern NSString *const kAUMediaPlaybackDidReachEndNotification;
extern NSString *const kAUMediaPlayedItemDidChangeNotification;
extern NSString *const kAUMediaPlayerFailedToPlayItemNotification;
extern NSString *const kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey;
