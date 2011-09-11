//
//  LifeBar.m
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/11/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import "LifeBar.h"

#define kMusicKombatBarItemWidth 83
#define kMusicKombatItemsCount 5

@interface LifeBar () {
@private
    int value;
    BOOL isRight;
}
@end

@implementation LifeBar

- (id)initWithFrame:(CGRect)frame isRight:(BOOL)_isRight {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        isRight = _isRight;
        frame.size.width = kMusicKombatBarItemWidth * kMusicKombatItemsCount;
        frame.size.height = 49;
        self.frame = frame;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    for (int i = 0; i < kMusicKombatItemsCount && i >= 0; i++) {
        if ((!isRight && self.value > i) || (isRight && self.value >= kMusicKombatItemsCount-i)) {
            NSString *name = [NSString stringWithFormat:@"%@%i", (isRight ? @"right" : @"left"), (isRight ? kMusicKombatItemsCount - i : i+1)];
            UIImage *image = [UIImage imageNamed:name];
            CGPoint origin = CGPointMake(i * kMusicKombatBarItemWidth, 0);
            [image drawAtPoint:origin];
        }
    }
}

- (int)value {
    return value;
}

- (void)setValue:(int)_value {
    value = _value;
    [self setNeedsDisplay];
}

@end
