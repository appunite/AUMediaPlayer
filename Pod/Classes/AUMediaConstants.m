//
//  AUMediaConstants.m
//  AUMedia
//
//  Created by Dev on 2/15/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "AUMediaConstants.h"

// Errors

NSString *const AUMediaErrorDomain = @"com.AUMedia";

// Library notofocations
NSString *const kAUMediaDownloadingItemsListDidChangeNotification = @"kAUMediaDownloadingItemsListDidChangeNotification";
NSString *const kAUMediaDownloadedItemsListDidChangeNotification = @"kAUMediaDownloadedItemsListDidChangeNotification";

// Player notifications
NSString *const kAUMediaPlaybackStateDidChangeNotification = @"kAUMediaPlaybackStateDidChangeNotification";
NSString *const kAUMediaPlaybackDidReachEndNotification = @"kAUMediaPlaybackDidReachEndNotification";
NSString *const kAUMediaPlayedItemDidChangeNotification = @"kAUMediaPlayedItemDidChangeNotification";
NSString *const kAUMediaPlayerFailedToPlayItemNotification = @"kAUMediaPlayerFailedToPlayItemNotification";
NSString *const kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey = @"kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey";