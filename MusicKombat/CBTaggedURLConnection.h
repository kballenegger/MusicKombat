//
//  CBTaggedURLConnection.h
//  ChartBoost
//
//  Created by Kenneth Ballenegger on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBTaggedURLConnection : NSURLConnection {
	NSNumber *tag;
}

@property (retain) NSNumber *tag;

@end
