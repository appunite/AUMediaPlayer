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
#import "AUCast.h"

/*********************************************************************

Add this to application:didFinishLaunchingWithOptions: method to enable background playback

[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
 
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

/**
 *  Mode of tracks repetition
 */
typedef NS_ENUM(NSUInteger, AUMediaRepeatMode){
    /**
     *  Doesn't repeat. Stops playback at the end of the queue.
     */
    AUMediaRepeatModeOff,
    /**
     *  Starts first track of the queue, when queue ends.
     */
    AUMediaRepeatModeOn,
    /**
     *  When playback of the track finishes, same track is started from the beginning.
     */
    AUMediaRepeatModeOneSong
};

/**
 *  Receiver enumartion type
 */
typedef NS_ENUM(NSUInteger, AUMediaReceiverType){
    /**
     *  Indicates that all media are playing locally
     */
    AUMediaReceiverNone,
    /**
     *  Indicates that chromecast streaming is active
     */
    AUMediaReceiverChromecast
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
 *  This property gives access to chromecast fuctionality
 */
@property (nonatomic, strong, readonly) AUCast *chromecastManager;

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
@property (nonatomic, readonly) AUMediaRepeatMode repeat;
/**
 *  Currently played track index will be -1, when there is no track in the queue
 */
@property (nonatomic, readonly) NSInteger currentlyPlayedTrackIndex;
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
 *  It informs on which device is playing.
 */
@property (nonatomic, readonly) AUMediaReceiverType receiver;
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
 *  Plays track from currently played queue, either shuffled or regular.
 *  Assert is triggered when index exceeds current queue length.
 *
 *  @param index of track in current queue
 */
- (void)playItemFromCurrentQueueAtIndex:(NSUInteger)index;
/**
 *  Plays given item if it's available in the current queue.
 *
 *  @param item to play
 *
 *  @return YES if given item is available in current queue, NO otherwise
 */
- (BOOL)tryPlayingItemFromCurrentQueue:(id<AUMediaItem>)item;
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
- (void)setRepeatMode:(AUMediaRepeatMode)repeat;
/**
 *  Toggles through available modes
 */
- (void)toggleRepeatMode;

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
 * Use this method to change receiver type. If change is possible it returns YES.
 *
 * @param receiver New receiver type
 */

#pragma mark -
#pragma mark Switching receivers

- (void)changeReceviverToChromecastTypeWithChromecastDevicesViewController:(UIViewController *)devicesController
                                            currentlyVisibleViewController:(UIViewController *)visibleViewController
                                                 connectionCompletionBlock:(AUCastConnectCompletionBlock)completionBlock;
- (void)setLocalPlayback;
- (void)switchPlaybackToCurrentReceiver;
- (void)stopChromecast;

#pragma mark -
#pragma mark Chromecast section

- (BOOL)isItemCurrentlyPlayedOnChromecast:(id<AUMediaItem>)item;

@end

