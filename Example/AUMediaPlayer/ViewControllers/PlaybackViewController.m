//
//  ViewController.m
//  AUMedia
//
//  Created by Dev on 2/11/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "PlaybackViewController.h"
#import <AUMediaPlayer/AUMediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoView.h"

static void *AUMediaPlaybackCurrentTimeObservationContext = &AUMediaPlaybackCurrentTimeObservationContext;
static void *AUMediaPlaybackDurationObservationContext = &AUMediaPlaybackDurationObservationContext;
static void *AUMediaPlaybackTimeValidityObservationContext = &AUMediaPlaybackTimeValidityObservationContext;

@interface PlaybackViewController () {
    NSUInteger _currentItemDuration;
    BOOL _playbackTimesAreValid;
}

@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTimeLabel;

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;


@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet VideoView *playbackView;

@property (weak, nonatomic) IBOutlet UISlider *slider;
@end

@implementation PlaybackViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self musicPlayerStateChanged:nil];
    [self updateShuffleAndRepeatButtons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AUMediaPlayer *player = [self player];
    [player addObserver:self forKeyPath:@"currentPlaybackTime" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AUMediaPlaybackCurrentTimeObservationContext];
    [player addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AUMediaPlaybackDurationObservationContext];
    [player addObserver:self forKeyPath:@"playbackTimesAreValid" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AUMediaPlaybackTimeValidityObservationContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(musicPlayerStateChanged:)
                                                 name:kAUMediaPlaybackStateDidChangeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    AUMediaPlayer *player = [AUMediaPlayer sharedInstance];
    [player removeObserver:self forKeyPath:@"currentPlaybackTime" context:AUMediaPlaybackCurrentTimeObservationContext];
    [player removeObserver:self forKeyPath:@"duration" context:AUMediaPlaybackDurationObservationContext];
    [player removeObserver:self forKeyPath:@"playbackTimesAreValid" context:AUMediaPlaybackTimeValidityObservationContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kAUMediaPlaybackStateDidChangeNotification
                                                  object:nil];
}

- (void)setPlayerLayer {
    AVPlayerLayer *layer = (AVPlayerLayer *)self.playbackView.layer;
    [layer setPlayer:[self player].player];
}

- (IBAction)playPauseAction:(id)sender {
    AUMediaPlayer *player = [AUMediaPlayer sharedInstance];
    if (player.playbackStatus == AUMediaPlaybackStatusPlayerInactive || ![[player.nowPlayingItem uid] isEqualToString:self.item.uid]) {
        NSError *error;
        if (self.collection) {
            [player playItemQueue:self.collection error:&error];
        } else {
            [player playItem: self.item error:&error];
            [self setPlayerLayer];
        }
    } else if (player.playbackStatus == AUMediaPlaybackStatusPlaying) {
        [player pause];
    } else {
        [player play];
    }
    NSLog(@"Current time: %lu, Duration: %lu", (unsigned long)player.currentPlaybackTime, (unsigned long)player.duration);
}

- (IBAction)prevAction:(id)sender {
    [[self player] playPrevious];
}

- (IBAction)nextAction:(id)sender {
    [[self player] playNext];
}
- (IBAction)repeatAction:(id)sender {
    AUMediaPlayer *player = [self player];
    if (player.repeat) {
        [[self player] setRepeatOn:NO];
    } else {
        [[self player] setRepeatOn:YES];
    }
    
    [self updateShuffleAndRepeatButtons];
}
- (IBAction)shuffleAction:(id)sender {
    AUMediaPlayer *player = [self player];
    if (player.shuffle) {
        [player setShuffleOn:NO];
    } else {
        [player setShuffleOn:YES];
    }
    
    [self updateShuffleAndRepeatButtons];
}

- (IBAction)didSlide:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [[self player] seekToMoment:slider.value];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == AUMediaPlaybackTimeValidityObservationContext) {
        BOOL playbackTimesValidaity = [change[NSKeyValueChangeNewKey] boolValue];
        _playbackTimesAreValid = playbackTimesValidaity;
        if (!playbackTimesValidaity) {
            self.leftTimeLabel.text = @"invalid";
            self.rightTimeLabel.text = @"invalid";
        }
    } else if (context == AUMediaPlaybackCurrentTimeObservationContext) {
        NSUInteger currentPlaybackTime = [change[NSKeyValueChangeNewKey] integerValue];
        [self updatePlaybackProgressSliderWithTimePassed:currentPlaybackTime];
        self.leftTimeLabel.text = [NSString stringWithFormat:@"%lu", currentPlaybackTime];
    } else if (context == AUMediaPlaybackDurationObservationContext) {
        NSUInteger currentDuration = [change[NSKeyValueChangeNewKey] integerValue];
        _currentItemDuration = currentDuration;
        self.rightTimeLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)currentDuration];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (AUMediaPlayer *)player {
    return [AUMediaPlayer sharedInstance];
}

- (void)updatePlaybackProgressSliderWithTimePassed:(NSUInteger)time {
    if (_playbackTimesAreValid && _currentItemDuration > 0) {
        self.slider.value = (float)time/(float)_currentItemDuration;
    } else {
        self.slider.value = 0.0;
    }
}

- (void)musicPlayerStateChanged:(NSNotification *)notification {
    [self updateNowPlayingInfo];
    [self updateButtonsForStatus:[[AUMediaPlayer sharedInstance] playbackStatus]];
}

- (void)updateButtonsForStatus:(AUMediaPlaybackStatus)status {
    if (status == AUMediaPlaybackStatusPlaying) {
        [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    } else {
        [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}

- (void)updateNowPlayingInfo {
    id<AUMediaItem>item = [[self player] nowPlayingItem];
    self.authorLabel.text = [item author];
    self.titleLabel.text = [item title];
}

- (void)updateShuffleAndRepeatButtons {
    AUMediaPlayer *player = [AUMediaPlayer sharedInstance];
    if (player.shuffle) {
        [self.shuffleButton setTitle:@"Shuffle on" forState:UIControlStateNormal];
        NSLog(@"Shuffle on");
    } else {
        [self.shuffleButton setTitle:@"Shuffle off" forState:UIControlStateNormal];
        NSLog(@"Shuffle off");
    }
    if (player.repeat) {
        [self.repeatButton setTitle:@"Repeat on" forState:UIControlStateNormal];
        NSLog(@"Repeat on");
    } else {
        [self.repeatButton setTitle:@"Repeat off" forState:UIControlStateNormal];
        NSLog(@"Repeat off");
    }
}

@end
