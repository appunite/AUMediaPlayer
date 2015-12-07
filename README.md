# AUMediaPlayer

[![CI Status](http://img.shields.io/travis/lukasz.kasperek/AUMediaPlayer.svg?style=flat)](https://travis-ci.org/lukasz.kasperek/AUMediaPlayer)
[![Version](https://img.shields.io/cocoapods/v/AUMediaPlayer.svg?style=flat)](http://cocoadocs.org/docsets/AUMediaPlayer)
[![License](https://img.shields.io/cocoapods/l/AUMediaPlayer.svg?style=flat)](http://cocoadocs.org/docsets/AUMediaPlayer)
[![Platform](https://img.shields.io/cocoapods/p/AUMediaPlayer.svg?style=flat)](http://cocoadocs.org/docsets/AUMediaPlayer)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Features

* Audio playback (local file and network stream)
* Video playback (local file and network stream)
* Chromecast stream
* Downloading and storing media files (playback occurs automatically from local file, if one is available)
* Convenient, KVO based mechanism for desplayinf playback info to user
* Shuffle
* Repeat queue (or repeat one track endlessly...)
* Background playback with built in interruptions (i.e. phone calls) management 
* Displaying media info on lock screen
* Lock screen controls

AUMediaPlayer is a library allowing audio and video playback, both from network stream and local files. It features all the common stuff you may expect, like queues, shuffle, repeat. It has convenient progress observation mechanism based on KVO. It automatically sets media info for lock screen displaying and works with lock screen controls. It also manages interruptions. Library object is included as well. It allows to download and store media. Since then they are automatically played from local files.

From version 3.0 it also enables you to stream tracks from AUMediaLibrary to Chromecast.

AUMediaPlayer header files contain commented out code snippets, which allow you to setup whole playback mechanism quickly. Example project is also included.

![alt tag](https://raw.github.com/appunite/AUMediaPlayer/tree/master/Example/Screenshots/PlayerScreenshot.png)

## Some basic methods

### AUMediaPlayer class

Play item:

	- (void)playItem:(id<AUMediaItem>)item error:(NSError * __autoreleasing *)error;
	
Play queue:

	- (void)playItemQueue:(id<AUMediaItemCollection>)collection error:(NSError * __autoreleasing *)error;
	
Play another item from current queue:

	- (void)playItemFromCurrentQueueAtIndex:(NSUInteger)index;
	- (BOOL)tryPlayingItemFromCurrentQueue:(id<AUMediaItem>)item;
	
Control playback:

	- (void)play;
	- (void)pause;
	- (void)stop;
	- (void)playNext;
	- (void)playPrevious;
	
Seek to specific moment (value from 0 to 1):

	- (void)seekToMoment:(double)moment;
	
Set shuffle and repeat options:

	- (void)setShuffleOn:(BOOL)shuffle;
	- (void)setRepeatMode:(AUMediaRepeatMode)repeat;
	- (void)toggleRepeatMode;

### AUMediaLibrary class

Download:

	- (void *)downloadItem:(id<AUMediaItem>)item;
	- (void)cancelDownloadForItem:(id<AUMediaItem>)item;
	- (NSProgress *)progressObjectForItem:(id<AUMediaItem>)item;
	- (void)downloadItemCollection:(id<AUMediaItemCollection>)collection;

Check status:

	- (BOOL)itemIsDownloaded:(id<AUMediaItem>)item;
	- (BOOL)itemCollectionIsDownloaded:(id<AUMediaItemCollection>)collection;

Get all items ot items from specific category (audio or video):

	- (NSArray *)downloadingItems;
	- (NSDictionary *)allExistingItems;
	- (NSDictionary *)existingItemsForType:(AUMediaType)type;

Remove items:

	- (void)removeItemFromLibrary:(id<AUMediaItem>)item error:(NSError * __autoreleasing*)error;
	- (void)removeCollectionFromLibrary:(id<AUMediaItemCollection>)collecion error:(NSError * __autoreleasing*)error;
	- (void)cleanLibraryError:(NSError * __autoreleasing*)error;

## Requirements

AUMediaPlayers requires ARC.
Deployment target: iOS7.
Requires AFNetworking dependency.

## Installation

AUMediaPlayer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "AUMediaPlayer"

## Credits

Thanks to AppUnite and @piotrbernad, who has authored the library class in major part.

## Author

lukasz.kasperek, lukasz.kasperek@appunite.com

## License

AUMediaPlayer is available under the MIT license. See the LICENSE file for more info.


