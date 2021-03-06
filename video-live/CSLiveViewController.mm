//
//  CSLiveViewController.m
//  cstore-example-ios
//
//  Created by 林小程 on 2020/7/10.
//  Copyright © 2020 bigo. All rights reserved.
//

#import "CSLiveViewController.h"
#import "CSUtils.h"
#import <CStoreMediaEngineKit/CStoreMediaEngineKit.h>
#import "CSAccessPermissionsManager.h"
#import "CSInfoAlert.h"
#import "CSLiveDebugView.h"
#import "CSBeautyViewController.h"
#import "CSBeautyStickerViewController.h"
#import "CSBeautyManager.h"
#import "CSDataStore.h"
#import "CSTranscodingInfoManager.h"
#import "CSTestArgSettingManager.h"
#import "CSCaptureDeviceCamera.h"
#import "BigoAudioProcessing.hpp"
#import "CSMusicViewController.h"
#import <CStoreMediaEngineKit/CSMVideoCanvas.h>
#define kRtmpUrl @"rtmp://169.136.125.28/test/test2"

#import "TuSDKManager.h"

@interface CSLiveViewController ()
<
CSLiveDebugViewDataSource,
CStoreMediaEngineCoreDelegate,
CSCaptureDeviceDataOutputPixelBufferDelegate,
CSMusicViewControllerDelegate
>

@property (weak, nonatomic) IBOutlet GLKView *videoView;
@property (weak, nonatomic) IBOutlet UIButton *beautyBtn;
@property (weak, nonatomic) IBOutlet UIButton *stickerBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraBtn;
@property (weak, nonatomic) IBOutlet UIButton *muteAudioBtn;
@property (weak, nonatomic) IBOutlet UIButton *muteVideoBtn;
@property (weak, nonatomic) IBOutlet UIButton *lockRoomBtn;
@property (weak, nonatomic) IBOutlet UIView *addBlockListContainer;
@property (weak, nonatomic) IBOutlet UIButton *removeBlockList;
@property (weak, nonatomic) IBOutlet UIView *addWhiteListContainer;
@property (weak, nonatomic) IBOutlet UIButton *removeWhiteList;
@property (weak, nonatomic) IBOutlet UIButton *onMicBtn;
@property (weak, nonatomic) IBOutlet UIButton *earBackBtn;
@property (weak, nonatomic) IBOutlet UIButton *setIsCallModeBtn;
@property (nonatomic, strong) UIButton *pauseAllEffectButton; // 暂停所有音效
@property (nonatomic, strong) UIButton *resumeAllEffectButton; // 恢复播放所有音效
@property (nonatomic, strong) UIButton *stopAllEffectButton; // 恢复播放所有音效
@property (nonatomic, strong) UIButton *playAudioMixing; // 播放音乐文件
@property (nonatomic, strong) UIButton *pauseAudioMixing; // 暂停音乐文件
@property (nonatomic, strong) UIButton *stopAudioMixing; // 停止播放音乐文件
@property (nonatomic, strong) UISlider *audioMixingSlider; // 音乐文件播放进度
@property (nonatomic, strong) UIButton *playGuideVoice;    // 播放导唱文件
@property (nonatomic, strong) UIButton *pauseGuideVoice;    // 暂停导唱文件
@property (nonatomic, strong) UIButton *stopGuideVoice;   // 停止播放导唱文件
@property (nonatomic, strong) UISlider *guideVoiceSlider;  // 导唱播放进度
@property (nonatomic, strong) UIButton *playAudioEffect;   // 播放音效文件
@property (nonatomic, strong) UIButton *pauseAudioEffect;   // 播放音效文件
@property (nonatomic, strong) UIButton *stopAudioEffect;   // 停止播放音效文件
@property (nonatomic, strong) UISlider *audioEffectSlider; // 音效文件播放进度
@property (strong, nonatomic) IBOutletCollection(UIStackView) NSArray *bottomFunEreas;


@property (nonatomic, strong) CStoreMediaEngineCore *mediaEngine;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, CSMChannelMicUser *> *micUsers;
@property (nonatomic, assign) BOOL isBeautyOpened;
@property (nonatomic, assign) BOOL isAudioMuted;
@property (nonatomic, assign) BOOL isVideoMuted;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) BOOL isUseCallMode;
@property (nonatomic, assign) BOOL isEarBacking;
@property (nonatomic, strong) NSMutableSet<NSString *> *rtmpUrls;

@property (nonatomic, strong) CSCaptureDeviceCamera *captureDevice;

@property(nonatomic, assign)BOOL customCapture;

@property (nonatomic, strong)CSMusicViewController *musicViewController;

@property(nonatomic, strong)CSMVideoCanvas *previewCanvas;
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, CSMVideoCanvas *> *remoteCanvas;

@property(nonatomic, strong)CSMLocalVideoStats *localVideoStas;
@property(nonatomic, strong)CSMLocalAudioStats *localAudioStats;

@end

@implementation CSLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _remoteCanvas = [NSMutableDictionary dictionary];
    _rtmpUrls = [NSMutableSet set];
    
    [self initTuSDKUI];
    
    //设置debug页面
    [self setupMSDebugView];
