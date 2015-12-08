//
//  ExampleItem.m
//  AUMedia
//
//  Created by Dev on 2/19/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "ExampleItem.h"

@implementation ExampleMediaItem

- (NSString *)fileTypeExtension {
    return @".dat";
}

- (AUMediaType)itemType {
    return AUMediaTypeAudio;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_author forKey:@"author"];
    [aCoder encodeObject:_title forKey:@"title"];
    [aCoder encodeObject:_remotePath forKey:@"remotePath"];
    [aCoder encodeObject:_uid forKey:@"uid"];
    [aCoder encodeObject:_fileTypeExtension forKey:@"fileTypeExtension"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [[ExampleMediaItem alloc] init];
    if (self) {
        _author = [aDecoder decodeObjectForKey:@"author"];
        _title = [aDecoder decodeObjectForKey:@"title"];
        _uid = [aDecoder decodeObjectForKey:@"uid"];
        _remotePath = [aDecoder decodeObjectForKey:@"remotePath"];
        _fileTypeExtension = [aDecoder decodeObjectForKey:@"fileTypeExtension"];
    }
    return self;
}

@end

@implementation ExampleAudioItem

- (NSString *)fileTypeExtension {
    return @".mp3";
}

@end

@implementation ExampleVideoItem

- (NSString *)fileTypeExtension {
    return @".mp4";
}

@end



@implementation ExampleMediaCollection

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_author forKey:@"author"];
    [aCoder encodeObject:_title forKey:@"title"];
    [aCoder encodeObject:_uid forKey:@"uid"];
    [aCoder encodeObject:_mediaItems forKey:@"mediaItems"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [[ExampleMediaCollection alloc] init];
    if (self) {
        _author = [aDecoder decodeObjectForKey:@"author"];
        _title = [aDecoder decodeObjectForKey:@"title"];
        _uid = [aDecoder decodeObjectForKey:@"uid"];
        _mediaItems = [aDecoder decodeObjectForKey:@"mediaItems"];
    }
    return self;
}

- (BOOL)containsMediaType:(AUMediaType)type {
    if (type == AUMediaTypeAudio) {
        return YES;
    } else {
        return NO;
    }
}

@end



