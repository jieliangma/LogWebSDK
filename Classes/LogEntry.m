#import "LogEntry.h"

@implementation LLWLogEntry

- (instancetype)initWithLevel:(LLWLogLevel)level
                      message:(NSString *)message {
    if (self = [super init]) {
        _level     = level;
        _message   = [message copy];
    }
    return self;
}

@end
