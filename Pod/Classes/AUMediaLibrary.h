//
//  AUMediaLibrary.h
//  AUMedia
//
//  Created by Dev on 2/12/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "AFURLSessionManager.h"
#import "AUMediaItem.h"

static NSString *kAUMediaAudioDocuments = @"AUMediaPersisatnceStoreAudio";
static NSString *kAUMediaVideoDocuments = @"AUMediaPersisatnceStoreVideo";
static NSString *kAUMediaOtherDocuments = @"AUMediaPersistanceStoreOthers";

@interface AUMediaLibrary : AFURLSessionManager

/**
 *  Downloads given item.
 *
 *  @param item Item object conforming to AUMediaItem protocol.
 *
 *  @return NSProgress class object indicating download progress state.
 */
- (NSProgress *)downloadItem:(id<AUMediaItem>)item;
/**
 *  Gets NSProgress class object for item that is already downloading.
 *
 *  @param item Item object conforming to AUMediaItem protocol.
 *
 *  @return NSProgress class object indicating download progress state.
 */
- (NSProgress *)progressObjectForItem:(id<AUMediaItem>)item;
/**
 *  Cancels download for given item.
 *
 *  @param item Currently downloading item object conforming to AUMediaItem protocol.
 */
- (void)cancelDownloadForItem:(id<AUMediaItem>)item;
/**
 *  Downloads all objects from mediaItems array.
 *
 *  @param collection Item object conforming to AUMediaItemCollection protocol.
 */
- (void)downloadItemCollection:(id<AUMediaItemCollection>)collection;

/**
 *  Gets NSData for downloaded item.
 *  @warning Use only for small files.
 *  Using on big files allocates all this data into memory and may cause crashes, especially on devices with low small RAM.
 *
 *  @param item  Item object conforming to AUMediaItem protocol.
 *  @param error Error informing about cause of unsuccessful action.
 *
 *  @return NSData object containg file data.
 */
- (NSData *)itemData:(id<AUMediaItem>)item error:(NSError * __autoreleasing *)error;
/**
 *  Adds item to library with NSData.
 *
 *  @param item       Item object conforming to AUMediaItem protocol.
 *  @param data       File data.
 *  @param attributes Write attributes such as modification date.
 */
- (void)writeItem:(id<AUMediaItem>)item data:(NSData *)data attributes:(NSDictionary *)attributes;

- (BOOL)itemIsDownloaded:(id<AUMediaItem>)item;
- (BOOL)itemCollectionIsDownloaded:(id<AUMediaItemCollection>)collection;
- (NSString *)localPathForItem:(id<AUMediaItem>)item;
- (void)removeItemFromLibrary:(id<AUMediaItem>)item error:(NSError * __autoreleasing*)error;
- (void)removeCollectionFromLibrary:(id<AUMediaItemCollection>)collecion error:(NSError * __autoreleasing*)error;
/**
 *  Removes all items from library and directory they were stored in.
 *
 *  @param error Error when performing clean.
 */
- (void)cleanLibraryError:(NSError * __autoreleasing*)error;

/**
 *  @return Dictionary containing all items.
 *  Keys in dictionary ale items' uid's and items ale values.
 *  If you want to get array of these items just call [dictionary allItems]
 */
- (NSDictionary *)allExistingItems;
/**
 *  @return Dictionary containing items for a given type.
 *  Keys in dictionary ale items' uid's and items ale values.
 *  If you want to get array of these items just call [dictionary allItems]
 */
- (NSDictionary *)existingItemsForType:(AUMediaType)type;
/**
 *  @return Array of all items that are currently downloading.
 */
- (NSArray *)downloadingItems;

@end
