//
//  Card.h
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioInput.h"
#import "CardView.h"

@protocol CardDelegate
- (void)cardCompleted;
@end

@interface Card : NSObject <MPDADelegateProtocol>

@property (nonatomic, assign) id <CardDelegate> delegate;
@property (nonatomic, readonly) CardView *cardView;

- (id)initWithCardView:(CardView *)cardView notes:(int *)notes;

@end
