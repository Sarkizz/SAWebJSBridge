//
//  ViewController.m
//  SABridgeDemo
//
//  Created by sagles on 15/7/1.
//  Copyright (c) 2015年 SA. All rights reserved.
//

#import "ViewController.h"
#import "UIWebView+SAWebJSBridge.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupWebView];
}

- (void)setupWebView {
    //setup js bridge
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask,
                                                                  YES) firstObject];
    NSString *jsPath = [documentPath stringByAppendingString:@"/WebViewJavascriptBridge.js"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jsPath]) {
        [self.webView sa_registerBridge:@{kSABridgeJSFetchQueueMethodName: @"_fetchQueue",
                                          kSABridgeJSHandleOCMethodName: @"_dispatchMessageFromObjC"}
                                 jsPath:[NSURL URLWithString:jsPath]];
    }
    else {
        NSLog(@"No JS file.");
    }
    
    [self.webView sa_addBridgeWithHandler:^(id data, SABridgeCallback callback) {
        NSLog(@"test");
    } name:@"testJavascriptHandler"];
    
    //setup local html
    NSString *htmlPath = [documentPath stringByAppendingString:@"/doc_app1.html"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:htmlPath]) {
        NSError *error;
        NSString *html = [NSString stringWithContentsOfFile:htmlPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
        if (error) {
            NSLog(@"Load html file fail: %@",error);
        }
        else {
            [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:htmlPath]];
        }
    }
}

@end
