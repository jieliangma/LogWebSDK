//
//  LLWNSLogger.h
//  LogWebSDK
//

#import <CocoaLumberjack/CocoaLumberjack.h>

NS_ASSUME_NONNULL_BEGIN

/// NSLogger 适配器 - 将 CocoaLumberjack 日志转发到 NSLogger Viewer
@interface LLWNSLogger : DDAbstractLogger <DDLogger>

@end

NS_ASSUME_NONNULL_END
