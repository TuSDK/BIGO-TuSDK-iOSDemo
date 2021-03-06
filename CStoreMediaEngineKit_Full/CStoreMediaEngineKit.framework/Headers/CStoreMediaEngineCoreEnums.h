//
//  CStoreMediaEngineCoreEnums.h
//  CStoreEngineKit
//
//  Created by Caimu Yang on 2019/8/20.
//  Copyright © 2019 BIGO Inc. All rights reserved.
//

#ifndef CStoreMediaEngineCoreEnums_h
#define CStoreMediaEngineCoreEnums_h
/**
 音频属性
 */
typedef NS_ENUM(NSInteger, BigoAudioProfile ) {
/**
 0: 默认设置。
通信场景下：32 KHz 采样率，语音编码，单声道，编码码率最大值为 18 Kbps。
直播场景下：48 KHz 采样率，音乐编码，单声道，编码码率最大值为 64 Kbps。
 */
   BigoAudioProfileDefault = 0,
/**
 指定 32 KHz采样率，语音编码，单声道，编码码率最大值为 18 Kbps
*/
   BigoAudioProfileSpeechStandard = 1,
/**
 指定 48 KHz采样率，音乐编码，单声道，编码码率最大值为 64 Kbps
*/
   BigoAudioProfileMusicStandard = 2,
/**
 指定 48 KHz采样率，音乐编码，双声道，编码码率最大值为 80 Kbps
*/
   BigoAudioProfileMusicStandardStereo = 3,
/**
 指定 48 KHz 采样率，音乐编码，单声道，编码码率最大值为 96 Kbps
*/
   BigoAudioProfileMusicHighQuality = 4,
/**
 指定 48 KHz采样率，音乐编码，双声道，编码码率最大值为 128 Kbps
*/
   BigoAudioProfileMusicHighQualityStereo = 5,
/**
 可变
*/
   BigoAudioProfileSettable = 6,
};
/**
 音频应用场景
*/
typedef NS_ENUM(NSInteger, BigoAudioScenario ) {
/**
 0: 默认设置;通信时使用通话音量；直播时观众使用媒体音量，连麦后使用通话音量
 */
   BigoAudioScenarioDefault = 0,
/**
 1: 娱乐应用，需要频繁上下麦的场景;通信时使用通话音量；直播时无论观众还是主播也都使用通话音量*
 */
   BigoAudioScenarioChatRoomEntertainment = 1,
/**
 2: 教育应用，流畅度和稳定性优先;通信时使用通话音量；直播时观众使用媒体音量，连麦后使用通话音量
 */
   BigoAudioScenarioEducation = 2,
/**
 3: 高音质语聊房应用;通信时使用媒体音量；直播时无论观众还是主播也都使用媒体音量
 */
   BigoAudioScenarioGameStreaming = 3,
/**
 4: 秀场应用，音质优先和更好的专业外设支持;通信时使用通话音量；直播时观众使用媒体音量，连麦后使用通话音量
 */
   BigoAudioScenarioShowRoom = 4,
/**
 5: 游戏开黑;通信时使用通话音量；直播时无论观众还是主播也都使用通话音量
 */
   BigoAudioScenarioChatRoomGaming = 5,
/**
 6: 该场景下可用不做强制限制
 */
   BigoAudioScenarioSettable = 6,
};
/**
 镜像模式
 */
typedef NS_ENUM(int, CSMVideoMirrorMode) {
    /**
     自动
     */
    CSMVideoMirrorModeAuto      = 0,
    /**
     打开
     */
    CSMVideoMirrorModeEnable    = 1,
    /**
     关闭
     */
    CSMVideoMirrorModeDisable   = 2
};

/**
 媒体连接状态
 */
typedef NS_ENUM(int, CSMConnectionStateType) {
    /**
     已断开
     */
    CSMConnectionStateTypeDisconnected  = 1,
    /**
     连接中
     */
    CSMConnectionStateTypeConnecting    = 2,
    /**
     已连接
     */
    CSMConnectionStateTypeConnected     = 3,
    /**
     重连中
     */
    CSMConnectionStateTypeReconnecting  = 4,
    /**
     连接失败
     */
    CSMConnectionStateTypeFailed        = 5,
};

/**
 网络类型
 */
