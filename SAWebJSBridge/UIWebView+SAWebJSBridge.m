//
//  UIWebView+SAWebJSBridge.m
//  SABridgeDemo
//
//  Created by sagles on 15/7/1.
//  Copyright (c) 2015年 SA. All rights reserved.
//

#if DEBUG
#define SA_LOG(format, args...) NSLog(@"" format "", ## args);;
#else
#define SA_LOG(format, args...) do{}while(0)
#endif

#import "UIWebView+SAWebJSBridge.h"
#import <objc/runtime.h>

//Require
NSString *kSABridgeJSEnginName = @"sa_bridgeJSEnginName";
NSString *kSABridgeJSHandleOCMethodName = @"sa_bridgeJSHandleOCMethodName";
NSString *kSABridgeJSFetchQueueMethodName = @"sa_bridgeJSFetchQueueMethodName";
NSString *kSABridgeProtocolKey = @"sa_bridgeProtocolKey";
NSString *kSABridgeMsgKey = @"sa_bridgeMsgKey";
//Optional
NSString *kSABridgeBase64EncodeBlock = @"sa_bridgeBase64EncodeBlock";
NSString *kSABridgeBase64DecodeBlock = @"sa_bridgeBase64DecodeBlock";

NSString *kSABridgeRemoteNotifyKey = @"sa_bridgeRemoteNotifyKey";
NSString *kSABridgeSchemeKey = @"sa_bridgeSchemeKey";
NSString *kSABridgePluginKey = @"sa_bridgePluginKey";

//global id
static NSInteger sa_callback_id;
//global load num
static NSInteger sa_webView_load_num;

/**
 *  The serialization type for data which exchange between JS & OC
 */
typedef NS_ENUM(NSInteger, SASerializaitionType) {
    SASerializaitionTypeJson, //Ex.When your data is NSString
    SASerializaitionTypeBase64 //Ex.When your data is NSData
};

typedef NSDictionary SA_JSMSG;
@interface SABridgeEngin : NSObject <UIWebViewDelegate>

@property (nonatomic, weak) id<UIWebViewDelegate> sa_delegate;
@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, copy) NSDictionary *registInfo;
@property (nonatomic, copy) NSURL *jsPath;

@property (nonatomic, strong) NSMutableDictionary *sa_handlers;
@property (nonatomic, strong) NSMutableDictionary *sa_callbacks;
@property (nonatomic, strong) NSMutableArray *sa_queue;

@end

@implementation SABridgeEngin

- (void)sa_enqueue:(SA_JSMSG *)call {
    if (self.sa_queue) {
        [self.sa_queue addObject:call];
    }
    else {
        [self sa_dispatchCall:call];
    }
}

- (void)sa_sendData:(id)data callback:(SABridgeCallback)callback handler:(NSString *)handlerName {
    NSMutableDictionary *msg = [@{} mutableCopy];
    
    if (data) {
        if ([data isKindOfClass:[UIImage class]]) {
            data = [self sa_serializate:UIImagePNGRepresentation(data) type:SASerializaitionTypeBase64];
        }
        if ([data isKindOfClass:[NSData class]]) {
            data = [self sa_serializate:data type:SASerializaitionTypeBase64];
        }
        msg[kData] = data;
    }
    
    if (callback) {
        NSString *callbackId = [NSString stringWithFormat:@"sa_cb_%ld",++sa_callback_id];
        self.sa_callbacks[callbackId] = [callback copy];
        msg[kCallbackId] = callbackId;
    }
    
    if (handlerName) {
        msg[kHandlerName] = handlerName;
    }
    
    [self sa_enqueue:msg];
}

- (void)sa_dispatchCall:(SA_JSMSG *)call {
    NSString *msgJson = [self sa_serializate:call type:SASerializaitionTypeJson];
    
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    msgJson = [msgJson stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString *handleMethod = [self.registInfo[kSABridgeJSHandleOCMethodName] hasSuffix:@"()"] ?
    [self.registInfo[kSABridgeJSHandleOCMethodName] stringByReplacingOccurrencesOfString:@"()" withString:@""] :
    self.registInfo[kSABridgeJSHandleOCMethodName];
    
    
    NSString *jscmd = [NSString stringWithFormat:@"%@.%@('%@');",
                       self.registInfo[kSABridgeJSEnginName],
                       handleMethod,
                       msgJson];
    if ([[NSThread currentThread] isMainThread]) {
        [self.webView stringByEvaluatingJavaScriptFromString:jscmd];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView stringByEvaluatingJavaScriptFromString:jscmd];
        });
    }
    
}

