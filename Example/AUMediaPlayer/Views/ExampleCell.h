//
//  ExampleCell.h
//  AUMediaPlayer
//
//  Created by Dev on 3/19/15.
//  Copyright (c) 2015 lukasz.kasperek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AUMediaPlayer/AUMediaPlayer.h>

@class ExampleCell;

@protocol ExampleCellDelegate <NSObject>
- (void)didTapDownload:(ExampleCell *)cell;
@end


@interface ExampleCell : UITableViewCell

@property (nonatomic, weak) id<ExampleCellDelegate>delegate;

@end
