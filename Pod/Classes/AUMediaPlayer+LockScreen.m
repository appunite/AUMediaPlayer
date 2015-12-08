//
//  AUMediaPlayer+LockScreen.m
//  Pods
//
//  Created by Dev on 5/11/15.
//
//

#import "AUMediaPlayer+LockScreen.h"

@implementation AUMediaPlayer (LockScreen)

- (void)handleLockScreenEvent:(UIEvent *)receivedEvent {
    switch (receivedEvent.subtype) {
        case UIEventSubtypeRemoteControlPause:
            [self pause];
            break;
            
        case UIEventSubtypeRemoteControlPlay:
            [self play];
            break;
            
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self playPrevious];
            break;
            
        case UIEventSubtypeRemoteControlNextTrack:
            [self playNext];
            break;
            
        default:
            break;
    }
    
}

@end
