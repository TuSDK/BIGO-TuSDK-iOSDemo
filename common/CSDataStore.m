//
//  CSDataStore.m
//  cstore-example-ios
//
//  Created by 林小程 on 2020/7/27.
//  Copyright © 2020 bigo. All rights reserved.
//

#import "CSDataStore.h"
#import "CSUtils.h"
#import "CSTestArgSettingManager.h"

static NSString * const kAppId = @"100273";
static NSString * const kCer = @"y4ichchhawpvria5u7fasb5wqpi8kjaodyqk0y7g0n1ivitv";

static NSString *const kUserAccountKey = @"kUserAccountKey";
static NSString *const kChannelNameKey = @"kChannelNameKey";

#define CSDataStoreSettingsKeyMaxResolutionType @"CSDataStoreSettingsKeyMaxResolutionType"
#define CSDataStoreSettingsKeyMaxFrameRate @"CSDataStoreSettingsKeyMaxFrameRate"


@implementation CSDataStore

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Getter && Setter
- (NSString *)lastUserName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserAccountKey];
}

- (void)setLastUserName:(NSString *)lastUserName {
    [[NSUserDefaults standardUserDefaults] setObject:lastUserName forKey:kUserAccountKey];
}

- (NSString *)lastChannelName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kChannelNameKey];
}

- (void)setLastChannelName:(NSString *)lastChannelName {
    [[NSUserDefaults standardUserDefaults] setObject:lastChannelName forKey:kChannelNameKey];
}

- (CSApp)app {
    static NSDictionary * targetMapApp;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        targetMapApp = @{
            @"video-live" : @(CSAppVideoLive),
            @"video-call-1v1" : @(CSAppVideoCall1V1),
            @"audio-live" : @(CSAppAudioLive),
            @"audio-call-1v1" : @(CSAppAudioCall1V1),
            @"video-live-basic-beauty" : @(CSAppVideoLiveBasicBeauty),
            @"video-call-1v1-basic-beauty" : @(CSAppVideoCall1V1BasicBeauty),
        };
    });
    
#ifdef TARGET_NAME
    if (TARGET_NAME.length > 0) {
        NSNumber *appNum = targetMapApp[TARGET_NAME];
        if (appNum) {
            return appNum.unsignedIntegerValue;
        }
    }
#endif
    
    return CSAppUnkown;
}

- (NSString *)welcomeText {
    switch ([self app]) {
        case CSAppVideoLive: {
            return @"欢迎来到Bigo视频直播";
            break;
        }
        case CSAppAudioLive: {
            return @"欢迎来到Bigo多人语音";
            break;
        }
        case CSAppVideoCall1V1: {
            return @"欢迎来到Bigo视频通话";
            break;
        }
        case CSAppAudioCall1V1: {
            return @"欢迎来到Bigo音频通话";
            break;
        }
        case CSAppVideoLiveBasicBeauty: {
            return @"欢迎来到Bigo基础美颜直播";
            break;
        }
        case CSAppVideoCall1V1BasicBeauty: {
            return @"欢迎来到Bigo 1v1基础美颜";
            break;
        }
        default: {
            return @"";
            break;
        }
    }
}

- (NSString *)powerByText {
    return [NSString stringWithFormat:@"Powered by BigoCloud %@", [CSUtils demoVersion]];
}

- (void)setMaxResolutionType:(CSMResolutionType)maxResolutionType {
    [[NSUserDefaults standardUserDefaults] setInteger:maxResolutionType forKey:CSDataStoreSettingsKeyMaxResolutionType];
}

- (CSMResolutionType)maxResolutionType {
    return [[NSUserDefaults standardUserDefaults] integerForKey:CSDataStoreSettingsKeyMaxResolutionType];
}

- (void)setMaxFrameRate:(CSMFrameRate)maxFrameRate {
    [[NSUserDefaults standardUserDefaults] setInteger:maxFrameRate forKey:CSDataStoreSettingsKeyMaxFrameRate];
}

- (CSMFrameRate)maxFrameRate {
    return [[NSUserDefaults standardUserDefaults] integerForKey:CSDataStoreSettingsKeyMaxFrameRate];
}

- (NSString *)appId {
    return kAppId;
}

- (NSString *)cer {
    return kCer;
}

@end
