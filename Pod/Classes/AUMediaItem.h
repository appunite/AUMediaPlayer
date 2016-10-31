//
//  AUMediaItem.h
//  AUMedia
//
//  Created by Dev on 2/11/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  Makes file management easier. Files with specific type may be requested from library.
 *  Doesn't affect used player though, since both video and audio use the same instance of AVPlayer.
 */
typedef NS_ENUM(NSInteger, AUMediaType){
    /**
     *  Enables storing all items other than audio and video.
     */
    AUMediaTypeUnknown,
    /**
     *  For video items.
     */
    AUMediaTypeVideo,
    /**
     *  For audio items
     */
    AUMediaTypeAudio,
};

@protocol AUMediaItem <NSObject, NSCoding>

@optional

- (BOOL)isLocalItem;
- (NSString *)localPath;

@required

/*****************************************************************************
 
 It is recommended to override isEqual and hash methods for objects implementing this protocol

****************************************************************************/

/**
 *  Item identifier. Must be unique.
 *
 *  @return unique identifier
 */
- (NSString *)uid;
- (NSString *)title;
/**
 *  Item must know its type.
 *
 *  @return AUMediaType enum case
 */
- (AUMediaType)itemType;
/**
 *  Remote path getter, item can be stream or downloaded from.
 *
 *  @return remote path
 */
- (NSString *)remotePath;
/**
 *  File type extension, that will be appended to path
 *
 *  @return file type extension
 */
- (NSString *)fileTypeExtension;

@optional

/**
 *  Author name
 *
 *  @return author name
 */
- (NSString *)author;

/**
 *  Path to artwork cover image
 *  Used to display media artwork on chromecast
 *
 *  @return file type extension
 */
- (NSString *)coverImagePath;

/**
 *  Local path getter. Item can be streamed from disk, even if it's not sotred by AUMediaPlayer itself
 *
 *  @return external to AUMediaLibrary local path
 */
- (NSString *)localPath;

@end

@protocol AUMediaItemCollection <NSObject, NSCoding>

@required

/**
 *  Array storing all items in album
 *
 *  @return array of items conforming to <AUMediaItem> protocol
 */
- (NSArray *)mediaItems; //media items must conform to protocol AUMediaItem

@optional

/*
 * These getters and methods are not requiered by AUMedia yet, but may in in the future and are recommended
 */
- (NSString *)uid;
- (NSString *)title;
- (NSString *)author;

- (BOOL)containsMediaType:(AUMediaType)type;
- (NSArray *)mediaTypes;



@end
