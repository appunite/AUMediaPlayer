//
//  NSArray+AUMedia.m
//  Pods
//
//  Created by Dev on 6/8/15.
//
//

#import "NSArray+AUMedia.h"

@implementation NSArray (AUMedia)

- (NSArray *)shuffle {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self];
    NSMutableArray *shuffledArray = [NSMutableArray array];
    while ([tempArray count] > 0) {
        NSUInteger idx = arc4random() % [tempArray count];
        [shuffledArray addObject:[tempArray objectAtIndex:idx]];
        [tempArray removeObjectAtIndex:idx];
    }
    return [NSArray arrayWithArray:shuffledArray];
}

@end
