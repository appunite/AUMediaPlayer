//
//  AUMediaLibrary.m
//  AUMedia
//
//  Created by Dev on 2/12/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "AUMediaLibrary.h"
#import "NSString+AUMedia.h"
#import "NSURL+AUMedia.h"
#import "AUMediaConstants.h"
#import "NSError+AUMedia.h"

@interface AUMediaLibrary()

@property (atomic, strong, readonly) NSMutableArray *currentlyDownloadingItems;

@end

@implementation AUMediaLibrary

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentlyDownloadingItems = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSArray *)downloadingItems {
    @synchronized(self) {
        return _currentlyDownloadingItems;
    }
}

#pragma mark - External methods

- (NSData *)itemData:(id<AUMediaItem>)item error:(NSError * __autoreleasing *)error {
    NSString *localPath = [self localPathForItem:item];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        NSData *data = [NSData dataWithContentsOfFile:localPath options:0 error:error];
        return data;
    } else {
        *error = [NSError au_itemNotFoundInLibrary];
        return nil;
    }
}

- (void)writeItem:(id<AUMediaItem>)item data:(NSData *)data attributes:(NSDictionary *)attributes {
    NSParameterAssert([item uid]);
    if ([item uid] == nil) {
        return;
    }
    
    NSString *path = [self generateLocalPathForItem:item];
    [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:attributes];
    [self saveItemToFileRegister:item];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDownloadedItemsListDidChangeNotification object:nil];
}

- (NSProgress *)downloadItem:(id<AUMediaItem>)item {
    NSParameterAssert([item uid]);
    if ([item uid] == nil) {
        return nil;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[item remotePath]]];
    
    NSProgress *progress = [[NSProgress alloc] init];
    
    @synchronized(self) {
        [_currentlyDownloadingItems addObject:item];
    }
    
    __weak __typeof__(self) wSelf = self;
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:[wSelf generateLocalPathForItem:item]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            [wSelf saveItemToFileRegister:item];
            NSLog(@"Completed download of item %@ by %@", [item title], [item author]);
            [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDownloadedItemsListDidChangeNotification object:nil];
        }
        @synchronized(wSelf) {
            [_currentlyDownloadingItems removeObject:item];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDownloadedItemsListDidChangeNotification object:nil];
    }];
    
    [downloadTask setTaskDescription:[item uid]];
    
    [downloadTask resume];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDownloadingItemsListDidChangeNotification object:nil];
    
    return progress;
}

- (NSProgress *)progressObjectForItem:(id<AUMediaItem>)item {
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskForItem:item];
    
    if (!downloadTask) {
        return nil;
    }
    
    NSProgress *progress = [self downloadProgressForTask:downloadTask];
    return progress;
}

- (void)downloadItemCollection:(id<AUMediaItemCollection>)collection {
    for (id obj in collection.mediaItems) {
        NSAssert([obj conformsToProtocol:@protocol(AUMediaItem)], @"Item in album should conform to AUMediaItem protocol");
        [self downloadItem:obj];
    }
}

- (void)cancelDownloadForItem:(id<AUMediaItem>)item {
    [[self downloadTaskForItem:item] cancel];
}

- (void)removeItemFromLibrary:(id<AUMediaItem>)item error:(NSError *__autoreleasing *)error {
    if (![self itemIsDownloaded:item]) {
        *error = [NSError au_itemNotFoundInLibrary];
        return;
    }
    
    NSString *localPath = [self localPathForItem:item];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:error];
        [self removeItemFromFileRegister:item];
    }
}

- (void)removeCollectionFromLibrary:(id<AUMediaItemCollection>)collecion error:(NSError * __autoreleasing*)error {
    for (id<AUMediaItem>item in [collecion mediaItems]) {
        [self removeItemFromLibrary:item error:error];
    }
}

- (void)cleanLibraryError:(NSError *__autoreleasing *)error {
    NSDictionary *allItems = [self allExistingItems];
    
    [allItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(AUMediaItem)]) {
            [self removeItemFromLibrary:obj error:error];
        }
    }];
    
    NSString *entireDirectoryPath = [NSString au_filePathWithLastPathComponent:@""];
    if ([[NSFileManager defaultManager] fileExistsAtPath:entireDirectoryPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:entireDirectoryPath error:error];
    }
}

