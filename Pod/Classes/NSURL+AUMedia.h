//
//  NSURL+AUMedia.h
//  AUMedia
//
//  Created by Dev on 2/12/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (AUMedia)

+ (NSURL *)au_fileURLWithLastPathComponent:(NSString *)lastPath;

@end
