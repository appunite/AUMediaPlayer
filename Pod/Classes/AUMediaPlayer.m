//
//  AUMedia.m
//  AUMedia
//
//  Created by Dev on 2/11/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

// Observe for current Item.
// Bind AVPLayerItem with item

#import "AUMediaPlayer.h"
#import <objc/runtime.h>
#import "NSError+AUMedia.h"
#import "NSArray+AUMedia.h"

@interface AUMediaPlayer() <AUCastDelegate> {
    id _timeObserver;
    NSTimer *_chromecastObserverTimer;
    BOOL _shouldPlayWhenPlayerIsReady;
    BOOL _playing; // used to continue playback after buffer empties and loads again
    NSTimeInterval _localPlayerPlaybackTime; // used when pausing local player and resuming playback on chromecast
}
@property (nonatomic, readwrite) BOOL playbackTimesAreValid;
@property (nonatomic, readwrite) NSUInteger currentPlaybackTime;
@property (nonatomic, readwrite) NSUInteger duration;

@property (nonatomic, strong) NSArray *queue;
@property (nonatomic, strong) NSArray *shuffledQueue;

@end

static const void *AVPlayerItemAssociatedItem = &AVPlayerItemAssociatedItem;

static void *AVPlayerPlaybackRateObservationContext = &AVPlayerPlaybackRateObservationContext;
static void *AVPlayerPlaybackStatusObservationContext = &AVPlayerPlaybackStatusObservationContext;
static void *AVPlayerPlaybackCurrentItemObservationContext = &AVPlayerPlaybackCurrentItemObservationContext;
static void *AVPlayerPlaybackCurrentItemOldObservationContext = &AVPlayerPlaybackCurrentItemOldObservationContext;
static void *AVPlayerPlaybackBufferEmptyObservationContext = &AVPlayerPlaybackBufferEmptyObservationContext;

@implementation AUMediaPlayer

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static AUMediaPlayer *sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _library = [[AUMediaLibrary alloc] initWithiCloudBackup:[self backupToiCloud] saveItemPersistently:[self saveItemsPersistently]];
        _chromecastManager = [[AUCast alloc] init];
        _chromecastManager.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
        self.playbackIsResumedAfterInterruptions = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark AUMediaLibrary persistnace characteristics

- (BOOL)backupToiCloud {
    return NO;
}

- (BOOL)saveItemsPersistently {
    return YES;
}

#pragma mark -
#pragma mark Getters/setters

- (void)setQueue:(NSArray *)queue {
    _queue = queue;
    [self shuffleQueue];
}

- (void)setNowPlayingCover:(UIImage *)nowPlayingCover {
    _nowPlayingCover = nowPlayingCover;
    [self updateNowPlayingInfoCenterData];
}

#pragma mark -
#pragma mark Player actions

- (void)playItem:(id<AUMediaItem>)item error:(NSError *__autoreleasing *)error {
    
    if (!item) {
        NSAssert(NO, @"You must provide an item to play");
        return;
    }
    
    [self updatePlayerWithItem:item error:error];
    self.queue = @[item];
    
    if (_receiver == AUMediaReceiverChromecast) {
        [self startItemPlaybackOnChromecast:item];
    }
    
    [self play];
}

- (void)playItemQueue:(id<AUMediaItemCollection>)collection error:(NSError *__autoreleasing *)error {
    
    if (!collection.mediaItems || collection.mediaItems.count == 0) {
        NSAssert(NO, @"Media collection must contain at least one item");
        return;
    }
    
    NSArray *items = collection.mediaItems;
    NSArray *shuffledItems = [collection.mediaItems shuffle];
    id<AUMediaItem>item = _shuffle ? [shuffledItems objectAtIndex:0] : [items objectAtIndex:0];

    [self updatePlayerWithItem:item error:error];
    
    _queue = items;
    _shuffledQueue = shuffledItems;
    
    if (_receiver == AUMediaReceiverChromecast) {
        [self startItemPlaybackOnChromecast:item];
    }
    
    [self play];
}

