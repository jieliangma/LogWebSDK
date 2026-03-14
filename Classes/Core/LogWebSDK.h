//
//  LogWebSDK.h
//  LogWebSDK
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
#if __has_include(<NSLogger/NSLogger.h>)
    #import "LLWNSLogger.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/// iOS 日志收集 SDK
@interface LogWebSDK : NSObject

/// SDK 版本号
@property (class, nonatomic, copy, readonly) NSString *version;

/// 是否已启动
@property (class, nonatomic, assign, readonly, getter=isStarted) BOOL started;

/// 启动 SDK（默认端口 8080）
+ (BOOL)start;

/// 启动 SDK
+ (BOOL)startWithPort:(NSInteger)port;

/// 停止 SDK
+ (void)stop;

/// 获取当前配置信息
+ (NSDictionary *)configuration;

@end

NS_ASSUME_NONNULL_END
