//
//  NSString+AUMedia.h
//  AUMedia
//
//  Created by Dev on 2/12/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AUMediaItem.h"

@interface NSString (AUMedia)

+ (NSString *)au_lastPathComponentForItem:(id<AUMediaItem>)item;
+ (NSString *)au_filePathWithLastPathComponent:(NSString *)lastPath;

@end
