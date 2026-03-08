//
//  LogBroadcastService.h
//  LogWebSDK
//
//  Bonjour 服务发现与广播
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Bonjour 服务 - 单例模式
@interface LLWLogBroadcastService : NSObject

@property (class, nonatomic, strong, readonly) LLWLogBroadcastService *sharedInstance;

/// 服务名称（默认使用设备名）
@property (nonatomic, copy) NSString *serviceName;

/// 服务类型（默认 _ioslog._tcp）
@property (nonatomic, copy) NSString *serviceType;

/// 服务端口
@property (nonatomic, assign) NSInteger port;

/// 是否正在发布服务
@property (nonatomic, assign, readonly, getter=isPublishing) BOOL publishing;

/// 发布服务
/// @param port 端口号
/// @param error 错误信息
- (BOOL)publishWithPort:(NSInteger)port error:(NSError **)error;

/// 停止发布服务
- (void)stopPublishing;

@end

NS_ASSUME_NONNULL_END