- (NSString *)sa_serializate:(id)obj type:(SASerializaitionType) type {
    switch (type) {
        case SASerializaitionTypeJson: {
            NSData *_ = [NSJSONSerialization dataWithJSONObject:obj
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:nil];
            return [[NSString alloc] initWithData:_ encoding:NSUTF8StringEncoding];
        }
            break;
        case SASerializaitionTypeBase64: {
            SABase64Encode encode = self.registInfo[kSABridgeBase64EncodeBlock];
            if (encode) {
                return encode(obj);
            }
            return nil;
        }
            break;
        default:
            return nil;
            break;
    }
}

- sa_deserializate:(NSString *)data type:(SASerializaitionType) type {
    switch (type) {
        case SASerializaitionTypeJson: {
            id _ = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding]
                                                   options:NSJSONReadingAllowFragments
                                                     error:nil];
            return _;
        }
            break;
        case SASerializaitionTypeBase64: {
            SABase64Decode decode = self.registInfo[kSABridgeBase64DecodeBlock];
            if (decode) {
                return decode(data);
            }
            return nil;
        }
            break;
        default:
            return nil;
            break;
    }
}

void sa_flushQueue(id context) {
    SABridgeEngin *engin = (SABridgeEngin *)context;
    
    NSString *brackets = [engin.registInfo[kSABridgeJSFetchQueueMethodName] hasSuffix:@"()"] ? @"" : @"()";
    NSString *fetchJS = [NSString stringWithFormat:@"%@.%@%@",
                         engin.registInfo[kSABridgeJSEnginName],
                         engin.registInfo[kSABridgeJSFetchQueueMethodName],
                         brackets];
    NSString *queueMsg = [engin.webView stringByEvaluatingJavaScriptFromString:fetchJS];
    
    id msgs = [engin sa_deserializate:queueMsg type:SASerializaitionTypeJson];
    
    if ([msgs isKindOfClass:[NSArray class]]) {
        for (SA_JSMSG *msg in msgs) {
            if (![msg isKindOfClass:[SA_JSMSG class]]) {
                SA_LOG(@"WARNING: %@ invalid %@ recieved: %@",
                       engin.registInfo[kSABridgeJSEnginName],
                       [msg class],
                       msg);
                continue;
            }
            
            sa_call(context, msg);
        }
    }
    else if ([msgs isKindOfClass:[SA_JSMSG class]]) {
        sa_call(context, msgs);
    }
}

