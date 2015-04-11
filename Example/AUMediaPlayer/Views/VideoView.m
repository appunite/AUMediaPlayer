//
//  VideoView.m
//  AUMediaPlayer
//
//  Created by Dev on 3/5/15.
//  Copyright (c) 2015 lukasz.kasperek. All rights reserved.
//

#import "VideoView.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end
