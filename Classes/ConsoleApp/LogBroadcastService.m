#import "LogBroadcastService.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface LLWLogBroadcastService () <NSNetServiceDelegate>
@property (nonatomic, strong) NSNetService *netService;
@property (nonatomic, assign, readwrite, getter=isPublishing) BOOL publishing;
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
        _serviceName = [[UIDevice currentDevice].name
                        stringByReplacingOccurrencesOfString:@" " withString:@"-"];
#else
        _serviceName = [NSHost currentHost].name ?: @"Unknown";
#endif
        _serviceType = @"_ioslog._tcp";
        _port = 50001;
    }
    return self;
}

- (void)publishWithPort:(NSInteger)port {
    if (self.isPublishing) return;

    self.port = port;

    self.netService = [[NSNetService alloc] initWithDomain:@""
                                                      type:self.serviceType
                                                      name:self.serviceName
                                                      port:(int)port];
    self.netService.delegate = self;

    NSDictionary *txtRecord = @{
        @"version": @"1.0",
        @"path":    @"/",
        @"ws":      [NSString stringWithFormat:@"/ws"]
    };
    self.netService.TXTRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecord];
    [self.netService publish];
}

- (void)stopPublishing {
    if (!self.netService) return;
    [self.netService stop];
    self.netService.delegate = nil;
    self.netService = nil;
    _publishing = NO;
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidPublish:(NSNetService *)sender {
    _publishing = YES;
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    _publishing = NO;
    self.netService.delegate = nil;
    self.netService = nil;
#ifdef DEBUG
    NSLog(@"[LogWebSDK] Bonjour failed: %@", errorDict);
#endif
}

- (void)netServiceDidStop:(NSNetService *)sender {
    _publishing = NO;
    self.netService.delegate = nil;
    self.netService = nil;
}

@end
