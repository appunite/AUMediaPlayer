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
NSString *const kAUMediaDownloadDidStartNotification = @"kAUMediaDownloadDidStartNotification";
NSString *const kAUMediaDownloadDidFinishNotification = @"kAUMediaDownloadDidFinishNotification";
NSString *const kAUMediaDownloadDidFailToFinishNotification = @"kAUMediaDownloadDidFailToFinishNotification";
NSString *const kAUMediaDidFinishLocallyWritingItemToLibrary = @"kAUMediaDidFinishLocallyWritingItemToLibrary";

// User info keys
NSString *const kAUMediaItemIdentifierUserInfoKey = @"kAUMediaItemIdentifierUserInfoKey";

// Player notifications
NSString *const kAUMediaPlaybackStateDidChangeNotification = @"kAUMediaPlaybackStateDidChangeNotification";
NSString *const kAUMediaPlaybackDidReachEndNotification = @"kAUMediaPlaybackDidReachEndNotification";
NSString *const kAUMediaPlayedItemDidChangeNotification = @"kAUMediaPlayedItemDidChangeNotification";
NSString *const kAUMediaPlayerFailedToPlayItemNotification = @"kAUMediaPlayerFailedToPlayItemNotification";
NSString *const kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey = @"kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey";