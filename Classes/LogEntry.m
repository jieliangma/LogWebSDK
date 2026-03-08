//
//  LogEntry.m
//  LogWebSDK
//

#import "LogEntry.h"

@implementation LLWLogEntry

- (instancetype)initWithLevel:(LLWLogLevel)level message:(NSString *)message tag:(nullable NSString *)tag {
    if (self = [super init]) {
        _level = level;
        _message = [message copy];
        _timestamp = [NSDate date];
        _tag = [tag copy];
    }
    return self;
}

@end