- (void)play {
    
    if (self.receiver == AUMediaReceiverChromecast) {
        [self.chromecastManager resume];
        return;
    }
    
    if (_player.status == AVPlayerStatusReadyToPlay) {
        [_player play];
    } else {
        _shouldPlayWhenPlayerIsReady = YES;
    }
    _playing = YES;
}

- (void)pause {
    if (self.receiver == AUMediaReceiverChromecast) {
        [self.chromecastManager pause];
        return;
    }
    [_player pause];
    _playing = NO;
    _shouldPlayWhenPlayerIsReady = NO;
}

- (void)stop {
    if (self.receiver == AUMediaReceiverChromecast) {
        [self.chromecastManager stop];
        [self setLocalPlayback];
    }
    
    [_player pause];
    _playing = NO;
    _shouldPlayWhenPlayerIsReady = NO;
    [self replaceCurrentItemWithNewPlayerItem:nil];
    self.queue = @[];
}

- (void)stopChromecast {
    
    if (self.receiver == AUMediaReceiverChromecast) {
        [self.chromecastManager stop];
        [self setLocalPlayback];
    }
}

- (void)playItemFromCurrentQueueAtIndex:(NSUInteger)index {
    if (index >= self.queueLength) {
        NSAssert(NO, @"Given index exceeds queue length");
        return;
    }
    
    NSError *error;
    id<AUMediaItem> nextItem = [self.playingQueue objectAtIndex:index];
    [self updatePlayerWithItem:nextItem error:&error];
    
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey object:nil userInfo:@{kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey : error}];
        return;
    }
    
    [self play];
}

- (BOOL)tryPlayingItemFromCurrentQueue:(id<AUMediaItem>)item {
    NSInteger index = [self findIndexForItem:item];
    if (index < 0) {
        return NO;
    }
    
    NSError *error;
    id<AUMediaItem> nextItem = [self.playingQueue objectAtIndex:index];
    [self updatePlayerWithItem:nextItem error:&error];
    
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey object:nil userInfo:@{kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey : error}];
        return NO;
    }
    
    [self play];
    
    return YES;
}

- (void)playNext {
    
    if (!self.queue || self.queue.count < 1) {
        return;
    }
    
    NSError *error = nil;
    
    NSUInteger nextTrackIndex = (self.currentlyPlayedTrackIndex + 1) % self.queue.count;
    id<AUMediaItem> nextItem = [self.playingQueue objectAtIndex:nextTrackIndex];
    [self updatePlayerWithItem:nextItem error:&error];
    
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey object:nil userInfo:@{kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey : error}];
        return;
    }
    
    if (_repeat == AUMediaRepeatModeOn || nextTrackIndex > 0) {
        
        if (_receiver == AUMediaReceiverNone) {
            [self play];
        } else if (_receiver == AUMediaReceiverChromecast) {
            [self startItemPlaybackOnChromecast:nextItem];
        }
    } else {
        [self pause];
    }
}

- (void)playPrevious {
    
    if (!self.queue || self.queue.count < 1) {
        return;
    }
    
    if (_currentPlaybackTime > 2) {
        [_player seekToTime:kCMTimeZero];
        return;
    }
    
    NSUInteger nextTrackIndex = 0;
    NSInteger currentTrackIndex = self.currentlyPlayedTrackIndex;
    if (currentTrackIndex <= 0 && _repeat == AUMediaRepeatModeOn) {
        nextTrackIndex = self.queue.count - 1;
    } else if (currentTrackIndex > 0) {
        nextTrackIndex = currentTrackIndex - 1;
    }
    
    NSError *error;
    id<AUMediaItem> nextItem = [self.playingQueue objectAtIndex:nextTrackIndex];
    [self updatePlayerWithItem:nextItem error:&error];
    
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey object:nil userInfo:@{kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey : error}];
        return;
    }
    
    if (nextTrackIndex == 0 && currentTrackIndex == 0) {
        [self pause];
    } else {
        if (_receiver == AUMediaReceiverNone) {
            [self play];
        } else if (_receiver == AUMediaReceiverChromecast) {
            [self startItemPlaybackOnChromecast:nextItem];
        }
    }
}

