//
//  UIWebView+SAWebJSBridge.h
//  SABridgeDemo
//
//  Created by sagles on 15/7/1.
//  Copyright (c) 2015年 SA. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 @require
 */

//For JS Engin name
extern NSString *kSABridgeJSEnginName;
//For JS handle oc method name.Ex: EnginName.kSABridgeJSHandleOCMethodName('method');
extern NSString *kSABridgeJSHandleOCMethodName;
//Fetch all message for OC from JS.Ex: EnginName.kSABridgeJSFetchQueueMethodName();
extern NSString *kSABridgeJSFetchQueueMethodName;
//For receive message from JS
extern NSString *kSABridgeMsgKey;

/*
 @Optional
*/

//For serialize/deserialize data you send which is NSData,use the blocks under.If not set,it will return nil when serialize/deserialize.
extern NSString *kSABridgeBase64EncodeBlock;
extern NSString *kSABridgeBase64DecodeBlock;

//For remote notification
extern NSString *kSABridgeRemoteNotifyKey;
//For Open other application
extern NSString *kSABridgeSchemeKey;
//For Plugin module
extern NSString *kSABridgePluginKey;


//The keys use to transform model between JS & OC
static NSString *kData = @"data";
static NSString *kCallbackId = @"callbackId";
static NSString *kHandlerName = @"handlerName";

static NSString *kResponseId = @"responseId";
static NSString *kResponseData = @"responseData";


typedef void(^SABridgeCallback)(id responseObject);
typedef void(^SABridgeHandler)(id data, SABridgeCallback callback);

typedef NSString *(^SABase64Encode)(id data);
typedef NSData *(^SABase64Decode)(NSString *string);

@interface UIWebView (SAWebJSBridge)

- (void)sa_registerBridge:(NSDictionary *)registInfo jsPath:(NSURL *)path;//js file can be anywhere
- (void)sa_addBridgeWithHandler:(SABridgeHandler)handler name:(NSString *)name;
- (void)sa_sendMessage:(id)data callback:(SABridgeCallback)callback;
- (void)sa_dispatchHandler:(NSString *)handlerName data:(id)data callback:(SABridgeCallback)callback;

- (void)sa_removeBridgeHandler:(NSString *)name;

@end
