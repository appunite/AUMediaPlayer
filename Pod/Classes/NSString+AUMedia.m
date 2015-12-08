//
//  NSString+AUMedia.m
//  AUMedia
//
//  Created by Dev on 2/12/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "NSString+AUMedia.h"

@implementation NSString (AUMedia)

+ (NSString *)au_lastPathComponentForItem:(id<AUMediaItem>)item {
    
    return [NSString stringWithFormat:@"t_%ld_i_%@%@", (long)[item itemType], [item uid], [item fileTypeExtension]];
}

+ (NSString *)au_filePathWithLastPathComponent:(NSString *)lastPath persistent:(BOOL)persistent {
    
    if (!lastPath) {
        return nil;
    }
    
    NSString *documentsDirectoryPath;
    
    if (persistent) {
        documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    } else {
        documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    }
    return [documentsDirectoryPath stringByAppendingPathComponent:lastPath];

}

+ (NSString *)au_tempDownloadingDirectory {
    
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"aumedialibrary_downloading_temp"];
}

@end