- (void)seekToMoment:(double)moment {
    if (_receiver == AUMediaReceiverChromecast) {
        
        [self.chromecastManager seekToMoment:moment];
        return;
    }
    
    if (_player.status != AVPlayerStatusReadyToPlay) {
        return;
    }
    double secsToSeek = CMTimeGetSeconds([self playerItemDuration]) * moment;
    CMTime timeToSeek = CMTimeMakeWithSeconds(secsToSeek, NSEC_PER_SEC);
    
    __weak __typeof__(self) weakSelf = self;
    [_player seekToTime:timeToSeek completionHandler:^(BOOL finished) {
        [weakSelf updateNowPlayingInfoCenterData];
    }];
}

- (void)setShuffleOn:(BOOL)shuffle {
    if (shuffle && self.queue && self.queue.count > 1) {
        [self shuffleQueue];
    }
    _shuffle = shuffle;
}

- (void)setRepeatMode:(AUMediaRepeatMode)repeat {
    _repeat = repeat;
}

- (void)toggleRepeatMode {
    NSUInteger temp = _repeat + 1;
    _repeat = temp % 3;
}

- (void)restorePlayerStateWithItem:(id<AUMediaItem>)item queue:(NSArray *)queue playbackTime:(CMTime)time error:(NSError *__autoreleasing *)error {
    if (!item) {
        return;
    }
    [self updatePlayerWithItem:item error:error];
    self.queue = queue;
    [_player seekToTime:time];
}

- (void)prepareForCurrentItemReplacementWithItem:(id<AUMediaItem>)item {
    // override
}

#pragma mark -
#pragma mark Playback info

- (id<AUMediaItem>)nowPlayingItem {
    return objc_getAssociatedObject(_player.currentItem, AVPlayerItemAssociatedItem);
}

- (AUMediaPlaybackStatus)playbackStatus {
    if ([self playerIsPlaying]) {
        return AUMediaPlaybackStatusPlaying;
    } else if (self.receiver ==  AUMediaReceiverChromecast && (self.chromecastManager.status == AUCastStatusPlaying || self.chromecastManager.status == AUCastStatusBuffering)) {
        return AUMediaPlaybackStatusPlaying;
    } else if (self.receiver ==  AUMediaReceiverChromecast && self.chromecastManager.status == AUCastStatusPaused) {
        return AUMediaPlaybackStatusPaused;
    } else if (_player.status == AVPlayerStatusReadyToPlay) {
        return AUMediaPlaybackStatusPaused;
    } else {
        return AUMediaPlaybackStatusPlayerInactive;
    }
}

- (NSArray *)playingQueue {
    return _shuffle ? self.shuffledQueue : self.queue;
}

- (NSInteger)currentlyPlayedTrackIndex {
    return [self findIndexForItem:self.nowPlayingItem];
}

- (NSUInteger)queueLength {
    return self.queue.count;
}

#pragma mark -
#pragma mark Internal player methods

