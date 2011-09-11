//
//  Card.m
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import "Card.h"
#include "MKStack.c"

#define kMusicKombatNoteSpacing 0
#define kMusicKombatNoteWidth 173

@interface Card () {
@private
    id <CardDelegate> delegate;
    CardView *cardView;
    mk_stack_element *notes_head;
    NSMutableArray *noteViews;
}

- (void)refreshNoteLocationsFirstTime:(BOOL)firstTime;

@end

@implementation Card

@synthesize delegate, cardView;

- (id)initWithCardView:(CardView *)_cardView {
    if (self = [super init]) {
        notes_head = mk_stack_make(9, 7, 9, 7, MK_STACK_END);
        noteViews = [[NSMutableArray alloc] init];
        cardView = _cardView;

        for (mk_stack_element *cursor = notes_head; cursor; cursor = cursor->next) {
            NSLog(@"note %i", cursor->value);
            UIImageView *noteView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"note_%i", cursor->value]]];
            [noteViews addObject:noteView];
        }
        
        [self refreshNoteLocationsFirstTime:YES];
    }
    return self;
}

- (void)refreshNoteLocationsFirstTime:(BOOL)firstTime {
    int i= 0;
    for (UIView *noteView in noteViews) {
        CGFloat x1 = 190;
        CGFloat x2 = 926;
        CGFloat dx = x2 - x1;
        int j = i++;
        
        CGRect frame;
        frame.size = noteView.frame.size;
        frame.origin.y = 100;
        frame.origin.x = (dx / 2 + x1)
            - ([noteViews count] * kMusicKombatNoteWidth + ([noteViews count] - 1) * kMusicKombatNoteSpacing) / 2
            + (j * kMusicKombatNoteWidth + (j - 1) * kMusicKombatNoteSpacing);
        
        if (!firstTime)
            [UIView beginAnimations:nil context:nil];
        noteView.frame = frame;
        if (!firstTime)
            [UIView commitAnimations];
        
        if (firstTime) {
            [cardView addSubview:noteView];
        }
    }
}

- (void)pitchDetected:(MPDA_RESULT)result {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result.note_found) {
//        NSLog(@"pitch detected %i", result.note);
            if (result.note == notes_head->value) {
                mk_stack_element *current = mk_stack_pop(&notes_head);
                free(current);
                
                UIView *notePlayed = [noteViews objectAtIndex:0];
                [notePlayed removeFromSuperview]; // TODO: animate me
                [noteViews removeObjectAtIndex:0];
                [self refreshNoteLocationsFirstTime:NO];
                
                if (notes_head) {
                    NSLog(@"Note %i played, next: up %i", result.note, notes_head->value);
                } else{
                    NSLog(@"Last note on card played: %i", result.note);
                    [self.delegate cardCompleted];
                }
            }
        }
    });
}

- (void)dealloc {
    [self.cardView removeFromSuperview];
    [super dealloc];
}

@end
