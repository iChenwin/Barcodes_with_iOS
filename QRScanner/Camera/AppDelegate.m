//
//  AppDelegate.m
//  Camera
//
//  Created by wayne on 2017/6/5.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import "AppDelegate.h"
#import "CWCameraPreviewController.h"

@interface AppDelegate () <CWCameraPreviewControllerDelegate>

@end

@implementation AppDelegate
{
    NSDataDetector *_urlDetector;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    CWCameraPreviewController *previewController = (CWCameraPreviewController *)self.window.rootViewController;
    
    previewController.delegate = self;
    
    _urlDetector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingType)NSTextCheckingTypeLink error:NULL];
    
    return YES;
}

- (void)previewController:(CWCameraPreviewController *)previewController didScanCode:(NSString *)code ofType:(NSString *)type {
    NSRange entireString = NSMakeRange(0, [code length]);
    NSArray *matches = [_urlDetector matchesInString:code options:0 range:entireString];
    
    for (NSTextCheckingResult *match in matches) {
        if ([[UIApplication sharedApplication] canOpenURL:match.URL]) {
            NSLog(@"Opening URL '%@' in external browser", [match.URL absoluteString]);
            [[UIApplication sharedApplication] openURL:match.URL options:@{} completionHandler:nil];
            
            break;
        } else {
            NSLog(@"Device cannot open URL '%@'", [match.URL absoluteString]);
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