- (void)updatePlayerWithItem:(id<AUMediaItem>)item error:(NSError * __autoreleasing*)error {
    NSParameterAssert([item uid]);
    
    [self prepareForCurrentItemReplacementWithItem:item];
    
    NSURL *url = nil;
    if ([_library itemIsDownloaded:item]) {
        url = [NSURL fileURLWithPath:[_library localPathForItem:item]];
        if (url)
            NSLog(@"Playback will occur from local file with url: %@", url);
    }
    if (!url && [item respondsToSelector:@selector(localPath)] && [item localPath]) {
        url = [NSURL fileURLWithPath:[item localPath]];
        if (url)
            NSLog(@"Playback will occur from external disk file with url: %@", url);
    }
    if (!url && [item remotePath]) {
        url = [NSURL URLWithString:[item remotePath]];
        if (url)
            NSLog(@"Playback will occur from remote stream with url: %@", url);
    }
    if (!url) {
        *error = [NSError au_itemNotAvailableToPlayError];
        return;
    }
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
    objc_setAssociatedObject(playerItem, AVPlayerItemAssociatedItem, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([item itemType] == AUMediaTypeAudio) {
        _recentlyPlayedAudioItem = item;
    }
    if ([item itemType] == AUMediaTypeVideo) {
        _recentlyPlayedVideoItem = item;
    }
    
    if (!_player) {
        _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:playerItem];
        
        [playerItem addObserver:self
                     forKeyPath:@"status"
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                        context:AVPlayerPlaybackStatusObservationContext];
        
        [playerItem addObserver:self
                     forKeyPath:@"playbackBufferEmpty"
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                        context:AVPlayerPlaybackBufferEmptyObservationContext];
        
        [_player addObserver:self
                  forKeyPath:@"currentItem"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:AVPlayerPlaybackCurrentItemObservationContext];
        
        [_player addObserver:self
                  forKeyPath:@"currentItem"
                     options:NSKeyValueObservingOptionOld
                     context:AVPlayerPlaybackCurrentItemOldObservationContext];
        
        [_player addObserver:self
                  forKeyPath:@"rate"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:AVPlayerPlaybackRateObservationContext];
    } else {
        [self replaceCurrentItemWithNewPlayerItem:playerItem];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayedItemDidChangeNotification object:nil];
    [self updateNowPlayingInfoCenterData];
}

- (void)initPlaybackTimeObserver {
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        self.playbackTimesAreValid = NO;
        return;
    }
    self.playbackTimesAreValid = YES;
    
    __weak __typeof__(self) weakSelf = self;
    _timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                              queue:NULL /* If you pass NULL, the main queue is used. */
                                                         usingBlock:^(CMTime time)
                     {
                         [weakSelf observePlaybackTime];
                     }];
}

- (void)removePlayerTimeObserver {
    if (_timeObserver)
    {
        [self.player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

- (void)observePlaybackTime {
    
    // Local player
    if (_receiver == AUMediaReceiverNone) {
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration))
        {
            [self resetPlaybackTimes];
            return;
        }
        
        self.playbackTimesAreValid = YES;
        
        double duration = CMTimeGetSeconds(playerDuration);
        
        if (isfinite(duration))
        {
            double time = CMTimeGetSeconds([self.player currentTime]);
            if ((NSUInteger)time != _currentPlaybackTime) {
                self.currentPlaybackTime = (NSUInteger)time;
            }
            if ((NSUInteger)duration != _duration) {
                self.duration = (NSUInteger)duration;
            }
        }
    }
    
    // Chromecast
    else if (_receiver == AUMediaReceiverChromecast) {
        
        double progressTime = [self.chromecastManager getCurrentPlaybackProgressTime];
        double duration = [self.chromecastManager getCurrentItemDuration];
        
        if (progressTime < 0.0 || duration < 0.0) {
            [self resetPlaybackTimes];
            return;
        }
        
        self.playbackTimesAreValid = YES;
        
        if ((NSUInteger)progressTime != _currentPlaybackTime) {
            self.currentPlaybackTime = (NSUInteger)progressTime;
        }
        if ((NSUInteger)duration != _duration) {
            self.duration = (NSUInteger)duration;
        }
    }
}

- (CMTime)playerItemDuration {
    AVPlayerItem *playerItem = [self.player currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}

#pragma mark - KVO observer

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == AVPlayerPlaybackCurrentItemObservationContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (newPlayerItem == (id)[NSNull null]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlaybackStateDidChangeNotification object:nil];
        } else {
            id<AUMediaItem> item = self.nowPlayingItem;
            if ([item itemType] == AUMediaTypeAudio) {
                _recentlyPlayedAudioItem = item;
            } else if ([item itemType] == AUMediaTypeVideo) {
                _recentlyPlayedVideoItem = item;
            }
        }
        
    } else if (context == AVPlayerPlaybackCurrentItemOldObservationContext) {
        AVPlayerItem *priorItem = [change objectForKey:NSKeyValueChangeOldKey];
        
        if (priorItem && priorItem != (id)[NSNull null]) {
            [priorItem removeObserver:self forKeyPath:@"status" context:AVPlayerPlaybackStatusObservationContext];
            [priorItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:AVPlayerPlaybackBufferEmptyObservationContext];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                                          object:priorItem];
        }
        
    } else if (context == AVPlayerPlaybackRateObservationContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlaybackStateDidChangeNotification object:nil];
        
        [self updateNowPlayingInfoCenterData];
        
    } else if (context == AVPlayerPlaybackStatusObservationContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlaybackStateDidChangeNotification object:nil];
        
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self resetPlaybackTimes];
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self initPlaybackTimeObserver];
                
                if (_shouldPlayWhenPlayerIsReady) {
                    [_player play];
                    _shouldPlayWhenPlayerIsReady = NO;
                }
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self removePlayerTimeObserver];
                [self resetPlaybackTimes];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayerFailedToPlayItemNotification object:nil userInfo:@{kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey : playerItem.error}];
            }
                break;
        }
    } else if (context == AVPlayerPlaybackBufferEmptyObservationContext) {
        if (_playing) {
            [self play];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlaybackDidReachEndNotification object:nil];
    if (_repeat == AUMediaRepeatModeOneSong) {
        [_player seekToTime:kCMTimeZero];
        [self play];
    } else {
        [self playNext];
    }
}

