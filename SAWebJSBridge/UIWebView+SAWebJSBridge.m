//
//  UIWebView+SAWebJSBridge.m
//  SABridgeDemo
//
//  Created by sagles on 15/7/1.
//  Copyright (c) 2015年 SA. All rights reserved.
//

#import "UIWebView+SAWebJSBridge.h"
#import <objc/runtime.h>

NSString *sa_bridge_scheme = @"sajsbscheme";
NSString *sa_bridge_Msg = @"sajsbmsg";


@protocol SAWebViewDelegate <NSObject>
@optional
- (BOOL)sabridge_webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
- (void)sabridge_webViewDidFinishLoad:(UIWebView *)webView;
- (void)sabridge_webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;

@end
@interface SAWebViewDelegate : NSObject <SAWebViewDelegate>
@end

@implementation SAWebViewDelegate
@end

@interface UIWebView ()

@property (nonatomic, strong) SAWebViewDelegate *sa_delegate;

@end

@implementation UIWebView (SAWebJSBridge)

#pragma mark - Public methods

- (void)registerBridge {
    
    if (!self.sa_delegate) {
        
    }
    
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        Method originalMethod = class_getInstanceMethod([self.delegate class], @selector(webView:shouldStartLoadWithRequest:navigationType:));
        Method swizzlingMethod = class_getInstanceMethod(self.class, @selector(sabridge_webView:shouldStartLoadWithRequest:navigationType:));
        method_exchangeImplementations(originalMethod, swizzlingMethod);
    }
    else {
        
    }
}

- (void)addBridgeWithHandler:(SABridgeHandler)handler name:(NSString *)name {
    
}

- (void)sendMessage:(NSString *)message callback:(SABridgeCallback)callback {
    
}

- (void)tiggerHandler:(NSString *)handlerName data:(id)data callback:(SABridgeCallback)callback {
    
}

#pragma mark - Properties 

- (NSObject<SAWebViewDelegate> *)sa_delegate {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSa_delegate:(NSObject<SAWebViewDelegate> *)sa_delegate {
    objc_setAssociatedObject(self, @selector(sa_delegate), sa_delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
