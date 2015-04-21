//
//  AUMedia.h
//  AUMedia
//
//  Created by Dev on 2/11/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AUMediaLibrary.h"
#import "AUMediaConstants.h"

/*********************************************************************

Add this to application:didFinishLaunchingWithOptions: method to enable background playback

[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

Add this code to AppDelegate in order to be able to receive remote control events

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        [[AUMedia sharedInstance] handleLockScreenEvent:receivedEvent];
    }
}
 
 *********************************************************************/

/*********************************************************************

OBSERVER MACRO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == AUMediaPlaybackTimeValidityObservationContext) {
        BOOL playbackTimesValidaity = [change[NSKeyValueChangeNewKey] boolValue];
        
    } else if (context == AUMediaPlaybackCurrentTimeObservationContext) {
        NSUInteger currentPlaybackTime = [change[NSKeyValueChangeNewKey] integerValue];
        
    } else if (context == AUMediaPlaybackDurationObservationContext) {
        NSUInteger currentDuration = [change[NSKeyValueChangeNewKey] integerValue];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

 ************************************************************************/

/**
 *  Void unique pointers recommended for unique identification of contexts in KVO of playback time properties.
 *  Example values below. Recommended to copy-paste them to yout implementation file.
 */

/**************************************
 static void *AUMediaPlaybackCurrentTimeObservationContext = &AUMediaPlaybackCurrentTimeObservationContext;
 static void *AUMediaPlaybackDurationObservationContext = &AUMediaPlaybackDurationObservationContext;
 static void *AUMediaPlaybackTimeValidityObservationContext = &AUMediaPlaybackTimeValidityObservationContext;
 **************************************/

/**
 *  Playback status enumartion type
 */
typedef NS_ENUM(NSUInteger, AUMediaPlaybackStatus){
    /**
     *  Indicates that no item is loaded yet to player
     */
    AUMediaPlaybackStatusPlayerInactive,
    /**
     *  Indicates that playback is currently on.
     */
    AUMediaPlaybackStatusPlaying,
    /**
     *  Indicates that playback is paused and may be resumed by calling play method.
     */
    AUMediaPlaybackStatusPaused
};

@interface AUMediaPlayer : NSObject

//One can get visual output by setting this player object as a player property of AVPlayerLayer object
/**
 *  Used player property. Its main reason to be here is to enable setting it as player property of
 *  AVPlayerLayer in order to get visual output for video playback.
 *  @warning Is is NOT RECOMMENDED to call play or pause directly on this property.
 */
@property (nonatomic, strong, readonly) AVPlayer *player;
/**
 *  Library class' interface contains methods referring to media persistance store.
 *  Enables actions such as download, adding, removing items.
 */
@property (nonatomic, strong, readonly) AUMediaLibrary *library;

/**
 *  Item corresponding to AVPlayerItem that is currently loaded to player.
 */
@property (nonatomic, strong, readonly) id<AUMediaItem> nowPlayingItem;
/**
 *  Set this property in your subclass for example in prepareForCurrentItemReplacementWithItem: method
 *  and ot will be automatically added as lockscreen artowrk.
 */
@property (nonatomic, strong) UIImage *nowPlayingCover;
/**
 *  Recently played audio and video items. This properties may be helpful when
 *  implementing solutions, where audio and video are played alternately and one
 *  wants to resume audio playback after video playback.
 */
@property (nonatomic, strong, readonly) id<AUMediaItem> recentlyPlayedAudioItem;
@property (nonatomic, strong, readonly) id<AUMediaItem> recentlyPlayedVideoItem;

//Recomended way to implement playback progress is KVO for this properties
/**
 *  Properties used to track playback times. When playbackTimesAreValid is set to NO
 *  currentPlaybackTime and duration values should not be displayed to user.
 
 *  It is strongly recommended to use KVO to get notified about these properties state.
 *  Observer macro is available at the top of this file.
 */
@property (nonatomic, readonly) BOOL playbackTimesAreValid;
@property (nonatomic, readonly) NSUInteger currentPlaybackTime;
@property (nonatomic, readonly) NSUInteger duration;