#pragma mark -
#pragma mark Helper methods

- (void)shuffleQueue {
    self.shuffledQueue = [self.queue shuffle];
}

- (BOOL)playerIsPlaying {
    if (self.player.rate > 0.0f && self.player.error == nil) {
        return YES;
    }
    return NO;
}

- (NSInteger)findIndexForItem:(id<AUMediaItem>)item {
    NSArray *queue = self.playingQueue;
    
    for (NSUInteger idx = 0; idx < queue.count; idx++) {
        id<AUMediaItem> obj = [queue objectAtIndex:idx];
        if ([obj.uid isEqualToString:[item uid]]) {
            return idx;
        }
    }
    return -1;
}

- (void)replaceCurrentItemWithNewPlayerItem:(AVPlayerItem *)playerItem {
    
    if (playerItem) {
        
        [playerItem addObserver:self
                     forKeyPath:@"playbackBufferEmpty"
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                        context:AVPlayerPlaybackBufferEmptyObservationContext];
        
        [playerItem addObserver:self
                     forKeyPath:@"status"
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                        context:AVPlayerPlaybackStatusObservationContext];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:playerItem];
    }
    
    [_player replaceCurrentItemWithPlayerItem:playerItem];
}

- (void)resetPlaybackTimes {
    self.currentPlaybackTime = 0;
    self.duration = 0;
    self.playbackTimesAreValid = NO;
}

- (void)updateNowPlayingInfoCenterData {
    NSDictionary *dictionary = @{MPMediaItemPropertyPlaybackDuration : @(CMTimeGetSeconds(_player.currentItem.duration)),
                                 MPNowPlayingInfoPropertyElapsedPlaybackTime : @(CMTimeGetSeconds(_player.currentTime))};
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    if (self.player) {
        [info setObject:@(self.player.rate) forKey:MPMediaItemPropertyRating];
    }
    
    if ([self.nowPlayingItem title]) {
        [info setObject:[self.nowPlayingItem title] forKey:MPMediaItemPropertyTitle];
    }
    
    if ([self.nowPlayingCover respondsToSelector:@selector(author)] && [self.nowPlayingItem author]) {
        [info setObject:[self.nowPlayingItem author] forKey:MPMediaItemPropertyArtist];
    }
    
    if (self.nowPlayingCover) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.nowPlayingCover];
        if (artwork) {
            [info setObject:artwork forKey:MPMediaItemPropertyArtwork];
        }
    }
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
}

#pragma mark -
#pragma mark Interruptions

