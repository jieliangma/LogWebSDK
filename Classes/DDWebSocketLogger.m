#import "DDWebSocketLogger.h"
#import "LLWDefaultLogFormatter.h"
#import "LogWebServer.h"

@implementation DDWebSocketLogger

+ (instancetype)sharedInstance {
    static DDWebSocketLogger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DDWebSocketLogger alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _enabled = YES;
        self.logFormatter = [[LLWDefaultLogFormatter alloc] init];
    }
    return self;
}

#pragma mark - DDLogger

- (void)logMessage:(DDLogMessage *)logMessage {
    if (!self.enabled) return;

    LLWLogWebServer *server = [LLWLogWebServer sharedInstance];
    if (!server.isRunning) return;

    LLWLogLevel level  = [self llw_convertFlag:logMessage.flag];
    NSString *message  = [_logFormatter formatLogMessage:logMessage];

    LLWLogEntry *entry = [[LLWLogEntry alloc] initWithLevel:level
                                                    message:message];
    [server pushLogToClients:entry];
}

#pragma mark - Private

- (LLWLogLevel)llw_convertFlag:(DDLogFlag)flag {
    if (flag & DDLogFlagError)   return LLWLogLevelError;
    if (flag & DDLogFlagWarning) return LLWLogLevelWarning;
    if (flag & DDLogFlagInfo)    return LLWLogLevelInfo;
    if (flag & DDLogFlagDebug)   return LLWLogLevelDebug;
    return LLWLogLevelVerbose;
}

@end
