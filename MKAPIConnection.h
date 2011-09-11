//
//  CBAPIConnection.h
//  ChartBoost
//
//  Created by Kenneth Ballenegger on 8/1/11.
//  Copyright 2011 ChartBoost. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKAPIRequest.h"

@protocol MKAPIConnectionDelegate

- (void)didReceiveAPIResponse:(NSDictionary *)response forRequest:(MKAPIRequest *)request;
- (void)didFailToReceiveAPIResponseForRequest:(MKAPIRequest *)request;

@end



@interface MKAPIConnection : NSObject

@property (retain, nonatomic) id <MKAPIConnectionDelegate> delegate;

- (id)initWithDelegate:(id <MKAPIConnectionDelegate>)delegate;

- (void)sendRequest:(MKAPIRequest *)request;

@end
