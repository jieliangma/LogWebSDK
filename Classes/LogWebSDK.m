//
//  LogWebSDK.m
//  LogWebSDK
//

#import "LogWebSDK.h"
#import <objc/runtime.h>

// 检查 CocoaLumberjack 是否可用
#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
    #define HAS_COCOA_LUMBERJACK 1
    #import <CocoaLumberjack/CocoaLumberjack.h>
#else
    #define HAS_COCOA_LUMBERJACK 0
#endif

#define LOGWEB_VERSION @"1.0.0"

@interface LogWebSDK ()

@end

// 静态变量存储类属性
static BOOL _started = NO;
static NSInteger _currentPort = 8080;

@implementation LogWebSDK

+ (NSString *)version {
    return LOGWEB_VERSION;
}

+ (BOOL)isStarted {
    return _started;
}

+ (void)setStarted:(BOOL)value {
    _started = value;
}

+ (NSInteger)currentPort {
    return _currentPort;
}

+ (void)setCurrentPort:(NSInteger)port {
    _currentPort = port;
}

#pragma mark - Public Methods

+ (BOOL)start {
    return [self startWithPort:8080];
}

+ (BOOL)startWithPort:(NSInteger)port {
    if ([self isStarted]) {
        NSLog(@"[LogWebSDK] SDK already started");
        return YES;
    }
    
    // 1. 启动 Web 服务器
    NSError *webError = nil;
    BOOL webSuccess = [[LLWLogWebServer sharedInstance] startWithPort:port error:&webError];
    if (!webSuccess) {
        NSLog(@"[LogWebSDK] Failed to start web server: %@", webError);
        return NO;
    }
    
    // 2. 发布 Bonjour 服务
    NSError *bonjourError = nil;
    BOOL bonjourSuccess = [[LLWLogBroadcastService sharedInstance] publishWithPort:port error:&bonjourError];
    if (!bonjourSuccess) {
        NSLog(@"[LogWebSDK] Failed to publish Bonjour service: %@", bonjourError);
    }
    
    // 3. 注册 CocoaLumberjack Logger
    [self registerCocoaLumberjackLogger];
    
    self.started = YES;
    self.currentPort = port;
    
    NSLog(@"[LogWebSDK] 🌐 Web Server: http://localhost:%ld", (long)port);
    NSLog(@"[LogWebSDK] 🔍 Bonjour Service: %@.%s:%ld", 
          [[LLWLogBroadcastService sharedInstance] serviceName],
          [[LLWLogBroadcastService sharedInstance] serviceType].UTF8String,
          (long)port);
    
    return YES;
}

+ (void)stop {
    if (![self isStarted]) {
        return;
    }
    
    NSLog(@"[LogWebSDK] Stopping LogWebSDK...");
    
    // 1. 移除 Logger
    [self unregisterCocoaLumberjackLogger];
    
    // 2. 停止 Web 服务器
    [[LLWLogWebServer sharedInstance] stop];
    
    // 3. 停止 Bonjour 服务
    [[LLWLogBroadcastService sharedInstance] stopPublishing];
    
    self.started = NO;
    
    NSLog(@"[LogWebSDK] ✅ LogWebSDK stopped");
}

+ (NSDictionary *)configuration {
    LLWLogBroadcastService *broadcast = [LLWLogBroadcastService sharedInstance];
    LLWLogWebServer *server = [LLWLogWebServer sharedInstance];
    
    return @{
        @"version": LOGWEB_VERSION,
        @"started": @([self isStarted]),
        @"port": @(self.currentPort),
        @"webServerRunning": @(server.isRunning),
        @"bonjourPublishing": @(broadcast.isPublishing),
        @"serviceName": broadcast.serviceName ?: @"",
        @"serviceType": broadcast.serviceType ?: @""
    };
}

#pragma mark - Private Methods

/// 注册 CocoaLumberjack Logger
+ (void)registerCocoaLumberjackLogger {
#if HAS_COCOA_LUMBERJACK
    // 获取 DDLog 类
    Class DDLogClass = NSClassFromString(@"DDLog");
    if (!DDLogClass) {
        NSLog(@"[LogWebSDK] ⚠️ CocoaLumberjack not found, skipping logger registration");
        return;
    }
    
    // 创建并添加 Logger
    DDWebSocketLogger *logger = [DDWebSocketLogger sharedInstance];
    
    // 使用 performSelector 避免编译错误
    if ([DDLogClass respondsToSelector:@selector(addLogger:)]) {
        [DDLogClass performSelector:@selector(addLogger:) withObject:logger];
    } else {
        NSLog(@"[LogWebSDK] ⚠️ DDLog addLogger method not found");
    }
#else
    NSLog(@"[LogWebSDK] ⚠️ CocoaLumberjack header not found, skipping logger registration");
#endif
}

/// 移除 CocoaLumberjack Logger
+ (void)unregisterCocoaLumberjackLogger {
#if HAS_COCOA_LUMBERJACK
    Class DDLogClass = NSClassFromString(@"DDLog");
    if (DDLogClass && [DDLogClass respondsToSelector:@selector(removeLogger:)]) {
        DDWebSocketLogger *logger = [DDWebSocketLogger sharedInstance];
        [DDLogClass performSelector:@selector(removeLogger:) withObject:logger];
        NSLog(@"[LogWebSDK] ✅ DDWebSocketLogger removed from CocoaLumberjack");
    }
#else
    NSLog(@"[LogWebSDK] ⚠️ CocoaLumberjack not available, nothing to unregister");
#endif
}

#pragma mark - Automatic Initialization

/// 自动初始化方法 - 在类加载时自动调用
+ (void)load {
#if TARGET_OS_IOS
    // 使用 dispatch_once 确保只初始化一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 延迟启动，等待应用完成基本初始化
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 检查是否在测试环境
            NSString *processName = [[NSProcessInfo processInfo] processName];
            if ([processName containsString:@"xctest"] || [processName containsString:@"Test"]) {
                NSLog(@"[LogWebSDK] Running in test mode, auto-start disabled");
                return;
            }
            
            NSLog(@"[LogWebSDK] 🚀 Auto-initializing LogWebSDK...");
            [self start];
        });
    });
#endif
}

@end
