#
# Be sure to run `pod lib lint AUMediaPlayer.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "AUMediaPlayer"
  s.version          = "2.0.0"
  s.summary          = "AUMediaPlayer is a nice high level API for audio and video playback, both from network stream and local files."
  s.description      = "AUMediaPlayer is a library allowing audio and video playback, both from network stream and local files. It features all the common stuff you may expect, like queues, shuffle, repeat. It has convenient progress observation mechanism based on KVO. It automatically sets media info for lock screen displaying and works with lock screen controls. It also manages interruptions. Library object is included as well. It allows to download and store media. Since then they are automatically played from local files."
  s.homepage         = "https://github.com/appunite/AUMediaPlayer"
  s.license          = 'MIT'
  s.author           = { "lukasz.kasperek" => "lukasz.kasperek@appunite.com" }
  s.source           = { :git => "https://github.com/appunite/AUMediaPlayer.git", :tag => s.version.to_s }
  s.social_media_url = 'https://appunite.medium.com'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.public_header_files = 'Headers/Public/*.h'
  s.resource_bundles = {
    'AUMediaPlayer' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'AVFoundation', 'MediaPlayer'
  s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'google-cast-sdk', '~> 2.6'
  
end
