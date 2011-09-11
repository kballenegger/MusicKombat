//
//  CBContextualizedBasicAnimation.m
//  ChartBoost
//
//  Created by Kenneth Ballenegger on 8/4/11.
//  Copyright 2011 ChartBoost. All rights reserved.
//

#import "CBContextualizedBasicAnimation.h"

@interface CBContextualizedBasicAnimation () {
@private
    id context;
}


@end

@implementation CBContextualizedBasicAnimation

@synthesize context;

- (id)copyWithZone:(NSZone *)zone {
    CBContextualizedBasicAnimation *copy = [super copyWithZone:zone];
    copy.context = self.context;
    return copy;
}


@end
