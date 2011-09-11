//
//  Card.m
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import "Card.h"

@interface Card () {
@private
    id <CardDelegate> delegate;
    CardView *cardView;
}
@end

@implementation Card

@synthesize delegate, cardView;

- (void)pitchDetected:(MPDA_RESULT)result {
    if (result.note_found) {
        NSLog(@"pitch detected %i", result.note);
        if (result.note == 4) {
            [self.delegate cardCompleted];
        }
    }
}

- (void)dealloc {
    [self.cardView removeFromSuperview];
    [super dealloc];
}

@end
