//
//  AppDelegate.m
//  cstore-example-ios
//
//  Created by 林小程 on 2020/7/10.
//  Copyright © 2020 bigo. All rights reserved.
//

#import "AppDelegate.h"
#import <CStoreMediaEngineKit/CStoreMediaEngineKit.h>
#import "CSMainViewController.h"
#import "KSCrash/KSCrash.h"
#import "KSCrash/KSCrashPendingCrash.h"
#import "CSUtils.h"
#import "CSDataStore.h"
#import "CSTranscodingInfoManager.h"
#import "CSTestArgSettingManager.h"
//#import "TuSDKManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (AppDelegate *)sharedInstance {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[CSTestArgSettingManager sharedInstance] prepare];
    
    [CStoreMediaEngineCore launchWithAppId:[CSDataStore sharedInstance].appId];
    
    // 可选: 设置日志输出级别 (默认不输出)
    
    /**
     *  初始化SDK，应用密钥是您的应用在 TuSDK 的唯一标识符。每个应用的包名(Bundle Identifier)、密钥、资源包(滤镜、贴纸等)三者需要匹配，否则将会报错。
     *
     *  @param appkey 应用秘钥 (请前往 https://tutucloud.com 申请秘钥)
     */
//    [[TuSDKManager sharedManager] initSdkWithAppKey:@"8c71548f7fbc33d2-04-ewdjn1"];
    
//    NSLog(@"TuSDK.framework 的版本号 : %@",lsqSDKVersion);
//    NSLog(@"TuSDKVideo.framework 的版本号 : %@",lsqVideoVersion);
//    NSLog(@"TuSDKFace.framework 的版本号 : %@",lsqFaceVersion);
    
    CSMainViewController *mainVC = [[UIStoryboard storyboardWithName:@"common" bundle:nil] instantiateViewControllerWithIdentifier:@"CSMainViewController"];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:mainVC];
    _globalNavController = navVC;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = navVC;
    [self.window makeKeyAndVisible];
    [[CSTranscodingInfoManager sharedInstance] prepare];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[CStoreMediaEngineCore sharedSingleton] onApplicationWillResignActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[CStoreMediaEngineCore sharedSingleton] onApplicationDidEnterBackground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[CStoreMediaEngineCore sharedSingleton] onApplicationDidBecomeActive];
}

@end
