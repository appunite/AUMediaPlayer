//
//  ExampleCell.m
//  AUMediaPlayer
//
//  Created by Dev on 3/19/15.
//  Copyright (c) 2015 lukasz.kasperek. All rights reserved.
//

#import "ExampleCell.h"


@implementation ExampleCell

- (IBAction)downloadAction {
    [self.delegate didTapDownload:self];
}


@end
