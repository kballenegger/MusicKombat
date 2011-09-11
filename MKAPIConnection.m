//
//  CBAPIConnection.m
//  ChartBoost
//
//  Created by Kenneth Ballenegger on 8/1/11.
//  Copyright 2011 ChartBoost. All rights reserved.
//

#import "MKAPIConnection.h"

#import "CBTaggedURLConnection.h"
#import "JSON.h"


#define MK_API_ENDPOINT @"http://dev.misomedia.com:1234/"


#pragma mark Private Interface

@interface MKAPIConnection () {
@private
	NSString *endpoint;
	NSMutableDictionary *activeConnections;
	id <MKAPIConnectionDelegate> delegate;
	
	NSUInteger requestIdMax;
}

@property (retain, nonatomic) NSString *endpoint;
@property (retain, nonatomic) NSMutableDictionary *activeConnections;

@property (atomic) NSUInteger requestIdMax;

- (id)initWithEndpoint:(NSString *)_endpoint andDelegate:(id <MKAPIConnectionDelegate>)_delegate;

@end



#pragma mark Implementation

@implementation MKAPIConnection

@synthesize endpoint, delegate;
@synthesize activeConnections;
@synthesize requestIdMax;


#pragma mark Initializers

- (id)initWithDelegate:(id<MKAPIConnectionDelegate>)_delegate {
	return [self initWithEndpoint:MK_API_ENDPOINT andDelegate:_delegate];
}

- (id)initWithEndpoint:(NSString *)_endpoint andDelegate:(id <MKAPIConnectionDelegate>)_delegate {
	if (self = [super init]) {
		self.endpoint = _endpoint;
		self.delegate = _delegate;
		self.activeConnections = [NSMutableDictionary dictionary];
		self.requestIdMax = 1;
	}
	return self;
}

- (id)init {
	return [self initWithDelegate:nil];
}


#pragma Sending a request

- (void)sendRequest:(MKAPIRequest *)request {
	NSUInteger requestId = self.requestIdMax++;
	NSNumber *requestIdNumber = [NSNumber numberWithUnsignedInt:requestId];
	
	// prepare url
	NSString *urlString = [NSString stringWithFormat:@"%@%@", self.endpoint, request.suffix];
	// TODO: sanity checking on endpoint url (trailing slash, etc.)
	
	// prepare query string
	if (request.query) {
		NSString *queryString = @"";
		for (NSString *key in request.query) {
			NSString *value = [request.query objectForKey:key];
			queryString = [queryString stringByAppendingFormat:@"%@=%@&",
						   [key stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
						   [value stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		}
		urlString = [urlString stringByAppendingFormat:@"?%@", queryString];
	}
	
	
	// prepare url
    NSLog(@"preparing url %@", urlString);
	NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] init] autorelease];
	[urlRequest setURL:[NSURL URLWithString:urlString]];
	
	// set headers
	NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=UTF-8"];
	[urlRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	// set request type
	if (request.body) {
		[urlRequest setHTTPMethod:@"POST"];
		
		// if post, create & set body
		NSString *bodyString = @"";
		for (NSString *key in request.body) {
			NSString *value = [request.body objectForKey:key];
			bodyString = [bodyString stringByAppendingFormat:@"%@=%@&",
						  [key stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
						  [value stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		}
		
		NSMutableData *postBody = [NSMutableData data];
		[postBody appendData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
		
		[urlRequest setHTTPBody:postBody];
		
	} else {
		[urlRequest setHTTPMethod:@"GET"];
	}
	
	// send request!
	[self.activeConnections setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:request, @"request", [NSMutableData dataWithLength:0], @"data", nil]
							   forKey:requestIdNumber];
	CBTaggedURLConnection *urlConnection = [[[CBTaggedURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES] autorelease];
    urlConnection.tag = requestIdNumber;
}



#pragma mark NSURLConnectionDelegate

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		if (([@"www.chartboost.com" isEqualToString:challenge.protectionSpace.host])) {
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
			return;
		}
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(CBTaggedURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	[[self.activeConnections objectForKey:connection.tag] setObject:response forKey:@"response"];
}

- (void)connection:(CBTaggedURLConnection *)connection didReceiveData:(NSData *)d {
	NSMutableData *data = [[self.activeConnections objectForKey:connection.tag] objectForKey:@"data"];
    [data appendData:d];
}

- (void)connection:(CBTaggedURLConnection *)connection didFailWithError:(NSError *)error {
	[self.activeConnections removeObjectForKey:connection.tag];
}

- (void)connectionDidFinishLoading:(CBTaggedURLConnection *)connection {  
	NSDictionary *connectionInfo = [[[self.activeConnections objectForKey:connection.tag] retain] autorelease];
	NSMutableData *responseData = [connectionInfo objectForKey:@"data"];
	MKAPIRequest *request = [connectionInfo objectForKey:@"request"];
	NSHTTPURLResponse *urlResponse = [connectionInfo objectForKey:@"response"];
	
	[self.activeConnections removeObjectForKey:connection.tag];

	// deal with response
	if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300) { // 200 range = status code for ok response
		
		NSString *responseAsString = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"response %@", responseAsString);
		// got response, now parse it
		SBJsonParser *parser = [[SBJsonParser new] autorelease];
		id response = [parser objectWithString:responseAsString];

		if(!response || ![response isKindOfClass:[NSDictionary class]]){
			[self.delegate didFailToReceiveAPIResponseForRequest:request];
		} else {    
			[self.delegate didReceiveAPIResponse:response forRequest:request];
		}
	} else {
        NSLog(@"bad respone code: %i", [urlResponse statusCode]);
		[self.delegate didFailToReceiveAPIResponseForRequest:request];
	}
}



@end
