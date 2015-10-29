//
//  AUMediaLibrary.m
//  AUMedia
//
//  Created by Dev on 2/12/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "AUMediaLibrary.h"
#import "NSString+AUMedia.h"
#import "AUMediaConstants.h"
#import "NSError+AUMedia.h"

@interface AUMediaLibrary()

@property (nonatomic, strong) NSMutableDictionary *currentlyDownloadingItems;

@end

@implementation AUMediaLibrary

#pragma mark -
#pragma mark Initialization

- (instancetype)initWithNSURLSessionConfiguration:(NSURLSessionConfiguration *)configuration
                                     iCloudBackup:(BOOL)backupToiCloud
                             saveItemPersistently:(BOOL)persistently {
    
    self = [super initWithSessionConfiguration:configuration];
    
    if (self) {
        [self configureDownloadFinished];
        [self configureBackgroundSessionFinished];
        _saveItemsPersistently = persistently;
        _backupToiCloud = backupToiCloud && persistently;
    }
    
    return self;
}

- (void)configureDownloadFinished {
    
    __weak __typeof__(self) wSelf = self;
    
    [self setDownloadTaskDidFinishDownloadingBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *filePath) {
        
        __strong __typeof__(wSelf) strongSelf = wSelf;
        
        if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSUInteger statusCode = [(NSHTTPURLResponse *)downloadTask.response statusCode];
            if (statusCode != 200) {
                NSLog(@"%@ failed (statusCode = %ld)", [downloadTask.originalRequest.URL lastPathComponent], statusCode);
                return nil;
            }
        }
        
        if (strongSelf) {
            
            id <AUMediaItem> item = [strongSelf downloadingItemForTaskIdentifier:downloadTask.taskIdentifier];
            [strongSelf saveItemToFileRegister:item];
            
            if (!strongSelf.backupToiCloud) {
                NSError *skipError = nil;
                [filePath setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey
                                     error:&skipError];
                if (skipError) {
                    NSLog(@"Error while marking file as skipped: %@", skipError);
                }
            }
            
            NSLog(@"Completed download of item %@", [item title]);
            
            @synchronized(strongSelf) {
                if (item && [strongSelf isItemInDownloading:item]) {
                    [strongSelf removeDownloadingItemForID:downloadTask.taskIdentifier];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDownloadDidFinishNotification object:nil];
            });
            
            return [NSURL fileURLWithPath:[strongSelf generateLocalPathForItem:item]];
        }
        
        return nil;
    }];
    
    [self setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        if (error) {
            NSLog(@"%@: %@", [task.originalRequest.URL lastPathComponent], error);
            
            __strong __typeof__(wSelf) strongSelf = wSelf;
            
            if (strongSelf) {
                
                id <AUMediaItem> item = [strongSelf downloadingItemForTaskIdentifier:task.taskIdentifier];
                
                @synchronized(strongSelf) {
                    if (item && [strongSelf isItemInDownloading:item]) {
                        [strongSelf removeDownloadingItemForID:task.taskIdentifier];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDownloadDidFailToFinishNotification object:nil];
                });
            }
        }
    }];
}

- (void)configureBackgroundSessionFinished
{
    typeof(self) __weak weakSelf = self;
    
    [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        if (weakSelf.savedCompletionHandler) {
            weakSelf.savedCompletionHandler();
            weakSelf.savedCompletionHandler = nil;
        }
    }];
}

#pragma mark -
#pragma mark External methods

- (NSArray *)downloadingItems {
    @synchronized(self) {
        return [self.currentlyDownloadingItems allValues];
    }
}

- (NSData *)itemData:(id<AUMediaItem>)item error:(NSError * __autoreleasing *)error {
    NSString *localPath = [self localPathForItem:item];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        NSData *data = [NSData dataWithContentsOfFile:localPath options:0 error:error];
        return data;
    } else {
        if (error != NULL) *error = [NSError au_itemNotFoundInLibrary];
        return nil;
    }
}

