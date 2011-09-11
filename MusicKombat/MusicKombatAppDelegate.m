//
//  MusicKombatAppDelegate.m
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import "MusicKombatAppDelegate.h"

@interface MusicKombatAppDelegate () {
@private
    SocketIoClient *connection;
}
@end

@implementation MusicKombatAppDelegate

@synthesize window = _window;
@synthesize connection;

- (void)applicationDidBecomeActive:(UIApplication *)application {

    SocketIoClient *client = [[SocketIoClient alloc] initWithHost:@"dev.misomedia.com" port:1234];
    client.delegate = self;
    
    [client connect];
    
    [client send:@"Hello Socket.IO" isJSON:NO];

}

- (void)socketIoClientDidConnect:(SocketIoClient *)client {
    NSLog(@"Connected.");
}

- (void)socketIoClientDidDisconnect:(SocketIoClient *)client {
    NSLog(@"Disconnected.");
}

- (void)socketIoClient:(SocketIoClient *)client didReceiveMessage:(NSString *)message isJSON:(BOOL)isJSON {
    NSLog(@"Received: %@", message);
}

@end