/**
 *  Properties that mey be useful when displaying additional playback info to user.
 *  Shuffle and repeat properties indicate if respectively shuffle and repeat are currently on.
 */
@property (nonatomic, readonly) BOOL shuffle;
@property (nonatomic, readonly) BOOL repeat;
@property (nonatomic, readonly) NSUInteger currentlyPlayedTrackIndex;
@property (nonatomic, readonly) NSUInteger queueLength;
/**
 *  Contains id<AUMediaItem> objects that are currently in queue.
 */
@property (nonatomic, readonly) NSArray *playingQueue;
/**
 *  Current playback status.
 */
@property (nonatomic, readonly) AUMediaPlaybackStatus playbackStatus;
/**
 *  If thos flag is set to YES, after interruptions like phone calls, the playback will be resumed.
 *  Defaults to YES.
 */
@property (nonatomic) BOOL playbackIsResumedAfterInterruptions;

+ (instancetype)sharedInstance;

/**
 *  Plays given item.
 *
 *  @param item  Item to play.
 *  @param error Error is assigned when playback fails.
 */
- (void)playItem:(id<AUMediaItem>)item error:(NSError * __autoreleasing *)error;
/**
 *  Creates queue from mediaItems array of given collection and starts playing it starting from the first one.
 *
 *  @param collection Object conforming to AUMediaCollection protocol.
 *  @param error Error is assigned when playback fails.
 */
- (void)playItemQueue:(id<AUMediaItemCollection>)collection error:(NSError * __autoreleasing *)error;
/**
 *  Plays given item while maintaining current queue.
 *
 *  @param item  Item to play.
 *  @param error Error is assigned when playback fails.
 */
- (void)updatePlayerWithItem:(id<AUMediaItem>)item error:(NSError * __autoreleasing*)error;
/**
 *  Resumes playback.
 */
- (void)play;
/**
 *  Pauses playback.
 */
- (void)pause;
/**
 *  Stops playback and removes currently plauing item.
 *  Playback status becomes AUMediaPlaybackStatusPlayerInactive.
 */
- (void)stop;

/**
 *  Plays next track from the queue.
 *  If currently plaing item is last in the queue it jumps to the first one and carries on
 *  when repeat is on and pauses if it's off.
 */
- (void)playNext;
/**
 *  Plays previous track from the queue.
 *  If playback is on 3. second or greater it just seeks to second 0.
 *  When currently played track's index in the queue is 0, it jums to the last track
 *  in the queue if repear is on and stays on the first one if it's off.
 */
- (void)playPrevious;
/**
 *  Seeks to given playback moment.
 *  Accepts values from 0 to 1.
 *
 *  @param moment playback moment given by floating point number from 0 to 1
 */
- (void)seekToMoment:(double)moment;

- (void)setShuffleOn:(BOOL)shuffle;
- (void)setRepeatOn:(BOOL)repeat;

/**
 * Gets called before item replacement. Enables interaction with items and queues being played before new item appers.
 * Doesn't need to call super, since it's abstract method.
 *
 * @param item item that is going to replace current item
 */
- (void)prepareForCurrentItemReplacementWithItem:(id<AUMediaItem>)item;
/**
 *  Sets player state to specific item, queue and playback time. Enables setting player to some specific state.
 *
 *  @param item  item to be played first
 *  @param queue queue to replace current queue
 *  @param time  time the item is to be played from
 */
- (void)restorePlayerStateWithItem:(id<AUMediaItem>)item queue:(NSArray *)queue playbackTime:(CMTime)time error:(NSError *__autoreleasing *)error;

/**
 *  Method handling remote control events regarding playback when app is in background.
 *  @warning You DO NOT call it by yourself. Suitable method should be added to AppDelegate.
 *  Just copy-paste it from the top of this file.
 *
 *  @param receivedEvent
 */
- (void)handleLockScreenEvent:(UIEvent *)receivedEvent;

@end

