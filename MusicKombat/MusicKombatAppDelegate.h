//
//  MusicKombatAppDelegate.h
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocketIoClient.h"

@interface MusicKombatAppDelegate : UIResponder <UIApplicationDelegate, SocketIoClientDelegate>

@property (retain, nonatomic) UIWindow *window;
@property (retain) SocketIoClient *connection;

@end
