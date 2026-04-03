//
//  LogBroadcastService.h
//  LogWebSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLWLogBroadcastService : NSObject

@property (class, nonatomic, strong, readonly) LLWLogBroadcastService *sharedInstance;

@property (nonatomic, copy)   NSString  *serviceName;
@property (nonatomic, copy)   NSString  *serviceType;
@property (nonatomic, assign) NSInteger  port;

@property (nonatomic, assign, readonly, getter=isPublishing) BOOL publishing;

- (void)publishWithPort:(NSInteger)port;

- (void)stopPublishing;

@end

NS_ASSUME_NONNULL_END