//    [self setupViews];
    
    self.onMicBtn.selected = self.clientRole == CSMClientRoleAudience;
    
    //设置用户角色、渲染视图
    self.mediaEngine = [CStoreMediaEngineCore sharedSingleton];
    self.mediaEngine.delegate = self;
    if (self.customCapture) {
        [self.mediaEngine enableCustomVideoCapture:YES];
    }
    [self.mediaEngine enableMultiViewRender:TestArg.multiViewRenderMode];
    [self.mediaEngine setClientRole:self.clientRole];
    if (!TestArg.multiViewRenderMode) { //多View绘制
        [self.mediaEngine attachRendererView:self.videoView];
    }
    
    if (self.clientRole == CSMClientRoleBroadcaster) { //主播需要请求摄像头和麦克风权限
        __weak typeof(self) weakSelf = self;
        [CSAccessPermissionsManager requestCameraPermissionCompletionHandler:^(BOOL granted) {
            MainThreadBegin
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            if (granted) {
                [strongSelf.mediaEngine startPreview];
                strongSelf.isBeautyOpened = YES;
                
                if (strongSelf.micUsers.count != 0) { //如果请求权限后，已经有人上下麦，则不再显示预览页面
                    return;
                }
                    // 设置预览画面
                if (TestArg.multiViewRenderMode) { //多View绘制
                    CSMVideoCanvas *localCanvas = [[CSMVideoCanvas alloc] init];
                    localCanvas.uid = 0; //预览时需要把uid设为0，开播后触发didClientRoleChanged回调再刷新
                    localCanvas.view = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
                    [strongSelf.view addSubview:localCanvas.view];
                    [strongSelf.view sendSubviewToBack:localCanvas.view];
                    [(UIControl *)localCanvas.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:strongSelf action:@selector(toastIsInMultiViewRenderMode)]];
                    strongSelf.previewCanvas = localCanvas;
                    [strongSelf.mediaEngine setupLocalVideo:localCanvas];
                } else {
                    CSMVideoRenderer *videoRenderer = [[CSMVideoRenderer alloc] init];
                    videoRenderer.renderFrame = CGRectMake(0, 0, strongSelf.view.frame.size.width, strongSelf.view.frame.size.height);
                    videoRenderer.uid = 0; //预览时需要把uid设为0，开播后触发didClientRoleChanged回调再刷新
                    videoRenderer.seatNum = 1;
                    [strongSelf.mediaEngine setVideoRenderers:@[videoRenderer]];
                }
            }
            [CSAccessPermissionsManager requestMicrophonePermissionCompletionHandler:^(BOOL granted) {
                
            }];
            MainThreadCommit
        }];
    }
    
    __weak typeof(self) weakSelf = self;
    [self joinChannelWithCompletion:^(BOOL success) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        
        [BigoAudioProcessing  registerAudioPreprocessing:self.mediaEngine];
        [self.mediaEngine enableAudioVolumeIndication:200 smooth:3 report_vad:FALSE];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[CSBeautyManager sharedInstance] prepare];
        });
    }];
    [self refreshToolView];
    
}

- (void)toastIsInMultiViewRenderMode {
    [CSInfoAlert showInfo:@"正处于多View绘制模式"];
}

