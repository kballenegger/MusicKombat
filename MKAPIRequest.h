//
//  CBAPIRequest.h
//  ChartBoost
//
//  Created by Kenneth Ballenegger on 8/1/11.
//  Copyright 2011 ChartBoost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKAPIRequest : NSObject

@property (retain, nonatomic) NSString *suffix;

// After you assign it, I own these dictionaries. If they're mutable, I might modify them.
@property (retain, nonatomic) NSDictionary *body;
@property (retain, nonatomic) NSDictionary *query;
@property (retain, nonatomic) NSArray *params;

@property (retain, nonatomic) id contextInfo;

@property (retain, nonatomic) NSThread *delegationThread;

+ (MKAPIRequest *)requestWithSuffix:(NSString *)suffix;

- (id)initWithSuffix:(NSString *)suffix;

- (void)appendBodyArgumentKey:(NSString *)key value:(NSString *)value;
- (void)appendQueryArgumentKey:(NSString *)key value:(NSString *)value;

@end
