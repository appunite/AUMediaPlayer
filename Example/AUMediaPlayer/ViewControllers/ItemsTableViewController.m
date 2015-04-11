//
//  ExampleTableViewController.m
//  AUMedia
//
//  Created by Dev on 2/19/15.
//  Copyright (c) 2015 AppUnite. All rights reserved.
//

#import "ItemsTableViewController.h"
#import "PlaybackViewController.h"
#import "ExampleCell.h"

@interface ItemsTableViewController()<ExampleCellDelegate>

@end

@implementation ItemsTableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self mockMedia].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExampleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    id<AUMediaItem> item = [[self mockMedia] objectAtIndex:indexPath.row];
    cell.textLabel.text = item.title;
    cell.delegate = self;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PlaybackViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"viewController"];
    if (indexPath.row == 0) {
        controller.item = nil;
        controller.collection = [[self mockMedia] objectAtIndex:indexPath.row];
    } else {
        controller.collection = nil;
        controller.item = [[self mockMedia] objectAtIndex:indexPath.row];
    }
    
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Example cell delegate

- (void)didTapDownload:(ExampleCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (indexPath) {
        if (indexPath.row == 0) {
            ExampleMediaCollection *collection = [[self mockMedia] objectAtIndex:0];
            [[AUMediaPlayer sharedInstance].library downloadItemCollection:collection];
        } else {
            id<AUMediaItem> item = [[self mockMedia] objectAtIndex:indexPath.row];
            [[AUMediaPlayer sharedInstance].library downloadItem:item];
        }
    }
}

#pragma mark - Navigation

- (IBAction)unwind:(UIStoryboardSegue *)segue {
    [[AUMediaPlayer sharedInstance] stop];
}

#pragma mark - Mock

- (NSArray *)mockMedia {
    
    ExampleAudioItem *audio1 = [[ExampleAudioItem alloc] init];
    audio1.author = @"Author";
    audio1.title = @"Track 1";
    audio1.uid = @"00000000001";
    audio1.remotePath = @"http://www.tonycuffe.com/mp3/tail%20toddle.mp3";
    
    ExampleAudioItem *audio2 = [[ExampleAudioItem alloc] init];
    audio2.author = @"Author";
    audio2.title = @"Track 2";
    audio2.uid = @"00000000002";
    audio2.remotePath = @"http://www.tonycuffe.com/mp3/cairnomount_lo.mp3";
    
    ExampleAudioItem *audio3 = [[ExampleAudioItem alloc] init];
    audio3.author = @"Author";
    audio3.title = @"Track 3";
    audio3.uid = @"00000000003";
    audio3.remotePath = @"http://www.tonycuffe.com/mp3/pipers%20hut.mp3";
    
    ExampleMediaCollection *collection = [[ExampleMediaCollection alloc] init];
    collection.mediaItems = @[audio1, audio2, audio3];
    collection.author = @"Author";
    collection.title = @"Album";
    
    ExampleVideoItem *video = [[ExampleVideoItem alloc] init];
    video.author = @"Video author";
    video.title = @"Video";
    video.uid = @"00000000004";
    video.remotePath = @"http://qn.vc/files/data/1541/2%20Many%20Girls%20-%20Fazilpuria,%20Badshah%20[mobmp4.com].mp4";
    
    
    return @[collection, audio1, audio2, audio3, video];
}

@end
