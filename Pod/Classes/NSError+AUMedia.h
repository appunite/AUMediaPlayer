//
//  NSError+AUMedia.h
//  AUMedia
//
//  Created by Dev on 2/16/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (AUMedia)

+ (NSError *)au_itemNotFoundInLibrary;
+ (NSError *)au_itemNotAvailableToPlayError;

@end
