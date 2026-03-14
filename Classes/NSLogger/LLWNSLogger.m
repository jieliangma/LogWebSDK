//
//  LLWNSLogger.m
//  LogWebSDK
//

#import "LLWNSLogger.h"
#import <NSLogger/LoggerClient.h>

static NSString *LLWDeviceName(void) {
    NSString *hostName = [NSProcessInfo processInfo].hostName;
    return [hostName hasSuffix:@".local"]
        ? [hostName substringToIndex:hostName.length - 6]
        : hostName;
}

@implementation LLWNSLogger {
    Logger *_logger;
}

+ (void)load {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:@"LLWLogWebSDKDidStart"
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
        [DDLog addLogger:[LLWNSLogger new]];
    }];
}

- (instancetype)init {
    if (self = [super init]) {
        _logger = LoggerInit();
        LoggerSetupBonjour(_logger, NULL, (__bridge CFStringRef)LLWDeviceName());
        LoggerSetOptions(_logger,
            kLoggerOption_BrowseBonjour | kLoggerOption_BrowseOnlyLocalDomain);
    }
    return self;
}

- (void)didAddLogger {
    NSLog(@"┌──────────────────────────────────────┐\n"
          @"│      📱 LogWebSDK - NSLogger         │\n"
          @"  查找 Bonjour 服务名: %s\n"
          @"└──────────────────────────────────────┘",
          LLWDeviceName().UTF8String);

    LoggerStart(_logger);
}

- (void)flush {
    LoggerFlush(_logger, NO);
}

- (void)logMessage:(DDLogMessage *)logMessage {
    // __builtin_ctz(unsigned int) Count Trailing Zeros，数二进制末尾有多少个连续的 0。
    int level = __builtin_ctz((unsigned int)logMessage.flag);
    NSString *tag = logMessage.tag;
    if (![tag isKindOfClass:NSString.class]) {
        tag = [logMessage.fileName lastPathComponent].stringByDeletingPathExtension;
    }
    LogMessageRawToF(
        _logger,
        logMessage.file.UTF8String,
        (int)logMessage.line,
        logMessage.function.UTF8String,
        tag,
        level,
        logMessage.message
    );
}

- (void)dealloc {
    LoggerStop(_logger);
}

@end
