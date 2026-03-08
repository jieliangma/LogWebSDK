//
//  LogWebSDK.h
//  LogWebSDK
//
//  iOS 日志收集 SDK - 主入口
//  零配置集成 CocoaLumberjack 日志查看器
//

#import <Foundation/Foundation.h>

//! Project version number for LogWebSDK.
FOUNDATION_EXPORT double LogWebSDKVersionNumber;

//! Project version string for LogWebSDK.
FOUNDATION_EXPORT const unsigned char LogWebSDKVersionString[];

// 公共头文件
#import "LogEntry.h"
#import "DDWebSocketLogger.h"
#import "LogWebServer.h"
#import "LogBroadcastService.h"

NS_ASSUME_NONNULL_BEGIN

/// LogWebSDK - 主入口类
@interface LogWebSDK : NSObject

/// SDK 版本号
@property (class, nonatomic, copy, readonly) NSString *version;

/// 是否已启动
@property (class, nonatomic, assign, readonly, getter=isStarted) BOOL started;

/// 启动 SDK（默认端口 8080）
/// @returns 是否成功
+ (BOOL)start;

/// 启动 SDK
/// @param port Web 服务器端口
/// @returns 是否成功
+ (BOOL)startWithPort:(NSInteger)port;

/// 停止 SDK
+ (void)stop;

/// 获取当前配置信息
/// @returns 配置字典
+ (NSDictionary *)configuration;

@end

NS_ASSUME_NONNULL_END
