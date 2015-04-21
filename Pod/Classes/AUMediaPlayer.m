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

@interface AUMediaPlayer() {
    id _timeObserver;
    BOOL _shouldPlayWhenPlayerIsReady;
    BOOL _playing;
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
        _library = [[AUMediaLibrary alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
        self.playbackIsResumedAfterInterruptions = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters/setters

- (void)setQueue:(NSArray *)queue {
    _queue = queue;
    [self shuffleQueue];
}

- (void)setNowPlayingCover:(UIImage *)nowPlayingCover {
    _nowPlayingCover = nowPlayingCover;
    [self updateNowPlayingInfoCenterData];
}

#pragma mark - Player actions

- (void)playItem:(id<AUMediaItem>)item error:(NSError *__autoreleasing *)error {
    self.queue = @[item];
    [self updatePlayerWithItem:item error:error];
    [self play];
}

- (void)playItemQueue:(id<AUMediaItemCollection>)collection error:(NSError *__autoreleasing *)error {
    self.queue = collection.mediaItems;
    id<AUMediaItem>item = _shuffle ? [self.shuffledQueue objectAtIndex:0] : [self.queue objectAtIndex:0];
    
    [self updatePlayerWithItem:item error:error];
    [self play];
}

- (void)play {
    if (_player.status == AVPlayerStatusReadyToPlay) {
        [_player play];
    } else {
        _shouldPlayWhenPlayerIsReady = YES;
    }
    _playing = YES;
}

- (void)pause {
    [_player pause];
    _playing = NO;
    _shouldPlayWhenPlayerIsReady = NO;
}

- (void)stop {
    [_player pause];
    _playing = NO;
    _shouldPlayWhenPlayerIsReady = NO;
    [self replaceCurrentItemWithNewPlayerItem:nil];
    self.queue = @[];
}

- (void)playNext {
    [self playNextForced:NO];
}

- (void)playNextForced:(BOOL)force {
    NSError *error = nil;
    
    NSUInteger nextTrackIndex;
    
    if (_repeatSong && !force) {
        nextTrackIndex = self.currentlyPlayedTrackIndex;
    }else {
        nextTrackIndex = (self.currentlyPlayedTrackIndex + 1) % self.queue.count;
    }
    
    id<AUMediaItem> nextItem = [self.playingQueue objectAtIndex:nextTrackIndex];
    [self updatePlayerWithItem:nextItem error:&error];
    
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey object:nil userInfo:@{kAUMediaPlayerFailedToPlayItemNotificationUserInfoErrorKey : error}];
        return;
    }
    
    if (_repeat || nextTrackIndex > 0) {
        [self play];
    } else {
        [self pause];
    }
}

- (void)playPrevious {
    if (_currentPlaybackTime > 2) {
        [_player seekToTime:kCMTimeZero];
        return;
    }
    
    NSUInteger nextTrackIndex = 0;
    NSUInteger currentTrackIndex = self.currentlyPlayedTrackIndex;
    if (currentTrackIndex == 0 && _repeat) {
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
        [self play];
    }
}

- (void)seekToMoment:(double)moment {
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

- (void)setRepeatOn:(BOOL)repeat {
    _repeat = repeat;
}

- (void)setRepeatSongOn:(BOOL)repeat {
    _repeatSong = repeat;
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

#pragma mark - Playback info

- (id<AUMediaItem>)nowPlayingItem {
    return objc_getAssociatedObject(_player.currentItem, AVPlayerItemAssociatedItem);
}

- (AUMediaPlaybackStatus)playbackStatus {
    if ([self playerIsPlaying]) {
        return AUMediaPlaybackStatusPlaying;
    } else if (_player.status == AVPlayerStatusReadyToPlay) {
        return AUMediaPlaybackStatusPaused;
    } else {
        return AUMediaPlaybackStatusPlayerInactive;
    }
}

- (NSArray *)playingQueue {
    return _shuffle ? self.shuffledQueue : self.queue;
}

- (NSUInteger)currentlyPlayedTrackIndex {
    NSArray *queue = self.playingQueue;
    
    for (NSUInteger idx = 0; idx < queue.count; idx++) {
        id<AUMediaItem> obj = [queue objectAtIndex:idx];
        if ([obj.uid isEqualToString:self.nowPlayingItem.uid]) {
            return idx;
        }
    }
    return 0;
}

- (NSUInteger)queueLength {
    return self.queue.count;
}

#pragma mark - Internal player methods

- (void)updatePlayerWithItem:(id<AUMediaItem>)item error:(NSError * __autoreleasing*)error {
    NSParameterAssert([item uid]);
    
    [self prepareForCurrentItemReplacementWithItem:item];
    
    NSURL *url = nil;
    if ([_library itemIsDownloaded:item]) {
        url = [NSURL fileURLWithPath:[_library localPathForItem:item]];
        NSLog(@"Playback will occur from local file with url: %@", url);
    }
    if (!url) {
        url = [NSURL URLWithString:[item remotePath]];
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

- (void)observePlaybackTime
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        [self resetPlaybackTimes];
        return;
    }
    
    _playbackTimesAreValid = YES;
    
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
            [[NSNotificationCenter defaultCenter] postNotificationName:kAUMediaPlayedItemDidChangeNotification object:nil];
        }
        
        [self updateNowPlayingInfoCenterData];
        
    } else if (context == AVPlayerPlaybackCurrentItemOldObservationContext) {
        AVPlayerItem *priorItem = [change objectForKey:NSKeyValueChangeOldKey];
        
        if (priorItem && priorItem != (AVPlayerItem *)[NSNull null]) {
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
    [self playNext];
}

#pragma mark - Helper methods

- (void)shuffleQueue {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.queue];
    NSMutableArray *shuffledArray = [NSMutableArray array];
    while ([tempArray count] > 0) {
        NSUInteger idx = arc4random() % [tempArray count];
        [shuffledArray addObject:[tempArray objectAtIndex:idx]];
        [tempArray removeObjectAtIndex:idx];
    }
    self.shuffledQueue = shuffledArray;
}

- (BOOL)playerIsPlaying {
    if (self.player.rate > 0.0f && self.player.error == nil) {
        return YES;
    }
    return NO;
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
    
    if ([self.nowPlayingItem author]) {
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

#pragma mark - Lock screen

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

#pragma mark - Interruptions

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

@end

