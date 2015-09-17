//
//  ExampleCell.m
//  AUMediaPlayer
//
//  Created by Dev on 3/19/15.
//  Copyright (c) 2015 lukasz.kasperek. All rights reserved.
//

#import "ExampleCell.h"

@interface ExampleCell()

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressViewWidthConstraint;


@end


@implementation ExampleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.progressViewWidthConstraint.constant = 0.0;
    self.progressView.hidden = YES;
}

- (IBAction)downloadAction {
    [self.delegate didTapDownload:self];
}

- (void)showProgress:(BOOL)progressVisible progress:(CGFloat)progress {
    self.progressView.hidden = !progressVisible;
    
    if (progressVisible) {
        CGFloat cellWidth = CGRectGetWidth(self.bounds);
        self.progressViewWidthConstraint.constant = cellWidth * progress;
    }
}


@end
