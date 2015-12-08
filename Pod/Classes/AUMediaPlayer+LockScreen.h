//
//  AUMediaPlayer+LockScreen.h
//  Pods
//
//  Created by Dev on 5/11/15.
//
//

#import "AUMediaPlayer.h"

/*********************************************************************
 
 Add this code to AppDelegate in order to be able to receive remote control events
 
 - (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        [[AUMedia sharedInstance] handleLockScreenEvent:receivedEvent];
    }
 }
 
 *********************************************************************/

@interface AUMediaPlayer (LockScreen)

/**
 *  Method handling remote control events regarding playback when app is in background.
 *  @warning You DO NOT call it by yourself. Suitable method should be added to AppDelegate.
 *  Just copy-paste it from the top of this file.
 *
 *  @param receivedEvent
 */
- (void)handleLockScreenEvent:(UIEvent *)receivedEvent;

@end