typedef NS_ENUM(int, CSMNetworkType) {
    /**
     未知
     */
    CSMNetworkTypeUnknown     = 0,
    /**
     网络不可用
     */
    CSMNetworkTypeUnavailable = 1,
    /**
     WiFi
     */
    CSMNetworkTypeWIFI        = 2,
    /**
     2G网络
     */
    CSMNetworkType2G          = 3,
    /**
     3G网络
     */
    CSMNetworkType3G          = 4,
    /**
     4G网络
     */
    CSMNetworkType4G          = 5,
};

/**
 用户角色
 */
typedef NS_ENUM(int, CSMClientRole) {
    /**
     主播
     */
    CSMClientRoleBroadcaster = 1,
    /**
     观众
     */
    CSMClientRoleAudience    = 2,
};

/**
 错误码
 */
typedef NS_ENUM(int, CSMErrorCode) {
    /**
     未知
     */
    CSMErrorNone                = 0,
    /**
     超时
     */
    CSMErrorTimeout             = -1,
    /**
     协议失败
     */
    CSMErrorProtoFaile          = -2,
    /**
     无效的房间，可能没开播
     */
    CSMErrorRoomInvalid         = -3,
    /**
     无效的房间操作
     */
    CSMErrorRoomOperate         = -4,
    /**
     在黑名单中
     */
    CSMErrorInBlacklist         = -5,
    /**
     私密房不在白名单
     */
    CSMErrorNotInWhitelist      = -6,
    /**
     主播block了该用户（过了blocktime可以重新进入）
     */
    CSMErrorBlockedByHost       = -7,
    /**
     切私人房没有带白名单列表
     */
    CSMErrorNoWhitelist         = -8,
    /**
     房主将自己从白名单内移除
     */
    CSMErrorRemoveSelf          = -9,
    /**
     已经在频道中
     */
    CSMErrorAlreadyInChannel    = -10,
    /**
     频道状态无效
     */
    CSMErrorChannelStateInvalid = -11,
    /**
     Token无效
     */
    CSMErrorTokenInvalid        = -12,
    /**
     更新token时传入的token跟原来的token一样
     */
    CSMErrorSameToken           = -13,
    /**
     regetMS超时
     */
    CSMErrorNoMsGroup           = -15,
    
    /**
     检查token有效性失败
     */
    CSMErrorCheckTokenFailed = -16,
};

/**
 踢出原因
 */
typedef NS_ENUM(int, CSMKickReason) {
    /**
     被主播踢出
     */
    CSMKickReasonBroadcast        = -1,
    /**
     因房间变为私密房被踢出
     */
    CSMKickReasonRoomPrivated     = -2,
    /**
     因被加入黑名单被踢出
     */
    CSMKickReasonBlackList        = -3,
    /**
     主播踢出频道所有人
     */
    CSMKickReasonBroadcastKickAll = -4,
};

/**
 统计类型
 */
typedef NS_ENUM(int, CSMStatReportType) {
    /**
     lbs相关统计
     */
    CSMStatReportTypeLbs                = 1,
    /**
     频道相关统计
     */
    CSMStatReportTypeChannel            = 2,
    /**
     协议质量相关统计
     */
    CSMStatReportTypeLbsProtoQuality    = 3,
};

/**
 频道使用场景
 */
typedef NS_ENUM(int, CSMChannelProfile) {
    /**
     直播场景(默认)
     */
    CSMChannelProfileBroadcasting,
    /**
     通话场景
     */
    CSMChannelProfile1v1Call,
};

/**
 推流状态
 */
typedef NS_ENUM(NSUInteger, CSMRtmpStreamingState) {
    /**
     推流未开始或已结束。
     */
    CSMRtmpStreamingStateIdle,
    /**
     正在连接推流服务器和 RTMP 服务器。
     */
    CSMRtmpStreamingStateConnecting,
    /**
     推流正在进行。成功推流后，会返回该状态。
     */
    CSMRtmpStreamingStateRunning,
    /**
     推流失败。失败后，你可以通过返回的错误码排查错误原因，也可以再次调用 [CStoreMediaEngineCore addPublishStreamUrl:] 重新尝试推流。
     */
    CSMRtmpStreamingStateFailure,
};

/**
 推流错误信息
 */