void sa_call(id context, SA_JSMSG *msg) {
    SABridgeEngin *engin = (SABridgeEngin *)context;
    
    NSString *callbackID = msg[kResponseId];
    if (callbackID) {
        SABridgeCallback callback = engin.sa_callbacks[callbackID];
        callback(msg[kResponseData]);
        [engin.sa_callbacks removeObjectForKey:callbackID];
    }
    else {
        callbackID = msg[kCallbackId];
        SABridgeCallback callback = NULL;
        if (callbackID) {
            callback = ^(id responseData) {
                if (!responseData) {
                    responseData = [NSNull null];
                }
                
                SA_JSMSG *jsmsg = @{kResponseId: callbackID, kResponseData: responseData};
                [engin sa_enqueue:jsmsg];
            };
        }
        
        SABridgeHandler handler = engin.sa_handlers[msg[kHandlerName]];
        if (!handler) {
            SA_LOG(@"WARNING %@ no handler for message form JS: %@",
                   engin.registInfo[kSABridgeJSEnginName],
                   msg);
        }
        else {
            handler(msg[kData], callback);
        }
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (webView != self.webView) { return YES; }
    
    NSURL *url = request.URL;
    if ([[url scheme] isEqualToString:self.registInfo[kSABridgeJSEnginName]]) {
        if ([[url host] isEqualToString:self.registInfo[kSABridgeMsgKey]]) {
            sa_flushQueue(self);
        }
        else {
            SA_LOG(@"WARNING: Received unknow command %@://%@", self.registInfo[kSABridgeJSEnginName],[url path]);
        }
        
        return NO;
    }
    else if ([self.sa_delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.sa_delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (webView != self.webView) { return; }
    
    ++sa_webView_load_num;
    
    if ([self.sa_delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.sa_delegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (webView != self.webView) { return; }
    
    --sa_webView_load_num;
    
    NSString *starJS = [NSString stringWithFormat:@"typeof %@",self.registInfo[kSABridgeJSEnginName]];
    if (sa_webView_load_num == 0 &&
        [[webView stringByEvaluatingJavaScriptFromString:starJS] isEqualToString:@"object"]) {
        NSString *js = [NSString stringWithContentsOfURL:self.jsPath
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
        [webView stringByEvaluatingJavaScriptFromString:js];
    }
    
    if (self.sa_queue) {
        for (SA_JSMSG *msg in self.sa_queue) {
            [self sa_dispatchCall:msg];
        }
        self.sa_queue = nil;
    }
    
    if ([self.sa_delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.sa_delegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (webView != self.webView) { return; }
    
    --sa_webView_load_num;
    
    if ([self.sa_delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.sa_delegate webView:webView didFailLoadWithError:error];
    }
}

@end

@implementation UIWebView (SAWebJSBridge)

#pragma mark - Public methods

- (void)sa_registerBridge:(NSDictionary *)registInfo jsPath:(NSURL *)path {
    
    SABridgeEngin *engine = objc_getAssociatedObject(self, _cmd);
    
    if (!engine) {
        
        registInfo = [self setDefaultInfo:registInfo];
        
        engine = [[SABridgeEngin alloc] init];
        engine.sa_delegate = self.delegate;
        engine.registInfo = registInfo;
        engine.jsPath = path;
        engine.sa_callbacks = [@{} mutableCopy];
        engine.sa_handlers = [@{} mutableCopy];
        engine.sa_queue = [@[] mutableCopy];
        self.delegate = engine;
        
        objc_setAssociatedObject(self, _cmd, engine, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)sa_addBridgeWithHandler:(SABridgeHandler)handler name:(NSString *)name {
    SABridgeEngin *engine = objc_getAssociatedObject(self, @selector(sa_registerBridge:jsPath:));
    engine.sa_handlers[name] = [handler copy];
}

- (void)sa_sendMessage:(id)data callback:(SABridgeCallback)callback {
    SABridgeEngin *engine = objc_getAssociatedObject(self, @selector(sa_registerBridge:jsPath:));
    [engine sa_sendData:data callback:callback handler:nil];
}

- (void)sa_dispatchHandler:(NSString *)handlerName data:(id)data callback:(SABridgeCallback)callback {
    SABridgeEngin *engine = objc_getAssociatedObject(self, @selector(sa_registerBridge:jsPath:));
    [engine sa_sendData:data callback:callback handler:handlerName];
}

- (void)sa_removeBridgeHandler:(NSString *)name {
    SABridgeEngin *engine = objc_getAssociatedObject(self, @selector(sa_registerBridge:jsPath:));
    [engine.sa_handlers removeObjectForKey:name];
}

#pragma mark - Private

- (NSDictionary *)setDefaultInfo:(NSDictionary *)registInfo {
    NSMutableDictionary *mutableInfo = [registInfo mutableCopy];
    if (!mutableInfo[kSABridgeJSEnginName]) {
        mutableInfo[kSABridgeJSEnginName] = @"SAJSBridgeDefaultEnginName";
    }
    if (!mutableInfo[kSABridgeJSHandleOCMethodName]) {
        mutableInfo[kSABridgeJSHandleOCMethodName] = @"__SAJSBridgeDefaultHandleMethodName__";
    }
    if (!mutableInfo[kSABridgeJSFetchQueueMethodName]) {
        mutableInfo[kSABridgeJSFetchQueueMethodName] = @"__SAJSBridgeDefaultFetchQueueMethodName__";
    }
    if (!mutableInfo[kSABridgeMsgKey]) {
        mutableInfo[kSABridgeMsgKey] = @"__SAJSBridgeDefaultMsgKey__";
    }
    
    return [mutableInfo copy];
}

@end