- (void)setupViews {
    self.view.backgroundColor = [UIColor blackColor];
    
    _playAudioMixing = [[UIButton alloc] init];
    _playAudioMixing.layer.cornerRadius = 5;
    _playAudioMixing.clipsToBounds = YES;
    [_playAudioMixing setTitle:@"音乐播放" forState:UIControlStateNormal];
    [_playAudioMixing setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playAudioMixing.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [_playAudioMixing addTarget:self action:@selector(actionDidTapAudioPlayBtn:) forControlEvents:UIControlEventTouchUpInside];
    _playAudioMixing.frame = CGRectMake(0, 54, 64, 44);
    [self.view addSubview:_playAudioMixing];
    
    _pauseAudioMixing = [[UIButton alloc] init];
    _pauseAudioMixing.layer.cornerRadius = 5;
    _pauseAudioMixing.clipsToBounds = YES;
    [_pauseAudioMixing setTitle:@"暂停播放" forState:UIControlStateNormal];
    [_pauseAudioMixing setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_pauseAudioMixing.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [_pauseAudioMixing addTarget:self action:@selector(actionDidTapAudioPauseBtn:) forControlEvents:UIControlEventTouchUpInside];
    _pauseAudioMixing.frame = CGRectMake(CGRectGetMaxX(_playAudioMixing.frame) + 40, 54, 64, 44);
    [self.view addSubview:_pauseAudioMixing];
    
    _stopAudioMixing = [[UIButton alloc] init];
    _stopAudioMixing.layer.cornerRadius = 5;
    _stopAudioMixing.clipsToBounds = YES;
    [_stopAudioMixing setTitle:@"停止播放" forState:UIControlStateNormal];
    [_stopAudioMixing setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_stopAudioMixing.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [_stopAudioMixing addTarget:self action:@selector(actionDidTapAudioStopBtn:) forControlEvents:UIControlEventTouchUpInside];
    _stopAudioMixing.frame = CGRectMake(CGRectGetMaxX(_pauseAudioMixing.frame) + 40, 54, 64, 44);
    [self.view addSubview:_stopAudioMixing];
    
    _audioMixingSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_stopAudioMixing.frame) + 5, 200, 44)];
    _audioMixingSlider.minimumValue = 0;// 设置最小值
    _audioMixingSlider.maximumValue = 100;
    _audioMixingSlider.minimumTrackTintColor = [UIColor greenColor];
    _audioMixingSlider.maximumTrackTintColor = [UIColor redColor];
    _audioMixingSlider.value = 0;
    [_audioMixingSlider addTarget:self
              action:@selector(onProgressAudioMixingEndSlide:)
    forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:_audioMixingSlider];
    
   _playGuideVoice = [[UIButton alloc] init];
   _playGuideVoice.layer.cornerRadius = 5;
   _playGuideVoice.clipsToBounds = YES;
   [_playGuideVoice setTitle:@"导唱播放" forState:UIControlStateNormal];
   [_playGuideVoice setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
   [_playGuideVoice.titleLabel setFont:[UIFont systemFontOfSize:12]];
   [_playGuideVoice addTarget:self action:@selector(actionDidTapGuidePlayBtn:) forControlEvents:UIControlEventTouchUpInside];
   _playGuideVoice.frame = CGRectMake(0, CGRectGetMaxY(_audioMixingSlider.frame) + 5, 64, 44);
   [self.view addSubview:_playGuideVoice];
    
    _pauseGuideVoice = [[UIButton alloc] init];
    _pauseGuideVoice.layer.cornerRadius = 5;
    _pauseGuideVoice.clipsToBounds = YES;
    [_pauseGuideVoice setTitle:@"暂停播放" forState:UIControlStateNormal];
    [_pauseGuideVoice setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_pauseGuideVoice.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [_pauseGuideVoice addTarget:self action:@selector(actionDidTapGuidePauseBtn:) forControlEvents:UIControlEventTouchUpInside];
    _pauseGuideVoice.frame = CGRectMake(CGRectGetMaxX(_playGuideVoice.frame) + 40, CGRectGetMaxY(_audioMixingSlider.frame) + 5, 64, 44);
    [self.view addSubview:_pauseGuideVoice];
    
   _stopGuideVoice = [[UIButton alloc] init];
   _stopGuideVoice.layer.cornerRadius = 5;
   _stopGuideVoice.clipsToBounds = YES;
   [_stopGuideVoice setTitle:@"停止播放" forState:UIControlStateNormal];
   [_stopGuideVoice setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
   [_stopGuideVoice.titleLabel setFont:[UIFont systemFontOfSize:12]];
   [_stopGuideVoice addTarget:self action:@selector(actionDidTapGuideStopBtn:) forControlEvents:UIControlEventTouchUpInside];
   _stopGuideVoice.frame = CGRectMake(CGRectGetMaxX(_pauseGuideVoice.frame) + 40, CGRectGetMaxY(_audioMixingSlider.frame) + 5, 64, 44);
   [self.view addSubview:_stopGuideVoice];
    
    _guideVoiceSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_stopGuideVoice.frame) + 5, 200, 44)];
    _guideVoiceSlider.minimumValue = 0;// 设置最小值
    _guideVoiceSlider.maximumValue = 100;
    _guideVoiceSlider.minimumTrackTintColor = [UIColor greenColor];
    _guideVoiceSlider.maximumTrackTintColor = [UIColor redColor];
    _guideVoiceSlider.value = 0;
    [_guideVoiceSlider addTarget:self action:@selector(onProgressGuideVoiceSliding:) forControlEvents:UIControlEventValueChanged];
    [_guideVoiceSlider addTarget:self action:@selector(onProgressGuideVoiceEndSlide:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:_guideVoiceSlider];
    
    _playAudioEffect = [[UIButton alloc] init];
    _playAudioEffect.layer.cornerRadius = 5;
    _playAudioEffect.clipsToBounds = YES;
    [_playAudioEffect setTitle:@"音效1播放" forState:UIControlStateNormal];
    [_playAudioEffect setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playAudioEffect.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [_playAudioEffect addTarget:self action:@selector(actionDidTapAudioEffectPlayBtn:) forControlEvents:UIControlEventTouchUpInside];
    _playAudioEffect.frame = CGRectMake(0, CGRectGetMaxY(_guideVoiceSlider.frame) + 5, 64, 44);
    [self.view addSubview:_playAudioEffect];

    _pauseAudioEffect = [[UIButton alloc] init];
    _pauseAudioEffect.layer.cornerRadius = 5;
    _pauseAudioEffect.clipsToBounds = YES;
    [_pauseAudioEffect setTitle:@"暂停播放" forState:UIControlStateNormal];
    [_pauseAudioEffect setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_pauseAudioEffect.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [_pauseAudioEffect addTarget:self action:@selector(actionDidTapAudioEffectPauseBtn:) forControlEvents:UIControlEventTouchUpInside];
    _pauseAudioEffect.frame = CGRectMake(CGRectGetMaxX(_playAudioEffect.frame) + 40, CGRectGetMaxY(_guideVoiceSlider.frame) + 5, 64, 44);
    [self.view addSubview:_pauseAudioEffect];
    
    _stopAudioEffect = [[UIButton alloc] init];
    _stopAudioEffect.layer.cornerRadius = 5;
    _stopAudioEffect.clipsToBounds = YES;
    [_stopAudioEffect setTitle:@"停止播放" forState:UIControlStateNormal];
    [_stopAudioEffect setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_stopAudioEffect.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [_stopAudioEffect addTarget:self action:@selector(actionDidTapAudioEffectStopBtn:) forControlEvents:UIControlEventTouchUpInside];
    _stopAudioEffect.frame = CGRectMake(CGRectGetMaxX(_pauseAudioEffect.frame) + 40, CGRectGetMaxY(_guideVoiceSlider.frame) + 5, 64, 44);
    [self.view addSubview:_stopAudioEffect];

    _audioEffectSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_stopAudioEffect.frame) + 5, 200, 44)];
    _audioEffectSlider.minimumValue = 0;// 设置_audioEffectSlider
    _audioEffectSlider.maximumValue = 100;
    _audioEffectSlider.minimumTrackTintColor = [UIColor greenColor];
    _audioEffectSlider.maximumTrackTintColor = [UIColor redColor];
    _audioEffectSlider.value = 0;
    [_audioEffectSlider addTarget:self action:@selector(onProgressEffectSliderEndSlide:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:_audioEffectSlider];

}


- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine localAudioEffectStateChange:(BigoAudioMixingStateCode)state soundId:(NSInteger)soundId reason:(NSUInteger)reason {
    [self.musicViewController localAudioEffectStateChange:state soundId:soundId reason:reason];
}
    
- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine localAudioMixingStateDidChanged:(BigoAudioMixingStateCode)state  reason:(NSUInteger)reason {
    [self.musicViewController localAudioMixingStateDidChanged:state reason:reason];
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine reportAudioVolumeIndicationOfSpeakers:(NSArray*)uid volume:(NSArray*)volume vad:(NSArray*)vad channelId:(NSArray<NSString *>*)channelId totalVolume:(NSUInteger)totalVolume{
    [self.musicViewController reportAudioVolumeIndicationOfSpeakers:uid volume:volume vad:vad channelId:channelId totalVolume:totalVolume];
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine activeSpeaker:(int64_t)uid{
    [self.musicViewController activeSpeaker:uid];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)setupMSDebugView {
    CSLiveDebugView *view = [[CSLiveDebugView alloc] initWithFrame:self.view.bounds vc:self];
    view.dataSource = (id<CSLiveDebugViewDataSource>)self;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:view];
}

//退房
- (void)leaveRoom {
    [[CSBeautyManager sharedInstance] unprepare];
    [self.mediaEngine leaveChannel];
    self.mediaEngine.delegate = nil;
    self.mediaEngine = nil;
}

//更新功能按钮
- (void)refreshToolView {
    MainThreadBegin
    BOOL isBroadcaster = self.clientRole == CSMClientRoleBroadcaster;
    self.onMicBtn.selected = !isBroadcaster;

    self.beautyBtn.hidden = !isBroadcaster;
#if AdvancedBeauty
    self.stickerBtn.hidden = !isBroadcaster;
#else
    self.stickerBtn.hidden = YES;
#endif
    self.switchCameraBtn.hidden = !isBroadcaster;
    self.muteAudioBtn.hidden = !isBroadcaster;
    self.muteVideoBtn.hidden = !isBroadcaster;
    self.lockRoomBtn.hidden = !isBroadcaster;
    
    self.addWhiteListContainer.hidden = self.removeWhiteList.hidden = !isBroadcaster || !self.isLocked;
    self.addBlockListContainer.hidden = self.removeBlockList.hidden = !isBroadcaster || self.isLocked;
    MainThreadCommit
}

#pragma mark - Action
- (IBAction)actionDidTapQuit:(UIButton *)sender {
    [self leaveRoom];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)actionDidTapBueaty:(UIButton *)sender {
    [self cs_hideBottomFunAreas:YES];
    __weak typeof(self) weakSelf = self;
    [CSBeautyViewController showInVC:self dismissBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        [strongSelf cs_hideBottomFunAreas:NO];
    }];
}

- (IBAction)actionDidTapSwitchCamera:(UIButton *)sender {
    if (self.customCapture) {
        [self.captureDevice switchCameraPosition];
    } else {
        [self.mediaEngine switchCamera];
    }
}

- (IBAction)actionDidTapMuteAudio:(UIButton *)sender {
    self.isAudioMuted = !self.isAudioMuted;
    [self.mediaEngine muteLocalAudioStream:self.isAudioMuted];
    self.muteAudioBtn.selected = self.isAudioMuted;
}

- (IBAction)actionDidTapMuteVideo:(UIButton *)sender {
    self.isVideoMuted = !self.isVideoMuted;
    [self.mediaEngine muteLocalVideoStream:self.isVideoMuted];
    self.muteVideoBtn.selected = self.isVideoMuted;
}

- (IBAction)actionDidTapChangeRole:(UIButton *)sender {
    CSMClientRole clientRole = self.clientRole == CSMClientRoleBroadcaster ? CSMClientRoleAudience : CSMClientRoleBroadcaster;
    [self.mediaEngine setClientRole:clientRole];
}

- (IBAction)actionDidTapLockRoom:(UIButton *)sender {
    self.lockRoomBtn.enabled = NO;
     __weak typeof(self) weakSelf = self;
    if (self.isLocked) {
        [self.mediaEngine switchToPublicRoom:nil blockTime:0 appendBlackUidList:nil completion:^(BOOL success, CSMErrorCode resCode) {
            MainThreadBegin
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            NSLog(@"switchToPublicRoom, success:%d, code:%d", success, resCode);
            if (success) {
                strongSelf.isLocked = NO;
                strongSelf.lockRoomBtn.enabled = YES;
                strongSelf.lockRoomBtn.selected = NO;
                [strongSelf refreshToolView];
                [CSInfoAlert showInfo:@"设置成功"];
            } else {
                [CSInfoAlert showInfo:[NSString stringWithFormat:@"设置失败:%d", resCode]];
            }
            MainThreadCommit
        }];
    } else {
        [self.mediaEngine switchToPrivacyRoom:0 accessToken:self.token whiteUidList:@[ @(self.myUid) ] completion:^(BOOL success, CSMErrorCode resCode) {
            MainThreadBegin
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            NSLog(@"switchToPrivacyRoom, success:%d, code:%d", success, resCode);
            if (success) {
                strongSelf.isLocked = YES;
                strongSelf.lockRoomBtn.enabled = YES;
                strongSelf.lockRoomBtn.selected = YES;
                [strongSelf refreshToolView];
                [CSInfoAlert showInfo:@"设置成功"];
            } else {
                [CSInfoAlert showInfo:[NSString stringWithFormat:@"设置失败:%d", resCode]];
            }
            MainThreadCommit
        }];
    }
}

- (IBAction)actionDidTapAddBlockUid:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self cs_showPrivacyTextFieldAlertWithText:@"请输入要加入黑名单的uid:" sureAction:^(uint64_t uid) {
        [self.mediaEngine updateBlackUidList:0 accessToken:@"" appendList:@[ @(uid) ] removeList:nil completion:^(BOOL success, CSMErrorCode resCode) {
            MainThreadBegin
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            NSLog(@"addBlockUid, success:%d, code:%d", success, resCode);
            if (success) {
                [CSInfoAlert showInfo:@"设置成功"];
                [strongSelf.mediaEngine kickUser:0 accessToken:@"" kickUidList:@[ @(uid) ] blockTime:1 completion:nil];
            } else {
                [CSInfoAlert showInfo:[NSString stringWithFormat:@"设置失败:%d", resCode]];
            }
            MainThreadCommit
        }];
    }];
}