typedef NS_ENUM(NSUInteger, CSMRtmpStreamingErrorCode) {
    /**
     推流成功
     */
    CSMRtmpStreamingErrorCodeOK,
    /**
     参数无效。请检查输入参数是否正确。
     */
    CSMRtmpStreamingErrorCodeInvalidParameters,
    /**
     服务器内部错误。
     */
    CSMRtmpStreamingErrorCodeInternalServerError,
    /**
     服务器未找到这个流。
     */
    CSMRtmpStreamingErrorCodeStreamNotExist,
    /**
     连接RTMP服务器失败
     */
    CSMRtmpStreamingErrorCodeConnectRtmpFail,
    /**
     与RTMP服务器的交互超时
     */
    CSMRtmpStreamingErrorCodeRtmpTimeout,
    /**
     RTMP url被其它频道占用。
     */
    CSMRtmpStreamingErrorCodeOccupiedByOtherChannel,
};

/**
 分辨率
 */
typedef NS_ENUM(NSUInteger, CSMResolutionType) {
    /**
     分辨率1280x720
     */
    CSMResolutionType1280x720 = 46,
    /**
     分辨率960x540
     */
    CSMResolutionType960x540 = 47,
    /**
     分辨率854x480
     */
    CSMResolutionType854x480 = 48,
    /**
     分辨率640x360
     */
    CSMResolutionType640x360 = 49,
    /**
     分辨率480x270
     */
    CSMResolutionType480x270 = 50,
};

/**
 视频播放帧率
 */
typedef NS_ENUM(NSUInteger, CSMFrameRate) {
    /**
     每秒钟 1 帧
     */
    CSMFrameRate1 = 1,
    /**
     每秒钟 7 帧
     */
    CSMFrameRate7 = 7,
    /**
     每秒钟 10 帧
     */
    CSMFrameRate10 = 10,
    /**
     每秒钟 15 帧
     */
    CSMFrameRate15 = 15,
    /**
     每秒钟 24 帧
     */
    CSMFrameRate24 = 24,
    /**
     每秒钟 30 帧
     */
    CSMFrameRate30 = 30,
};

/**
 音频文件播放错误码
 */
typedef NS_ENUM(NSInteger, BigoAudioMixingErrorCode) {
    /**
    701: 音乐文件打开出错
    */
   BigoAudioMixingErrorCanNotOpen = 701,
    /**
     702: 音乐文件打开太频繁
    */
   BigoAudioMixingErrorTooFrequentCall = 702,
    /**
     703: 音乐文件打开中断
    */
   BigoAudioMixingErrorInterruptedEOF = 703,
    /**
     704: 音乐文件已经播放到末尾
    */
   BigoAudioMixingPlayEndOfFile = 704,
    /**
     705: 主动停止播放音乐文件
    */
   BigoAudioMixingPlayActiveStop = 705,
    /**
     706: 音效文件数量已经达到最大值，请先关闭无用的soundid的文件
    */
   BigoAudioEffectFileNumFull = 706,
    /**
     0: 音乐文件状态正常
    */
   BigoAudioMixingErrorOK = 0,

};
/**
音频文件播放状态
 */
typedef NS_ENUM(NSInteger, BigoAudioMixingStateCode) {
   /**
    710: 音乐文件正常播放。
    成功调用 startAudioMixing/playEffect 播放音乐文件。
    成功调用 resumeAudioMixing/resumeEffect 恢复播放音乐文件。
   */
   BigoAudioMixingStatePlaying = 710,
    /**
     711: 音乐文件暂停播放。
     该状态表示 SDK 成功调用 [pauseAudioMixing/pauseEffect]
     */
   BigoAudioMixingStatePaused = 711,
    /**
     713: 音乐文件停止播放。
     该状态表示 SDK 成功调用 [stopAudioMixing]
     */
   BigoAudioMixingStateStopped = 713,
    /**
     714: 音乐文件播放失败。错误类型见 BigoAudioMixingErrorCode。
     */
   BigoAudioMixingStateFailed = 714,
    /**
     715: 音乐文件播放进度
     */
   BigoAudioMixingStateProgress = 715,

};

/**
视频帧格式
 */
typedef NS_ENUM(NSInteger, BigoPixelFormat) {
    /**
     0: yuv420p
    */
    I420 = 0,
    /**
     1: nv21
    */
    NV21 = 1,
    /**
     2:rgba24
    */
    RGBA = 2,
};

#endif /* CStoreMediaEngineCoreEnums_h */
