//
//  DDWebSocketLogger.h
//  LogWebSDK
//
//  自定义 CocoaLumberjack Logger，用于收集日志到缓冲区
//

#import <Foundation/Foundation.h>

// 检查是否已导入 CocoaLumberjack
#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
    #import <CocoaLumberjack/CocoaLumberjack.h>
#else
    // 如果没有找到 CocoaLumberjack，提供编译错误提示
    #error "请确保已安装 CocoaLumberjack: pod 'CocoaLumberjack'"
#endif

#import "LogEntry.h"

NS_ASSUME_NONNULL_BEGIN

/// WebSocket Logger - 继承自 DDAbstractLogger
@interface DDWebSocketLogger : DDAbstractLogger <DDLogger>

/// 日志缓冲区单例
@property (class, nonatomic, strong, readonly) DDWebSocketLogger *sharedInstance;

/// 是否启用（默认 YES）
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

/// 启动 Logger
- (void)startLogging;

/// 停止 Logger
- (void)stopLogging;

@end

/// 默认日志格式化器
@interface DefaultLogFormatter : NSObject <DDLogFormatter>
@end

NS_ASSUME_NONNULL_END
