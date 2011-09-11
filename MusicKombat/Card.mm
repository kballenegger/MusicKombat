//
//  Card.m
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import "Card.h"
#include "MKStack.c"


@interface Card () {
@private
    id <CardDelegate> delegate;
    CardView *cardView;
    mk_stack_element *notes_head;
}
@end

@implementation Card

@synthesize delegate, cardView;

- (id)init {
    if (self = [super init]) {
        notes_head = mk_stack_make(4, 7, 4, 7, MK_STACK_END);
    }
    return self;
}

- (void)pitchDetected:(MPDA_RESULT)result {
    if (result.note_found) {
//        NSLog(@"pitch detected %i", result.note);
        if (result.note == notes_head->value) {
            mk_stack_pop(&notes_head);
            if (notes_head) {
                NSLog(@"Note %i played, next: up %i", result.note, notes_head->value);
            } else{
                NSLog(@"Last note on card played: %i", result.note);
                [self.delegate cardCompleted];
            }
        }
    }
}

- (void)dealloc {
    [self.cardView removeFromSuperview];
    [super dealloc];
}

@end
