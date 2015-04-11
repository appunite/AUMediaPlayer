//
//  NSURL+AUMedia.m
//  AUMedia
//
//  Created by Dev on 2/12/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "NSURL+AUMedia.h"
#import "NSString+AUMedia.h"

@implementation NSURL (AUMedia)

+ (NSURL *)au_fileURLWithLastPathComponent:(NSString *)lastPath {
    
    if (!lastPath) {
        return nil;
    }
    
    return [NSURL fileURLWithPath:[NSString au_filePathWithLastPathComponent:lastPath]];
    
}

@end
