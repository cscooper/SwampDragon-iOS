//
//  SDWebsocket.m
//  A simple class for interfacing iOS apps to real-time services powered by SwampDragon
//
//  SwampDragon is maintained by Jonas Hagstedt. <http://swampdragon.net>
//
//  Created by Craig Cooper on 9/02/2015.
//  Copyright (c) 2015 Craig Cooper
//

#import <Foundation/Foundation.h>
#import "SocketRocket/SRWebSocket.h"

@protocol SDWebsocketDelegate;


typedef void (^SocketCallback)( NSDictionary *context, NSDictionary *message );

@interface SDWebsocket : NSObject <SRWebSocketDelegate>

@property (weak,nonatomic) id<SDWebsocketDelegate> delegate;

- (SDWebsocket*)initWithURL:(NSURL*)url;
- (void)connect;
- (void)close;
- (void)callRouter:(NSString*)routerName withVerb:(NSString*)verb withArguments:(NSDictionary*)args withCallback:(SocketCallback)callback;

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end



@protocol SDWebsocketDelegate <NSObject>

- (void)onMessage:(NSDictionary*)message fromChannel:(NSString*)channel;

@optional

- (void)socketOpened:(SDWebsocket*)socket;
- (void)socketClosedCleanly:(SDWebsocket*)socket;
- (void)socketClosed:(SDWebsocket*)socket withCode:(NSInteger)code andReason:(NSString*)reason;
- (void)onError:(NSError*)error forSocket:(SDWebsocket*)socket;

@end


