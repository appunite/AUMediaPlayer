//
//  ExampleItem.h
//  AUMediaPlayer
//
//  Created by Dev on 3/5/15.
//  Copyright (c) 2015 lukasz.kasperek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AUMediaPlayer/AUMediaPlayer.h>

@interface ExampleMediaItem : NSObject <AUMediaItem>

@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;

@property (nonatomic, strong) NSString *remotePath;

@property (nonatomic, strong) NSString *fileTypeExtension;

@end




@interface ExampleAudioItem : ExampleMediaItem
@end

@interface ExampleVideoItem : ExampleMediaItem
@end


@interface ExampleMediaCollection :NSObject <AUMediaItemCollection>

@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *mediaItems;

@end
