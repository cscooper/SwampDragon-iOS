SwampDragon Websockets for iOS

## Disclaimer

"I accept no responsibility for the affects, adverse or otherwise, this code may have on you, your computer, your sanity, your dog, or anything else you can think of. Use at your own risk."

## Description:
This will allow your app to open a websocket to a Django-powered web server using the SwampDragon framework.
With this, you can subscribe to data in your server's database and display updates in real-time on your app.

## Requirements:
*  SocketRocket <http://corner.squareup.com/2012/02/socketrocket-websockets.html>
*  A Django webserver running SwampDragon

How to use:

1.  Write a class to implement the SDWebsocketDelegate protocol.
2.  Create an instance of the SDWebsocket class, using initWithURL:
3.  Set the delegate to your class.
4.  call connect:

Your delegate class must implement:

	- (void)onMessage:(NSDictionary*)message fromChannel:(NSString*)channel;


This is called upon receiving a message on the given channel. The channel will be one you have specified when subscribing to data.

You also have the following optional methods:

	- (void)socketOpened:(SDWebsocket*)socket;
	- (void)socketClosedCleanly:(SDWebsocket*)socket;
	- (void)socketClosed:(SDWebsocket*)socket withCode:(NSInteger)code andReason:(NSString*)reason;
	- (void)onError:(NSError*)error forSocket:(SDWebsocket*)socket;

To subscribe, run the following code:

	- (void)callRouter:routerName withVerb:@"subscribe" withArguments:@{@"channel":@"my-channel", <filter fields>} withCallback:^(NSDictionary *context, NSDictionary *msg) {
		// What do I do when I get a response to this message?
	}

`routerName` is the name of the router in your SwampDragon model.
`my-channel` can be replaced with anything you like, and will be sent back to you through the onMessage function (see above).
You can add further filters to the arguments, such as `@{@"name":myName}`, which will subscribe to rows where 'name' is equal to the contents of 'myName'

Problems or bug fixes:
Email me at andor734@gmail.com