- (BOOL)itemIsDownloaded:(id<AUMediaItem>)item {
    if ([item uid] == nil) {
        return NO;
    }
    
    NSDictionary *items = [self allExistingItems];
    if ([items objectForKey:[item uid]]) {
        return YES;
    }
    return NO;
}

- (BOOL)itemCollectionIsDownloaded:(id<AUMediaItemCollection>)collection {
    if (!collection || !collection.mediaItems || [collection mediaItems].count < 1) {
        return NO;
    }
    for (id<AUMediaItem>item in [collection mediaItems]) {
        if ([self itemIsDownloaded:item] == NO) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)localPathForItem:(id<AUMediaItem>)item {
    if ([item uid] == nil) {
        return nil;
    }
    if ([self itemIsDownloaded:item]) {
        return [self generateLocalPathForItem:item];
    }
    return nil;
}

- (NSDictionary *)allExistingItems {
    NSMutableDictionary *allItems = [[NSMutableDictionary alloc] init];
    
    NSDictionary *audioItems = [self existingItemsForType:AUMediaTypeAudio];
    [allItems addEntriesFromDictionary:audioItems];
    NSDictionary *videoItems = [self existingItemsForType:AUMediaTypeVideo];
    [allItems addEntriesFromDictionary:videoItems];
    NSDictionary *otherItems = [self existingItemsForType:AUMediaTypeUnknown];
    [allItems addEntriesFromDictionary:otherItems];
    
    return allItems;
}

- (NSDictionary *)existingItemsForType:(AUMediaType)type {
    NSString *typePath = [self persistancePathForType:type];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:typePath]) {
        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithFile:typePath];
        
        if (dict && [dict isKindOfClass:[NSDictionary class]]) {
            return dict;
        }
    }
    return [[NSDictionary alloc] init];
}

#pragma mark - Private methods

- (NSString *)generateLocalPathForItem:(id<AUMediaItem>)item {
    return [NSString au_filePathWithLastPathComponent:[NSString au_lastPathComponentForItem:item]];
}

- (void)saveItemToFileRegister:(id<AUMediaItem>)item {
    NSString *writePath = [self persistancePathForType:[item itemType]];
    NSMutableDictionary *writeDictionary = [[self existingItemsForType:[item itemType]] mutableCopy];
    
    if ([writeDictionary objectForKey:[item uid]]) {
        [writeDictionary removeObjectForKey:[item uid]];
    }
    if (!writeDictionary) {
        writeDictionary = [NSMutableDictionary dictionary];
    }
    
    [writeDictionary setObject:item forKey:[item uid]];
    
    __unused BOOL writeSuccess = [NSKeyedArchiver archiveRootObject:writeDictionary toFile:writePath];
    
    NSAssert(writeSuccess, @"There was an error while saving item");
}

- (void)removeItemFromFileRegister:(id<AUMediaItem>)item {
    
    NSString *writePath = [self persistancePathForType:[item itemType]];
    NSMutableDictionary *writeDictionary = [[self existingItemsForType:[item itemType]] mutableCopy];
    
    if ([writeDictionary objectForKey:[item uid]]) {
        [writeDictionary removeObjectForKey:[item uid]];
    }
    
    __unused BOOL writeSuccess = [NSKeyedArchiver archiveRootObject:writeDictionary toFile:writePath];
    
    NSAssert(writeSuccess, @"There was an error while saving item");
}

- (NSString *)persistancePathForType:(AUMediaType)type {
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *typePath = nil;
    
    switch (type) {
        case AUMediaTypeAudio:
            typePath = kAUMediaAudioDocuments;
            break;
        case AUMediaTypeVideo:
            typePath = kAUMediaVideoDocuments;
            break;
        case AUMediaTypeUnknown:
            typePath = kAUMediaOtherDocuments;
            break;
        default:
            break;
    }
    
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:typePath];
}

- (NSURLSessionDownloadTask *)downloadTaskForItem:(id<AUMediaItem>)item {
    for (NSURLSessionDownloadTask *task in self.downloadTasks) {
        if ([task.taskDescription isEqualToString:[item uid]]) {
            return task;
        }
    }
    return nil;
}

@end
