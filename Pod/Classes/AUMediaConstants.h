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

extern NSString *const AUMediaErrorDomain;

// Library notifications
extern NSString *const kAUMediaDownloadingItemsListDidChangeNotification;
extern NSString *const kAUMediaDownloadedItemsListDidChangeNotification;

// Player notifications
extern NSString *const kAUMediaPlaybackStateDidChangeNotification;
extern NSString *const kAUMediaPlaybackDidReachEndNotification;
extern NSString *const kAUMediaPlayedItemDidChangeNotification;
extern NSString *const kAUMediaPlayerFailedToPlayItemNotification;
extern NSString *const kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey;
