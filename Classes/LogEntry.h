//
//  LogEntry.h
//  LogWebSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LLWLogLevel) {
    LLWLogLevelVerbose = 0,
    LLWLogLevelDebug = 1,
    LLWLogLevelInfo = 2,
    LLWLogLevelWarning = 3,
    LLWLogLevelError = 4
};

@interface LLWLogEntry : NSObject

@property (nonatomic, assign) LLWLogLevel level;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, copy, nullable) NSString *tag;

- (instancetype)initWithLevel:(LLWLogLevel)level message:(NSString *)message tag:(nullable NSString *)tag;

@end

NS_ASSUME_NONNULL_END
