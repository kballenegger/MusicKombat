//
//  MusicKombatViewController.m
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import "MusicKombatViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "CardView.h"
#import "CBContextualizedBasicAnimation.h"
#import "Card.h"

#import "AudioInput.h"

#define kMusicKombatHideViewAnimationContext @"kMusicKombatHideViewAnimationContext"

#define kMusicKombatDefaultAnimationDuration 0.2555

@interface MusicKombatViewController () <MPDADelegateProtocol, CardDelegate> {
@private
    UIProgressView *friendBar;
    UIProgressView *foeBar;
    
    Card *activeCard;
    
    AudioInput *pitchDetector;
}


@property (nonatomic, retain) IBOutlet UIProgressView *friendBar;
@property (nonatomic, retain) IBOutlet UIProgressView *foeBar;
@property (nonatomic, retain) IBOutlet Card *activeCard;

- (void)next;

@end

@implementation MusicKombatViewController
@synthesize friendBar;
@synthesize foeBar;
@synthesize activeCard;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation); 
}

- (void)awakeFromNib {
    
    pitchDetector = [[AudioInput alloc] initWithDelegate:self];
    
    
    // First card
    
    Card *card = [[Card alloc] init];
    card.delegate = self;
    
    CardView *newView = [[CardView alloc] initWithFrame:CGRectMake(48, 66, 384, 221)];
    CALayer *newLayer = newView.layer;
    
    CGPoint newToPosition = newView.center;
    CGPoint newFromPosition = newToPosition;
    
    newFromPosition.x += 480;
    
    CABasicAnimation *slideInAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    slideInAnimation.fromValue = [NSValue valueWithCGPoint:newFromPosition];
    slideInAnimation.toValue = [NSValue valueWithCGPoint:newToPosition];
    slideInAnimation.duration = kMusicKombatDefaultAnimationDuration;
    slideInAnimation.removedOnCompletion = NO;
    slideInAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    slideInAnimation.fillMode = kCAFillModeForwards;
    
    [self.view addSubview:newView];
    [newLayer addAnimation:slideInAnimation forKey:@"position"];
    
    card.cardView = [newView autorelease];
    self.activeCard = [card autorelease];
}

- (void)pitchDetected:(MPDA_RESULT)result {
    [self.activeCard pitchDetected:result];
}

- (void)cardCompleted {
    [self next];
}

- (void)next {
    
    NSLog(@"moviinnng on");

    Card *oldCard = self.activeCard;
    
    Card *newCard = [[Card alloc] init];
    newCard.delegate = self;
    
    self.activeCard = newCard;
    
    // Replace view with animation
    
    CardView *oldView = oldCard.cardView;
    CALayer *oldLayer = oldView.layer;
    
    CardView *newView = [[CardView alloc] initWithFrame:oldView.frame];
    CALayer *newLayer = newView.layer;
    
    CGPoint newToPosition = newView.center;
    CGPoint newFromPosition = newToPosition;
    
    newFromPosition.x += 1024;
    
    CABasicAnimation *slideInAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    slideInAnimation.fromValue = [NSValue valueWithCGPoint:newFromPosition];
    slideInAnimation.toValue = [NSValue valueWithCGPoint:newToPosition];
    slideInAnimation.duration = kMusicKombatDefaultAnimationDuration;
    slideInAnimation.removedOnCompletion = NO;
    slideInAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    slideInAnimation.fillMode = kCAFillModeForwards;
    
    [self.view addSubview:newView];
    [newLayer addAnimation:slideInAnimation forKey:@"position"];
    
    newCard.cardView = [newView autorelease];
    
    CGPoint oldFromPosition = oldView.center;
    CGPoint oldToPosition = oldFromPosition;
    
    oldToPosition.x -= 1024;
    
    CBContextualizedBasicAnimation *slideOutAnimation = [CBContextualizedBasicAnimation animationWithKeyPath:@"position"];
    slideOutAnimation.fromValue = [NSValue valueWithCGPoint:oldFromPosition];
    slideOutAnimation.toValue = [NSValue valueWithCGPoint:oldToPosition];
    slideOutAnimation.duration = kMusicKombatDefaultAnimationDuration;
    slideOutAnimation.removedOnCompletion = NO;
    slideOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    slideOutAnimation.fillMode = kCAFillModeForwards;
    slideOutAnimation.delegate = self;
    slideOutAnimation.context = oldView;
    
    [oldLayer addAnimation:slideOutAnimation forKey:@"position"];

}

- (void)dealloc {
    [friendBar release];
    [foeBar release];
    [activeCard release];
    [pitchDetector release];
    [super dealloc];
}


- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
    if (!finished) return;
    
    if (![animation isKindOfClass:[CBContextualizedBasicAnimation class]]) return;
    
    CBContextualizedBasicAnimation *contextualizedAnimation = (CBContextualizedBasicAnimation *)animation;
    
    if ([contextualizedAnimation.context isKindOfClass:[Card class]]) {
        [(Card *)contextualizedAnimation.context release];
    }
}

- (void)viewDidUnload {
    [self setActiveCard:nil];
    [super viewDidUnload];
}
@end
