//
//  SDWebsocket.m
//  A simple class for interfacing iOS apps to real-time services powered by SwampDragon
//
//  SwampDragon is maintained by Jonas Hagstedt. <http://swampdragon.net>
//
//  Created by Craig Cooper on 9/02/2015.
//  Copyright (c) 2015 Craig Cooper
//

#import "SDWebsocket.h"

NSMutableDictionary *channels = nil;

@interface SDWebsocket ()

@property (strong,nonatomic) NSURL* targetURL;
@property (strong,nonatomic) NSMutableDictionary *callbacks;
@property (strong,nonatomic) SRWebSocket *webSocket;
@property int callbackCount;
@property BOOL isConnected;
@property (strong,nonatomic) NSMutableArray *pendingCalls;

@end

@implementation SDWebsocket


- (SDWebsocket*)initWithURL:(NSURL*)url {

    if ( [ self init ] ) {
    
        self.targetURL = url;
        self.webSocket = [ [ SRWebSocket alloc ] initWithURLRequest:[ NSURLRequest requestWithURL:url ] ];
        self.webSocket.delegate = self;
        self.delegate = nil;
        self.callbackCount = 0;
        self.isConnected = NO;

        self.pendingCalls = [ [ NSMutableArray alloc ] init ];
        self.callbacks = [ [ NSMutableDictionary alloc ] init ];

        if ( !channels )
            channels = [ [ NSMutableDictionary alloc ] init ];

    }

    return self;
    
}

- (void)dealloc {

    [ self close ];
    self.callbacks = nil;
    self.pendingCalls = nil;
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    self.targetURL = nil;

}


- (void)connect {

    if ( !self.delegate ) {
        [ NSException raise:@"SDWebsocketDelegateException" format:@"Cannot connect to server without valid delegate." ];
        return;
    }

    [ self.webSocket open ];
    
}



- (void)close {
    
    self.delegate = nil;
    [ self.webSocket close ];
    
}


- (void)send:(NSDictionary*)message {

    // Encode to json
    NSData *json = [ NSJSONSerialization dataWithJSONObject:message options:0 error:nil ];
    if ( !json ) {
        [ NSException raise:@"SDWebsocketJsonException" format:@"Cannot send message to json." ];
        return;
    }
    
    [ self.webSocket send:json ];

}


- (void)callRouter:(NSString*)routerName withVerb:(NSString*)verb withArguments:(NSDictionary*)args withCallback:(SocketCallback)callback {

    NSString *callbackID = [ NSString stringWithFormat:@"%d",self.callbackCount++ ];

    // Add the callbacks to the array
    [ self.callbacks setObject:callback forKey:callbackID ];

    // Create and send the message
    NSDictionary *message = @{@"verb":verb,
                              @"route":routerName,
                              @"args":args,
                              @"callbackname":callbackID};

    if ( self.isConnected )
        [ self send:message ];
    else
        [ self.pendingCalls insertObject:message atIndex:0 ];

}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {

    if ( ![ message isKindOfClass:[ NSString class ] ] ) {
        return;
    }
    
    NSString *data = message;
    if ( [ data characterAtIndex:0 ] != 'a' )
        return; // This data is not for the client. (Taken from Swampdragon's code)

    // Decode the message from json
    int len = [ data length ];
    NSString *tmpStr = [ [ data substringWithRange:NSMakeRange(2, len-3) ] stringByReplacingOccurrencesOfString:@"\\" withString:@"" ];
    if ( [ tmpStr characterAtIndex:0 ] == '"' )
        tmpStr = [ tmpStr substringWithRange:NSMakeRange(1, [ tmpStr length ]-2) ];

    NSData *msgData = [ tmpStr dataUsingEncoding:NSUTF8StringEncoding ];
    NSError *err;
    NSDictionary *msg = [ NSJSONSerialization JSONObjectWithData:msgData options:0 error:&err ];
    if ( !msg ) {
        [ NSException raise:@"SDWebsocketJsonException" format:@"Cannot decode message from json. Reason: %@",err ];
        return;
    }

    // Set up any new channels.
    NSDictionary *channelData = msg[@"channel_data"];
    if ( channelData != nil ) {

        NSArray *remoteChannels = channelData[@"remote_channels"];
        NSString *localChannel = channelData[@"local_channel"];
        for ( NSString *remoteChannel in remoteChannels )
            channels[remoteChannel] = localChannel;

    }

    // Analyse the context and perform callbacks.
    NSDictionary *context = msg[@"context"];
    if ( context != nil ) {

        NSString *callbackName = context[@"client_callback_name"];
        if ( callbackName ) {
        
            SocketCallback cb = self.callbacks[callbackName];
            if ( cb ) {
                cb( context, msg[@"data"] );
            }
            [ self.callbacks removeObjectForKey:callbackName ];
        
        }

    } else {    // Otherwise we have a proper channel message.

        [ self.delegate onMessage:msg fromChannel:channels[msg[@"channel"]] ];

    }
    
}


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {

    if ( [ self.pendingCalls count ] == 0 ) {
        for ( NSDictionary *message in self.pendingCalls )
            [ self send:message ];
        [ self.pendingCalls removeAllObjects ];
    }
    
    self.isConnected = YES;
    [ self.delegate socketOpened:self ];

}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {

    [ self.delegate onError:error forSocket:self ];
    
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {

    self.isConnected = NO;
    if ( !wasClean ) {
        [ self.delegate socketClosedCleanly:self ];
    } else {
        [ self.delegate socketClosed:self withCode:code andReason:reason ];
    }

}


@end