- (void)handleInterruption:(NSNotification *)notification {
    if (notification.name == AVAudioSessionInterruptionNotification) {
        AVAudioSessionInterruptionType interruption = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        
        switch (interruption) {
            case AVAudioSessionInterruptionTypeBegan:
                [self pause];
                break;
            case AVAudioSessionInterruptionTypeEnded:
                [self play];
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark Receiver changes

- (void)changeReceviverToChromecastTypeWithChromecastDevicesViewController:(UIViewController *)devicesController
                                            currentlyVisibleViewController:(UIViewController *)visibleViewController
                                                 connectionCompletionBlock:(AUCastConnectCompletionBlock)completionBlock {
    
    [self pause];
    
    _localPlayerPlaybackTime = (NSTimeInterval)self.currentPlaybackTime;
    
    _receiver = AUMediaReceiverChromecast;
    
    [self initChromecastTimeObserver];
    
    if ([self.chromecastManager isDeviceConnected]) {
        completionBlock(self.chromecastManager.connectedDevice, nil);
        return;
    }
    
    self.chromecastManager.afterConnectBlock = completionBlock;
    
    self.chromecastManager.searchDevices = YES;
    
    [visibleViewController presentViewController:devicesController animated:YES completion:nil];
}

- (void)setLocalPlayback {
    
    NSTimeInterval playbackTime = [self.chromecastManager getCurrentPlaybackProgressTime];
    
    if (_receiver == AUMediaReceiverNone) {
        return;
    } else if (_receiver == AUMediaReceiverChromecast) {
        
        [_chromecastObserverTimer invalidate];
        _chromecastObserverTimer = nil;
        
        [self.chromecastManager stop];
    }
    
    if (playbackTime < 0.0) {
        playbackTime = 0.0;
    }
    
    _receiver = AUMediaReceiverNone;
    
    if (_player.status == AVPlayerStatusReadyToPlay) {
        
        CMTime timeToSeek = CMTimeMakeWithSeconds(playbackTime, NSEC_PER_SEC);
        
        __weak __typeof__(self) weakSelf = self;
        [_player seekToTime:timeToSeek completionHandler:^(BOOL finished) {
            [weakSelf updateNowPlayingInfoCenterData];
        }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlaybackStateDidChangeNotification object:nil];
}

- (void)switchPlaybackToCurrentReceiver {
    if (_receiver == AUMediaReceiverChromecast) {
        
        NSTimeInterval playbackMoment = _localPlayerPlaybackTime;
        id<AUMediaItem>item = self.nowPlayingItem;
        
        [self.chromecastManager playItem:item fromMoment:playbackMoment];
    } else if (_receiver == AUMediaReceiverNone) {
        
        if (_player.status == AVPlayerStatusReadyToPlay) {
            
            [self play];
            
        } else if(self.nowPlayingItem) {
            
            BOOL success = [self tryPlayingItemFromCurrentQueue:self.nowPlayingItem];
            
            if (!success) {
                [self playItem:self.nowPlayingItem error:nil];
            }
        }
    }
}

#pragma mark -
#pragma mark Chromecast

- (BOOL)isItemCurrentlyPlayedOnChromecast:(id<AUMediaItem>)item {
    if (_receiver == AUMediaReceiverChromecast) {
        return [self.chromecastManager isItemCurrentlyPlayedOnChromecast:item];
    }
    return NO;
}

- (void)startItemPlaybackOnChromecast:(id<AUMediaItem>)item {
    [self.chromecastManager playItem:item fromMoment:0.0];
}

- (void)initChromecastTimeObserver {
    if (_chromecastObserverTimer == nil) {
        _chromecastObserverTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observePlaybackTime) userInfo:nil repeats:YES];
    }
}

#pragma mark -
#pragma mark AUCastDelegate

- (void)playbackDidReachEnd {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlaybackDidReachEndNotification object:nil];
    
    if (_repeat == AUMediaRepeatModeOneSong) {
        
        [self.chromecastManager seekToMoment:0.0];
        [self play];
        return;
    }
    
    NSUInteger nextTrackIndex = (self.currentlyPlayedTrackIndex + 1) % self.queue.count;
    
    if (_repeat == AUMediaRepeatModeOn || nextTrackIndex > 0) {
        [self playNext];
        return;
    }
    
    [self stopChromecast];
}

@end

