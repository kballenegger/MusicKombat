//
//  CBAPIRequest.m
//  ChartBoost
//
//  Created by Kenneth Ballenegger on 8/1/11.
//  Copyright 2011 ChartBoost. All rights reserved.
//

#import "MKAPIRequest.h"

#import <UIKit/UIKit.h>
#include <CommonCrypto/CommonHMAC.h>


#pragma mark Private Interface

@interface MKAPIRequest () {
@private
	NSString *suffix;
	NSDictionary *body;
	NSDictionary *query;
	NSArray *params;
	
	NSThread *delegationThread;
	
	id contextInfo;
}

@end



#pragma mark Implementation

@implementation MKAPIRequest

@synthesize body, query, params, suffix;
@synthesize contextInfo, delegationThread;


+ (MKAPIRequest *)requestWithSuffix:(NSString *)_suffix {
	return [[[MKAPIRequest alloc] initWithSuffix:_suffix] autorelease];
}


- (id)initWithSuffix:(NSString *)_suffix {
	if (self = [super init]) {
		self.suffix = _suffix;
	}
	return self;
}


- (void)appendBodyArgumentKey:(NSString *)key value:(NSString *)value {
	NSDictionary *dict = self.body;
	NSMutableDictionary *newDict;
	if ([dict class] == [NSMutableDictionary class]) {
		newDict = (NSMutableDictionary *)dict;
	} else {
		newDict = [NSMutableDictionary dictionaryWithDictionary:self.body];
	}
	[newDict setObject:value forKey:key];
	self.body = newDict;
}
- (void)appendQueryArgumentKey:(NSString *)key value:(NSString *)value {
	NSDictionary *dict = self.query;
	NSMutableDictionary *newDict;
	if ([dict class] == [NSMutableDictionary class]) {
		newDict = (NSMutableDictionary *)dict;
	} else {
		newDict = [NSMutableDictionary dictionaryWithDictionary:self.query];
	}
	[newDict setObject:value forKey:key];
	self.query = newDict;
}


@end
