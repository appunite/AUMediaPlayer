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
* Downloading and storing media files (playback occurs automatically from local file, if one is available)
* Convenient, KVO based mechanism for desplayinf playback info to user
* Shuffle
* Repeat
* Background playback with built in interruptions (i.e. phone calls) management 
* Displaying media info on lock screen
* Lock screen controls

AUMediaPlayer is a library allowing audio and video playback, both from network stream and local files. It features all the common stuff you may expect, like queues, shuffle, repeat. It has convenient progress observation mechanism based on KVO. It automatically sets media info for lock screen displaying and works with lock screen controls. It also manages interruptions. Library object is included as well. It allows to download and store media. Since then they are automatically played from local files.

AUMediaPlayer header files contain commented out code snippets, which allow you to setup whole playback mechanism quickly. Example project is also included.

## Requirements

AUMediaPlayers requires ARC.
Deployment target: iOS7.
Requires AFNetworking dependency.

## Installation

AUMediaPlayer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "AUMediaPlayer"

## Author

lukasz.kasperek, lukasz.kasperek@appunite.com

## License

AUMediaPlayer is available under the MIT license. See the LICENSE file for more info.

