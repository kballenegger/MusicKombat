//
//  MusicKombatAppDelegate.h
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicKombatViewController.h"
#import "MKAPIConnection.h"

@interface MusicKombatAppDelegate : UIResponder <UIApplicationDelegate>

@property (retain, nonatomic) IBOutlet UIWindow *window;

@property (retain, nonatomic) MKAPIConnection *apiConnection;
@property (retain, nonatomic) IBOutlet MusicKombatViewController *gameViewController;

@property (retain, nonatomic) NSString *token;
@property (retain, nonatomic) NSNumber *userId;

+ (MusicKombatAppDelegate *)sharedDelegate;

@end
