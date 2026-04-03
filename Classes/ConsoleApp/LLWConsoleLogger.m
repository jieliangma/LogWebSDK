#import "LLWConsoleLogger.h"
#import "LogBroadcastService.h"
#import <os/log.h>

@implementation LLWConsoleLogger {
    os_log_t _osLog;
}

+ (void)load {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:@"LLWLogWebSDKDidStart"
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
        NSInteger port = [note.object integerValue];
        [[LLWLogBroadcastService sharedInstance] publishWithPort:port];
        NSString *subsystem = NSBundle.mainBundle.bundleIdentifier ?: @"com.logwebsdk";
        [DDLog addLogger:[[LLWConsoleLogger alloc] initWithSubsystem:subsystem category:@"LogWebSDK"]];
    }];
    [[NSNotificationCenter defaultCenter]
        addObserverForName:@"LLWLogWebSDKDidStop"
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
        [[LLWLogBroadcastService sharedInstance] stopPublishing];
    }];
}

- (instancetype)initWithSubsystem:(NSString *)subsystem category:(NSString *)category {
    if (self = [super init]) {
        _osLog = os_log_create(subsystem.UTF8String, category.UTF8String);
    }
    return self;
}

- (void)logMessage:(DDLogMessage *)logMessage {
    os_log_type_t type;
    switch (logMessage.flag) {
        case DDLogFlagError:   type = OS_LOG_TYPE_ERROR;   break;
        case DDLogFlagWarning: type = OS_LOG_TYPE_ERROR;   break;
        default:               type = OS_LOG_TYPE_DEFAULT; break;
    }
    NSString *formatted = _logFormatter ? [_logFormatter formatLogMessage:logMessage] : logMessage.message;
    os_log_with_type(_osLog, type, "%{public}s", formatted.UTF8String);
}

@end
