//
//  NSError+AUMedia.m
//  AUMedia
//
//  Created by Dev on 2/16/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "NSError+AUMedia.h"
#import "AUMediaConstants.h"

@implementation NSError (AUMedia)

+ (NSError *)au_itemNotFoundInLibrary {
    NSDictionary * userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Item could not be removed, because it wasn't present in the library.", nil)};
    NSError * error = [NSError errorWithDomain:AUMediaErrorDomain code:kAUMediaItemNotFoundInLibraryErrorCode userInfo:userInfo];
    return error;
}

+ (NSError *)au_itemNotAvailableToPlayError {
    NSDictionary * userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Item could not be played, because player isn't able to determine neither its local nor remote path.", nil)};
    NSError * error = [NSError errorWithDomain:AUMediaErrorDomain code:kAUMediaItemPathNotFoundError userInfo:userInfo];
    return error;
}

+ (NSError *)au_failedToWriteItemToLibraryError {
    NSDictionary * userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Failed to write item to disk.", nil)};
    NSError * error = [NSError errorWithDomain:AUMediaErrorDomain code:kAUMediaLibraryFailedToWriteItemToDiskErrorCode userInfo:userInfo];
    return error;
}

+ (NSError *)au_chromecastDeviceUnavailable {
    NSDictionary * userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"There is no chromecast device available right now. Please check your connection and try again.", nil)};
    NSError * error = [NSError errorWithDomain:AUMediaErrorDomain code:kAUMediaChromecastDeviceUnavailableErrorCode userInfo:userInfo];
    return error;
}

@end