- (IBAction)actionDidTapRemoveBlockUid:(id)sender {
    [self cs_showPrivacyTextFieldAlertWithText:@"请输入要移除黑名单的uid:" sureAction:^(uint64_t uid) {
        [self.mediaEngine updateBlackUidList:0 accessToken:@"" appendList:nil removeList:@[ @(uid) ] completion:^(BOOL success, CSMErrorCode resCode) {
            MainThreadBegin
            NSLog(@"removeBlockUid, success:%d, code:%d", success, resCode);
            if (success) {
                [CSInfoAlert showInfo:@"设置成功"];
            } else {
                [CSInfoAlert showInfo:[NSString stringWithFormat:@"设置失败:%d", resCode]];
            }
            MainThreadCommit
        }];
    }];
}
- (IBAction)actionDidTapAddWhiteUid:(id)sender {
    [self cs_showPrivacyTextFieldAlertWithText:@"请输入要加入白名单的uid:" sureAction:^(uint64_t uid) {
        [self.mediaEngine updateWhiteUidList:0 accessToken:@"" appendList:@[ @(uid) ] removeList:nil completion:^(BOOL success, CSMErrorCode resCode) {
            MainThreadBegin
            NSLog(@"addWhiteUid, success:%d, code:%d", success, resCode);
            if (success) {
                [CSInfoAlert showInfo:@"设置成功"];
            } else {
                [CSInfoAlert showInfo:[NSString stringWithFormat:@"设置失败:%d", resCode]];
            }
            MainThreadCommit
        }];
    }];
}

