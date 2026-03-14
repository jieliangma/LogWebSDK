//
//  LogEntry.h
//  LogWebSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LLWLogLevel) {
    LLWLogLevelVerbose = 0,
    LLWLogLevelDebug   = 1,
    LLWLogLevelInfo    = 2,
    LLWLogLevelWarning = 3,
    LLWLogLevelError   = 4
};

@interface LLWLogEntry : NSObject

@property (nonatomic, assign, readonly) LLWLogLevel  level;
@property (nonatomic, copy,   readonly) NSString     *message;

- (instancetype)initWithLevel:(LLWLogLevel)level
                      message:(NSString *)message NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
