//
//  LogBroadcastService.m
//  LogWebSDK
//

#import "LogBroadcastService.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface LLWLogBroadcastService () <NSNetServiceDelegate>

@property (nonatomic, strong) NSNetService *netService;
@property (nonatomic, assign) BOOL isPublishing;

@end

@implementation LLWLogBroadcastService

+ (instancetype)sharedInstance {
    static LLWLogBroadcastService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LLWLogBroadcastService alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
#if TARGET_OS_IOS
        // 使用设备名作为服务名称
        _serviceName = [[[UIDevice currentDevice] name] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
#else
        _serviceName = [[NSHost currentHost] name] ?: @"Unknown";
#endif
        _serviceType = @"_ioslog._tcp";
        _port = 8080;
    }
    return self;
}

- (BOOL)publishWithPort:(NSInteger)port error:(NSError **)error {
    if (self.isPublishing) {
        NSLog(@"[LogWebSDK] Bonjour service already publishing");
        return YES;
    }
    
    self.port = port;
    
    // 创建 NetService
    self.netService = [[NSNetService alloc] initWithDomain:@""
                                                     type:self.serviceType
                                                     name:self.serviceName
                                                     port:(int)port];
    self.netService.delegate = self;
    
    // 添加 TXT 记录，提供额外信息
    NSDictionary *txtRecord = @{
        @"version" : @"1.0",
        @"path" : @"/",
#if TARGET_OS_IOS
        @"device" : [[[UIDevice currentDevice] name] stringByReplacingOccurrencesOfString:@" " withString:@"-"]
#else
        @"device" : [[NSHost currentHost] name] ?: @"Unknown"
#endif
    };
    self.netService.TXTRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecord];
    
    // 发布服务
    [self.netService publish];
    
    NSLog(@"[LogWebSDK] Publishing Bonjour service: %@.%s:%ld", self.serviceName, self.serviceType.UTF8String, (long)port);
    
    return YES;
}

- (void)stopPublishing {
    if (!self.isPublishing || !self.netService) {
        return;
    }
    
    [self.netService stop];
    self.netService.delegate = nil;
    self.netService = nil;
    
    _isPublishing = NO;
    
    NSLog(@"[LogWebSDK] Bonjour service stopped");
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidPublish:(NSNetService *)sender {
    _isPublishing = YES;
    NSLog(@"[LogWebSDK] Bonjour service published successfully: %@", sender.name);
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    _isPublishing = NO;
    NSLog(@"[LogWebSDK] Bonjour service failed to publish: %@", errorDict);
}

- (void)netServiceDidStop:(NSNetService *)sender {
    _isPublishing = NO;
    NSLog(@"[LogWebSDK] Bonjour service stopped");
}

@end
