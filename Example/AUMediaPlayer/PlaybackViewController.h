//
//  ViewController.h
//  AUMedia
//
//  Created by Dev on 2/11/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExampleItem.h"

@interface PlaybackViewController : UIViewController

@property (nonatomic, strong) ExampleMediaItem *item;
@property (nonatomic, strong) ExampleMediaCollection *collection;


@end
