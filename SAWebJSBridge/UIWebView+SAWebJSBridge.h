//
//  UIWebView+SAWebJSBridge.h
//  SABridgeDemo
//
//  Created by sagles on 15/7/1.
//  Copyright (c) 2015年 SA. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SABridgeCallback)(id responseObject);
typedef void(^SABridgeHandler)(id data, SABridgeCallback callback);

@interface UIWebView (SAWebJSBridge)

- (void)registerBridge;
- (void)addBridgeWithHandler:(SABridgeHandler)handler name:(NSString *)name;
- (void)sendMessage:(NSString *)message callback:(SABridgeCallback)callback;
- (void)tiggerHandler:(NSString *)handlerName data:(id)data callback:(SABridgeCallback)callback;

@end