- (IBAction)actionDidTapRemoveWhiteUid:(id)sender {
    [self cs_showPrivacyTextFieldAlertWithText:@"请输入要移除白名单的uid:" sureAction:^(uint64_t uid) {
        [self.mediaEngine updateWhiteUidList:0 accessToken:@"" appendList:nil removeList:@[ @(uid) ] completion:^(BOOL success, CSMErrorCode resCode) {
            MainThreadBegin
            NSLog(@"removeWhiteUid, success:%d, code:%d", success, resCode);
            if (success) {
                [CSInfoAlert showInfo:@"设置成功"];
            } else {
                [CSInfoAlert showInfo:[NSString stringWithFormat:@"设置失败:%d", resCode]];
            }
            MainThreadCommit
        }];
    }];
}

- (IBAction)actionDidTapSticker:(id)sender {
    [self cs_hideBottomFunAreas:YES];
    __weak typeof(self) weakSelf = self;
    [CSBeautyStickerViewController showInVC:self dismissBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        [strongSelf cs_hideBottomFunAreas:NO];
    }];
}

- (IBAction)actionDidTapAddRtmpUrl:(UIButton *)sender {
    [self cse_setPublishStreamUrlWithAddOrRemove:YES];
}

- (IBAction)actionDidTapRemoveRtmUrl:(UIButton *)sender {
    [self cse_setPublishStreamUrlWithAddOrRemove:NO];
}

- (void)cse_setPublishStreamUrlWithAddOrRemove:(BOOL)addOrRemove {
    NSString *exitstUrl = [[self.rtmpUrls allObjects] componentsJoinedByString:@","];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:addOrRemove ? @"增加旁路推流url" : @"删除旁路推流url" message:[NSString stringWithFormat:@"当前已设置的url:%@", exitstUrl] preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"rtmp://";
#ifdef DEBUG //linxiaocheng
        textField.text = @"rtmp://169.136.125.28/test/2727";
#endif
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    __weak typeof(alert) weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        NSString *url = weakAlert.textFields.firstObject.text;
        if (url.length == 0) {
            [CSInfoAlert showInfo:@"url不能为空"];
            return;
        }
        
        if (addOrRemove) {
            [self.mediaEngine addPublishStreamUrl:url];
        } else {
            [self.mediaEngine removePublishStreamUrl:url];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)actionDidTapVolumeMode:(UIButton *)sender {
    self.isUseCallMode = !self.isUseCallMode;
}

- (IBAction)actionDidTapStartTranscoding:(UIButton *)sender {
    NSMutableArray<NSNumber *> *uids = [NSMutableArray array];
    [[self.micUsers.allValues sortedArrayUsingComparator:^NSComparisonResult(CSMChannelMicUser * obj1, CSMChannelMicUser *obj2) {
        return [@(obj1.uid) compare:@(obj2.uid)];
    }] enumerateObjectsUsingBlock:^(CSMChannelMicUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [uids addObject:@(obj.uid)];
    }];
    
    NSUInteger supportOnMicCount = [[CSTranscodingInfoManager sharedInstance] transcodingUserCountInPk:NO];
    if (supportOnMicCount < uids.count) {
        NSString *msg = [NSString stringWithFormat:@"当前只支持%lu人合流，请先在合流设置页面Transcoding Users一行增加更多用户的布局参数", (unsigned long)supportOnMicCount];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"合流设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController pushViewController:[CSModiTranscodingFormController formControllerWithPkOrMic:NO] animated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        int result = [self.mediaEngine setLiveTranscoding:[[CSTranscodingInfoManager sharedInstance] transcodingInPk:NO withUids:uids]];
        if (result == 0) {
            [CSInfoAlert showInfo:@"已启动合流"];
        } else if(result == -5) {
            [CSInfoAlert showInfo:@"视频布局参数无效"];
        }
    }
}

- (IBAction)actionDidTapStopTranscoding:(UIButton *)sender {
    [self.mediaEngine stopLiveTranscoding];
    [CSInfoAlert showInfo:@"已停止合流"];
}

- (IBAction)actionDidTapTranscodingSetting:(UIButton *)sender {
    [self.navigationController pushViewController:[CSModiTranscodingFormController formControllerWithPkOrMic:NO] animated:YES];
}

- (IBAction)actionDidTapEarBack:(UIButton *)sender {
    self.isEarBacking = !self.isEarBacking;
    [self.mediaEngine enableInEarMonitoring:self.isEarBacking];
    self.earBackBtn.selected = self.isEarBacking;
}

- (IBAction)actionDidTapMusic:(UIButton *)sender {
    if (!self.musicViewController) {
        self.musicViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([CSMusicViewController class])];
        self.musicViewController.delegate = self;
    }
    
    if ([self.musicViewController.view superview]) {
        [self.musicViewController.view removeFromSuperview];
    } else {
        [self.view addSubview:self.musicViewController.view];
    }
}

