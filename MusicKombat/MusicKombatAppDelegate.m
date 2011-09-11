//
//  MusicKombatAppDelegate.m
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/10/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import "MusicKombatAppDelegate.h"

#import "MKAPIRequest.h"

@interface MusicKombatAppDelegate () <MKAPIConnectionDelegate> {
@private
    MKAPIConnection *apiConnection;
    
    NSString *token;
    NSNumber *userId;
    
    MusicKombatViewController *gameViewController;
}
@end

@implementation MusicKombatAppDelegate

@synthesize window = _window;
@synthesize apiConnection;
@synthesize gameViewController;
@synthesize token, userId;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window.rootViewController = self.gameViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

+ (MusicKombatAppDelegate *)sharedDelegate {
    return (MusicKombatAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

    self.apiConnection = [[[MKAPIConnection alloc] initWithDelegate:self] autorelease];
    MKAPIRequest *request = [[MKAPIRequest alloc] initWithSuffix:@"users/new"];
    [request appendBodyArgumentKey:@"brandon" value:@"sucks_cock"]; // Fool stupid server into thinking it's a POST request
    [apiConnection sendRequest:request];
}

- (void)didFailToReceiveAPIResponseForRequest:(MKAPIRequest *)request {
}

- (void)didReceiveAPIResponse:(NSDictionary *)response forRequest:(MKAPIRequest *)request {
    NSLog(@"response on delegate %@", response);
    
    if ([request.suffix isEqualToString:@"users/new"]) {
        self.token = [response objectForKey:@"auth_token"];
        self.userId = [response objectForKey:@"id"];
        [self.gameViewController startGame];
    }
}

@end
