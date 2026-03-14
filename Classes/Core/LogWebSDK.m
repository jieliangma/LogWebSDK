#import "LogWebSDK.h"

#define LOGWEB_VERSION @"1.0.0"

static BOOL      _started     = NO;
static NSInteger _currentPort = 8080;

@implementation LogWebSDK

+ (NSString *)version   { return LOGWEB_VERSION; }
+ (BOOL)isStarted       { return _started; }
+ (NSInteger)currentPort { return _currentPort; }

#pragma mark - Public

+ (BOOL)start {
    return [self startWithPort:8080];
}

+ (BOOL)startWithPort:(NSInteger)port {
    if (_started) return YES;

    NSError *webError = nil;
    if (![[LLWLogWebServer sharedInstance] startWithPort:port error:&webError]) {
#ifdef DEBUG
        NSLog(@"[LogWebSDK] Failed to start: %@", webError);
#endif
        return NO;
    }

    [DDLog addLogger:[DDWebSocketLogger sharedInstance]];

    _started     = YES;
    _currentPort = port;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LLWLogWebSDKDidStart"
                                                        object:@(port)];
    return YES;
}

+ (void)stop {
    if (!_started) return;
    [DDLog removeLogger:[DDWebSocketLogger sharedInstance]];
    [[LLWLogWebServer sharedInstance] stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LLWLogWebSDKDidStop" object:nil];
    _started = NO;
}

+ (NSDictionary *)configuration {
    return @{
        @"version": LOGWEB_VERSION,
        @"started": @(_started),
        @"port":    @(_currentPort),
        @"webServerRunning": @([LLWLogWebServer sharedInstance].isRunning),
    };
}

#pragma mark - Auto-start

+ (void)load {
#if TARGET_OS_IOS
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
            if ([self llw_isTestEnvironment]) return;

            id val = [[NSBundle mainBundle] infoDictionary][@"LogWebSDKAutoStart"];
            if (val != nil && ![val boolValue]) return;

            [self start];
        }];
    });
#endif
}

+ (BOOL)llw_isTestEnvironment {
    return (NSClassFromString(@"XCTestCase") != nil)
        || ([NSProcessInfo processInfo].environment[@"XCTestConfigurationFilePath"] != nil);
}

@end