#pragma mark - Privacy Helper
- (void)cs_showPrivacyTextFieldAlertWithText:(NSString *)text sureAction:(void(^)(uint64_t uid))sureAction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"uid";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *uidStr = [CSUtils trimedString:alert.textFields[0].text];
        if (sureAction && uidStr.length > 0) {
            NSScanner *scanner = [NSScanner scannerWithString:uidStr];
            uint64_t uid = 0;
            [scanner scanUnsignedLongLong:&uid];
            if (uid > 0) {
                sureAction(uid);
            }
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - BLLiveDebugViewDataSource
- (NSString *)mssdkDebugInfoForLiveDebugView:(CSLiveDebugView *)liveDebugView {
    return [NSString stringWithFormat:@"%@\nlocalVideoStas:%@\nlocalAudioStats:%@", [self.mediaEngine mssdkDebugInfo], self.localVideoStas ?: @"", self.localAudioStats ?: @""];
}

#pragma mark - CStoreMediaEngineCoreDelegate
- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine connectionChangedToState:(CSMConnectionStateType)state {
    MainThreadBegin
    [CSInfoAlert showInfo:[NSString stringWithFormat:@"connection changed to state %d", state]];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine firstRemoteVideoFrameOfUid:(uint64_t)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    MainThreadBegin
    [CSInfoAlert showInfo:[NSString stringWithFormat:@"first remote video frame of uid %llu size %@", uid, NSStringFromCGSize(size)]];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine userJoined:(CSMChannelMicUser *)user elapsed:(NSInteger)elapsed {
    MainThreadBegin
    if (user.extraInfo.length > 0) {
        [CSInfoAlert showInfo:[NSString stringWithFormat:@"user %llu join:%@", user.uid, user.extraInfo] vertical:0.7];
    } else {
        [CSInfoAlert showInfo:[NSString stringWithFormat:@"user %llu join", user.uid] vertical:0.7];
    }
    
    self.micUsers[@(user.uid)] = user;
    [self updateRenderView];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine userOffline:(CSMChannelMicUser *)user reason:(int)reason {
    MainThreadBegin
    [CSInfoAlert showInfo:[NSString stringWithFormat:@"user %llu offline", user.uid]];
    
    NSLog(@"UserOffline %@", user);
    if ([self.micUsers.allKeys containsObject:@(user.uid)]) {
        self.micUsers[@(user.uid)] = nil;
    }
    [self.remoteCanvas[@(user.uid)].view removeFromSuperview];
    self.remoteCanvas[@(user.uid)] = nil;
    [self updateRenderView];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine didClientRoleChanged:(CSMClientRole)oldRole newRole:(CSMClientRole)newRole clientRoleInfo:(CSMChannelMicUser *)clientRoleInfo channelName:(NSString *)channelName {
    NSLog(@"didClientRoleChanged newRole:%d oldRole:%d channelName:%@ %@", newRole, oldRole, channelName, clientRoleInfo);
    MainThreadBegin
    self.clientRole = newRole;
    
    if (newRole == CSMClientRoleBroadcaster) {
        self.micUsers[@(clientRoleInfo.uid)] = clientRoleInfo;
        
        //重新上麦后，会重新打开视频和音频，刷新一下UI
        self.isAudioMuted = NO;
        self.muteAudioBtn.selected = NO;
        self.isVideoMuted = NO;
        self.muteVideoBtn.selected = NO;
    } else if (newRole == CSMClientRoleAudience) {
        self.micUsers[@(self.myUid)] = nil;
        [self.previewCanvas.view removeFromSuperview];
        self.previewCanvas = nil;
    }
    
    [self updateRenderView];
    [self refreshToolView];
    MainThreadCommit
}

- (CGRect)frameOfUserAtIndex:(NSUInteger)index totalMicUsersCount:(NSUInteger)total {
    CGRect result = CGRectZero;
    CGFloat width = self.videoView.frame.size.width;
    CGFloat height = self.videoView.frame.size.height;
    if (total <= 3) {
        CGFloat smallWindowWidth = width / 3;
        CGFloat smallWindowHeight = smallWindowWidth / 9 * 16; //视频比例16:9
        if (index == 0) {
            result = CGRectMake(0, 0, width, height);
        } else if (index == 1) {
            result = CGRectMake(width - smallWindowWidth, height - 50 - smallWindowHeight, smallWindowWidth, smallWindowHeight);
        } else if (index == 2) {
            result = CGRectMake(width - smallWindowWidth, height - 50 - 2 * smallWindowHeight, smallWindowWidth, smallWindowHeight);
        }
    } else {
        int totalColumn = (total <= 2) ? 1 : 2;
        int totalRow = (total <= 2) ? total : (total+1) / 2;
        CGFloat micW = width / totalColumn;
        CGFloat micH = height / totalRow;
        
        NSUInteger row = index / totalColumn;
        NSUInteger col = index % totalColumn;
        result = CGRectMake(col * micW, row * micH, micW, micH);
    }
    return result;
}

- (CSMVideoCanvas *)csm_createCanvasOfUid:(uint64_t)uid atIndex:(uint64_t)index totalCount:(NSUInteger)totalCount curCanvas:(CSMVideoCanvas *)curCanvas {
    CGRect frame = [self frameOfUserAtIndex:index totalMicUsersCount:totalCount];
    if (curCanvas) {
        curCanvas.uid = uid;
        curCanvas.view.frame = frame;
        return curCanvas;
    } else {
        UIControl *view = [[UIControl alloc] initWithFrame:frame];
        [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toastIsInMultiViewRenderMode)]];
        CSMVideoCanvas *canvas = [[CSMVideoCanvas alloc] init];
        canvas.uid = uid;
        canvas.view = view;
        [self.view addSubview:view];
        [self.view sendSubviewToBack:view];
        return canvas;
    }
}

- (void)updateRenderView {
    MainThreadBegin
    //更新视频布局
    NSArray<CSMChannelMicUser *> *sortedMicUsers = [self.micUsers.allValues sortedArrayUsingComparator:^NSComparisonResult(CSMChannelMicUser * obj1, CSMChannelMicUser *obj2) {
        return [@(obj1.uid) compare:@(obj2.uid)];
    }];
    NSUInteger micUserCount = sortedMicUsers.count;

    if (TestArg.multiViewRenderMode) {
        [sortedMicUsers enumerateObjectsUsingBlock:^(CSMChannelMicUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.uid == self.myUid) {
                self.previewCanvas = [self csm_createCanvasOfUid:obj.uid atIndex:idx totalCount:micUserCount curCanvas:self.previewCanvas];
                [self.mediaEngine setupLocalVideo:self.previewCanvas];
            } else {
                CSMVideoCanvas *canvas = self.remoteCanvas[@(obj.uid)];
                canvas = [self csm_createCanvasOfUid:obj.uid atIndex:idx totalCount:micUserCount curCanvas:canvas];
                [self.mediaEngine setupRemoteVideo:canvas];
                self.remoteCanvas[@(obj.uid)] = canvas;
            }
        }];
        if (sortedMicUsers.count <= 3) {
            //大窗放在最底下
            for (CSMChannelMicUser *micUser in [sortedMicUsers reverseObjectEnumerator]) {
                UIView *view;
                if (micUser.uid == self.myUid) {
                    view = self.previewCanvas.view;
                } else {
                    view = self.remoteCanvas[@(micUser.uid)].view;
                }
                if (view) {
                    [self.view sendSubviewToBack:view];
                }
            }
        }
    } else {
        NSMutableArray<CSMVideoRenderer *> *renderers = [NSMutableArray array];
        [sortedMicUsers enumerateObjectsUsingBlock:^(CSMChannelMicUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CSMVideoRenderer *videoRenderer = [[CSMVideoRenderer alloc] init];
            videoRenderer.uid = obj.uid;
            videoRenderer.seatNum = obj.seatNum;
            videoRenderer.renderFrame = [self frameOfUserAtIndex:idx totalMicUsersCount:micUserCount];
            [renderers addObject:videoRenderer];
        }];
        
        [self.mediaEngine setVideoRenderers:renderers];
    }
        
    if (self.clientRole == CSMClientRoleBroadcaster) {
        //自己在大窗或小窗时，指定不同的分辨率
        if (sortedMicUsers.count > 0 && self.myUid == sortedMicUsers.firstObject.uid) {
            [self.mediaEngine setAllVideoMaxEncodeParamsWithMaxResolution:CSMResolutionType1280x720 maxFrameRate:CSMFrameRate24];
        } else {
            [self.mediaEngine setAllVideoMaxEncodeParamsWithMaxResolution:CSMResolutionType480x270 maxFrameRate:CSMFrameRate24];
        }
    }
    
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine reportStatWithType:(CSMStatReportType)type statDict:(NSDictionary<NSString *, NSString *> *)statDict {
    NSLog(@"reportStatWithType:%d statDict:%@", type, statDict);
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine reportLbsUriResult:(int)uri cost:(int)cost success:(BOOL)success {
    NSLog(@"reportLbsUriResultWithUri:%d cost:%d success:%@", uri, cost, @(success));
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine kicked:(CSMKickReason)reason {
    MainThreadBegin
    [self leaveRoom];
    [CSInfoAlert showInfo:[NSString stringWithFormat:@"you are kicked:%d", reason]];
    [self.navigationController popViewControllerAnimated:YES];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine rtmpStreamingChangedToState:(NSString *)url state:(CSMRtmpStreamingState)state errorCode:(CSMRtmpStreamingErrorCode)errorCode {
    MainThreadBegin
    switch (state) {
        case CSMRtmpStreamingStateIdle: {
            [CSInfoAlert showInfo:[NSString stringWithFormat:@"已删除旁路推流url:%@", url]];
            if (url.length > 0) {
                [self.rtmpUrls removeObject:url];
            }
            break;
        }
        case CSMRtmpStreamingStateConnecting: {
            [CSInfoAlert showInfo:[NSString stringWithFormat:@"正在连接旁路推流url:%@", url]];
            if (url.length > 0) {
                [self.rtmpUrls addObject:url];
            }
            break;
            break;
        }
        case CSMRtmpStreamingStateRunning: {
            [CSInfoAlert showInfo:[NSString stringWithFormat:@"正在推流到url:%@", url]];
            if (url.length > 0) {
                [self.rtmpUrls addObject:url];
            }
            break;
        }
        case CSMRtmpStreamingStateFailure: {
            if (url.length > 0) {
                [self.rtmpUrls removeObject:url];
            }
            switch (errorCode) {
                case CSMRtmpStreamingErrorCodeOK: {
                    break;
                }
                case CSMRtmpStreamingErrorCodeInvalidParameters: {
                    [CSInfoAlert showInfo:@"rtmp链接格式无效"];
                    break;
                }
                case CSMRtmpStreamingErrorCodeInternalServerError: {
                    [CSInfoAlert showInfo:@"旁路推流失败：服务器内部错误"];
                    break;
                }
                case CSMRtmpStreamingErrorCodeStreamNotExist: {
                    [CSInfoAlert showInfo:@"rtmp链接不存在"];
                    break;
                }
                case CSMRtmpStreamingErrorCodeConnectRtmpFail: {
                    [CSInfoAlert showInfo:@"rtmp连接失败"];
                    break;
                }
                    
                case CSMRtmpStreamingErrorCodeRtmpTimeout: {
                    [CSInfoAlert showInfo:@"rtmp收包超时"];
                    break;
                }
                case CSMRtmpStreamingErrorCodeOccupiedByOtherChannel: {
                    [CSInfoAlert showInfo:@"该rtmp链接已被其它频道使用"];
                    break;
                }
            }
            break;
        }
    }
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine someBodyJoinedChannelWithUid:(uint64_t)uid role:(CSMClientRole)role {
    MainThreadBegin
    [CSInfoAlert showInfo:[NSString stringWithFormat:@"有%@进房:%llu", role == CSMClientRoleBroadcaster ? @"主播" : @"观众", uid] inView:self.view vertical:0.7];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine usingCallMode:(BOOL)usingCallMode {
    MainThreadBegin
    NSString *info;
    if (usingCallMode) {
        info = @"已切换为跟随系统通话音量";
    } else {
        info = @"已切换为跟随系统媒体音量";
    }
    [CSInfoAlert showInfo:info inView:self.view vertical:0.7];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine tokenPrivilegeWillExpire:(NSString *)token {
    //注意：仅用于demo调用，正式环境中，需要在接入方后台服务器部署Token 生成器生成 Token
    [self.tokenManager getTokenWithUid:self.myUid channelName:self.channelName userAccount:self.username completion:^(BOOL success, NSString * _Nonnull token) {
        MainThreadBegin
        if (success && token) {
            [CSInfoAlert showInfo:@"更新Token成功"];
            [[CStoreMediaEngineCore sharedSingleton] renewToken:token];
        } else {
            [CSInfoAlert showInfo:@"更新Token失败"];
        }
        MainThreadCommit
    }];
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine tokenPrivilegeExpired:(NSString *)token {
    MainThreadBegin
    //注意：仅用于demo调用，正式环境中，需要在接入方后台服务器部署Token 生成器生成 Token
    __weak typeof(self) weakSelf = self;
    [self.tokenManager getTokenWithUid:self.myUid channelName:self.channelName userAccount:self.username completion:^(BOOL success, NSString * _Nonnull token) {
        MainThreadBegin
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        
        if (success && token) {
            [self.mediaEngine setClientRole:self.clientRole];
            if (!TestArg.multiViewRenderMode) { //多View绘制
                [self.mediaEngine attachRendererView:self.videoView];
            }
            [self joinChannelWithCompletion:nil];
        } else {
            [CSInfoAlert showInfo:@"更新Token失败，已退出房间"];
            [self.navigationController popViewControllerAnimated:YES];
        }
        MainThreadCommit
    }];
    
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine didOccurError:(int32_t)errorCode {
    MainThreadBegin
    if (errorCode == CSMErrorCheckTokenFailed) {
        [CSInfoAlert showInfo:@"检查token有效性失败"];
    }
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine onRecvMediaSideInfo:(NSString *)info withSenderUid:(uint64_t)senderUid {
    MainThreadBegin
    [CSInfoAlert showInfo:[NSString stringWithFormat:@"%llu sei:%@", senderUid, info]];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore * _Nonnull)mediaEngine onCaptureVideoFrame:(unsigned char *_Nonnull) data frameType:(int) frameType width:(int) width height:(int) height bufferLength:(int) bufferLength rotation:(int) rotation renderTimeMs:(uint64_t) renderTimeMs{
    //TODO:处理采集回调的原始数据
    if(data != nil)
    {
        NSLog(@"图片格式 === %ld", frameType);

        NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};
        CVPixelBufferRef pixelBuffer = NULL;
        CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)(pixelAttributes),  &pixelBuffer);

        if (result != kCVReturnSuccess)
        {
            NSLog(@"Unable to create cvpixelbuffer %d", result);
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, 0);

        int yStride = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        int uvStride = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
//        int vStride = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);

        size_t w = CVPixelBufferGetWidth(pixelBuffer);
        size_t h = CVPixelBufferGetHeight(pixelBuffer);

//        const long len = yStride * height;
        unsigned char *yData = data;
        unsigned char *uData = &yData[yStride * h];
//        unsigned char *vData = &yData[yStride * h + uStride];

        unsigned char *yDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        unsigned char *uDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//        unsigned char *vDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
//
//
        for (int i = 0; i < height; i ++) {

            unsigned char *yDest = yDestPlane + i *yStride;
            unsigned char *src = data + i * width;
            memcpy(yDest, src, width);
        }

        for (int i = 0; i < height / 2; i++)
        {
            unsigned char *uDest = uDestPlane + i *uvStride;
            unsigned char *src = uData + i *uvStride / 4;
            memcpy(uDest, src, width);
        }
//
////        for (int i = 0, k = 0; i < height / 2; i ++) {
////            for (int j = 0; j < width / 2; j ++) {
////                uvDestPlane[k] = uData[j + i * uStride];
////                uvDestPlane[k] = vData[j + i * vStride];
////                k++;
////            }
////        }
//
//
//
    }
}

void releasePlanarBytesCallback(void *releaseRefCon, const void *dataPtr, size_t dataSize, size_t numberOfPlanes, const void * _Nullable *planeAddresses)
{
//   free(dataPtr);
//    NSLog(@"输入值 == %p", dataPtr);
}

- (void)onStartCustomCaptureVideoWithMediaEngine:(CStoreMediaEngineCore *)mediaEngine {
    if (self.customCapture) {
        [self.captureDevice startCapture];
    }
}

- (void)onStopCustomCaptureVideoWithMediaEngine:(CStoreMediaEngineCore *)mediaEngine {
    if (self.customCapture) {
        [self.captureDevice stopCapture];
    }
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine shouldChangeCustomCaptureResolutionToWidth:(int)width height:(int)height {
    [self.captureDevice changeCaptureResolutionToWidth:width height:height];
}

- (void)mediaEngineTranscodingUpdated:(CStoreMediaEngineCore *_Nonnull)mediaEngine {
    MainThreadBegin
    [CSInfoAlert showInfo:@"合流参数已更新" vertical:0.8];
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine localVideoStats:(CSMLocalVideoStats *)stats {
    MainThreadBegin
    self.localVideoStas = stats;
    MainThreadCommit
}

- (void)mediaEngine:(CStoreMediaEngineCore *)mediaEngine localAudioStats:(CSMLocalAudioStats *)stats {
    MainThreadBegin
    self.localAudioStats = stats;
    MainThreadCommit
}

#pragma mark - CSCaptureDeviceDataOutputPixelBufferDelegate
- (void)captureDevice:(CSCaptureDeviceCamera *)device didCapturedData:(CMSampleBufferRef)data {
    if (![TuSDKManager sharedManager].isInitFilterPipeline)
    {
        CVPixelBufferRef ref = CMSampleBufferGetImageBuffer(data);
        [self.mediaEngine sendCustomVideoCapturePixelBuffer:ref];
    }
    else
    {

        CVPixelBufferRef cameraFrame = CMSampleBufferGetImageBuffer(data);

        CVPixelBufferRef newPixelBuffer = [[TuSDKManager sharedManager] syncProcessSampleBuffer:data];

//        [[TuSDKManager sharedManager].filterProcessor destroyFrameData];

        [self.mediaEngine sendCustomVideoCapturePixelBuffer:newPixelBuffer];
        CFRelease(newPixelBuffer);
    }
}

#pragma mark - CSMusicViewControllerDelegate
- (void)didTapBgOfMusicViewController:(CSMusicViewController *)controller {
    [self.musicViewController.view removeFromSuperview];
}

#pragma mark - Getter && Setter
- (NSMutableDictionary *)micUsers {
    if (!_micUsers) {
        _micUsers = [NSMutableDictionary dictionary];
    }
    return _micUsers;
}

- (void)setIsUseCallMode:(BOOL)isUseCallMode {
    _isUseCallMode = isUseCallMode;
    [_mediaEngine setIsUseCallMode:isUseCallMode];
    self.setIsCallModeBtn.selected  = isUseCallMode;
}

- (CSCaptureDeviceCamera *)captureDevice {
    if (!_captureDevice) {
        _captureDevice = [[CSCaptureDeviceCamera alloc] initWithPixelFormatType:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];

        _captureDevice.delegate = self;
    }
    return _captureDevice;
}

- (BOOL)customCapture {
    return TestArg.customVideoCapture;
}

#pragma mark - Private
- (void)cs_hideBottomFunAreas:(BOOL)hide {
    for (UIView *v in self.bottomFunEreas) {
        v.alpha = (hide ? 0 : 1);
    }
}

#pragma mark -- 初始化TuSDK的UI
- (void)initTuSDKUI;
{
    [[TuSDKManager sharedManager] configTuSDKViewWithSuperView:self.view];
}

@end