- (void)writeItem:(id<AUMediaItem>)item data:(NSData *)data attributes:(NSDictionary *)attributes error:(NSError *__autoreleasing*)error {
    NSParameterAssert([item uid]);
    if ([item uid] == nil) {
        return;
    }
    
    NSString *path = [self generateLocalPathForItem:item];
    
    if ([[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:attributes]) {
        [self saveItemToFileRegister:item];
        
        if (!self.backupToiCloud) {
            
            NSError *skipError = nil;
            [self addSkipBackupAttributeToFileAtPath:path error:&skipError];
            
            if (skipError) {
                NSLog(@"Error while marking file as skipped: %@", skipError);
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDidFinishLocallyWritingItemToLibrary object:nil];
    } else {
        if (error != NULL) *error = [NSError au_failedToWriteItemToLibraryError];
    }
}

- (void)downloadItem:(id<AUMediaItem>)item {
    NSParameterAssert([item uid]);
    if ([item uid] == nil) {
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[item remotePath]]];
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:nil destination:nil completionHandler:nil];
    
    [self addItemToDownloadingItems:item forTaskID:downloadTask.taskIdentifier];
    
    [downloadTask resume];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaDownloadDidStartNotification object:nil];
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
        if (error != NULL) *error = [NSError au_itemNotFoundInLibrary];
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
    
    NSString *entireDirectoryPath = [NSString au_filePathWithLastPathComponent:@"" persistent:self.saveItemsPersistently];
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
        NSString *localPath = [self generateLocalPathForItem:item];
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            return YES;
        }
        
        // If no item was found, it must have been deleted by system due to system - is should be also removed from downloaded files register
        [self removeItemFromFileRegister:item];
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

#pragma mark -
#pragma mark Private methods

- (NSString *)generateLocalPathForItem:(id<AUMediaItem>)item {
    return [NSString au_filePathWithLastPathComponent:[NSString au_lastPathComponentForItem:item] persistent:self.saveItemsPersistently];
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
    
    BOOL writeSuccess = [NSKeyedArchiver archiveRootObject:writeDictionary toFile:writePath];
    
    if (writeSuccess && !self.backupToiCloud) {
        
        NSError *error = nil;
        [self addSkipBackupAttributeToFileAtPath:writePath error:&error];
        if (error) {
            NSLog(@"Error ocurred: %@", error);
        }
    }
    
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

#pragma mark -
#pragma mark Downloading items

- (void)addItemToDownloadingItems:(id<AUMediaItem>)item forTaskID:(NSUInteger)uid {
    
    @synchronized(self) {
        NSMutableDictionary *downloadingItems = self.currentlyDownloadingItems;
        downloadingItems[@(uid)] = item;
        [NSKeyedArchiver archiveRootObject:downloadingItems toFile:[NSString au_tempDownloadingDirectory]];
    }
}

- (void)removeDownloadingItemForID:(NSUInteger)uid {
    
    @synchronized(self) {
        NSMutableDictionary *downloadingItems = self.currentlyDownloadingItems;
        [downloadingItems removeObjectForKey:@(uid)];
        [NSKeyedArchiver archiveRootObject:downloadingItems toFile:[NSString au_tempDownloadingDirectory]];
    }
}

- (id<AUMediaItem>)downloadingItemForTaskIdentifier:(NSUInteger)uid {
    
    if ([self.currentlyDownloadingItems objectForKey:@(uid)]) {
        return [self.currentlyDownloadingItems objectForKey:@(uid)];
    }
    
    return nil;
}

- (BOOL)isItemInDownloading:(id<AUMediaItem>)item {
    
    __block BOOL contains = NO;
    
    [self.currentlyDownloadingItems enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, id<AUMediaItem> obj, BOOL *stop) {
        
        if ([[obj uid] isEqualToString:[item uid]]) {
            contains = YES;
            *stop = YES;
        }
    }];
    
    return contains;
}

- (NSMutableDictionary *)currentlyDownloadingItems {
    
    if (!_currentlyDownloadingItems) {
        
        NSString *path = [NSString au_tempDownloadingDirectory];
        _currentlyDownloadingItems = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        
        if (!_currentlyDownloadingItems) {
            _currentlyDownloadingItems = [NSMutableDictionary dictionary];
        }
    }
    
    return _currentlyDownloadingItems;
}

#pragma mark -
#pragma mark Helpers

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
        
        id<AUMediaItem> temp = [self downloadingItemForTaskIdentifier:task.taskIdentifier];
        if ([[temp uid] isEqualToString:[item uid]]) {
            return task;
        }
    }
    return nil;
}

- (BOOL)addSkipBackupAttributeToFileAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    return [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:error];
}

@end
