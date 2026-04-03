#import "LLWNSLogger.h"
#import <NSLogger/LoggerClient.h>

static NSString *LLWBonjourName(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *key = @"NSLogger.Bonjour.Name";
    NSString *name = [defaults stringForKey:key];
    if ([name length] == 0) {
        uint32_t random = arc4random() % 10000;
        name = [[NSString alloc] initWithFormat:@"%04u", random];
        [defaults setValue:name forKey:key];
    }
    
    return name;
}

@implementation LLWNSLogger {
    Logger *_logger;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter]
            addObserverForName:@"LLWLogWebSDKDidStart"
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
            [DDLog addLogger:[LLWNSLogger new]];
        }];
    });
}

- (instancetype)init {
    if (self = [super init]) {
        self->_logger = LoggerInit();
        LoggerSetupBonjour(self->_logger, NULL, (__bridge CFStringRef)LLWBonjourName());
        LoggerSetOptions(self->_logger,
            kLoggerOption_BrowseBonjour | kLoggerOption_BrowseOnlyLocalDomain);
    }
    return self;
}

- (void)didAddLogger {
    [self start];
}

- (void)start {
    if (_logger == NULL) {
        return;
    }
    
    NSLog(@"┌─────────────────────────────────────────┐\n"
          @"│ Connecting NSLogger, bonjour name: %-5s│\n"
          @"└─────────────────────────────────────────┘",
          LLWBonjourName().UTF8String);

    LoggerStart(_logger);
}

- (void)flush {
    LoggerFlush(self->_logger, NO);
}

- (void)logMessage:(DDLogMessage *)logMessage {
    // __builtin_ctz(unsigned int) Count Trailing Zeros，数二进制末尾有多少个连续的 0。
    int level = __builtin_ctz((unsigned int)logMessage.flag);
    NSString *tag = logMessage.tag;
    if (![tag isKindOfClass:NSString.class]) {
        tag = [logMessage.fileName lastPathComponent].stringByDeletingPathExtension;
    }
    
    LogMessageRawToF(
        self->_logger,
        logMessage.file.UTF8String,
        (int)logMessage.line,
        logMessage.function.UTF8String,
        tag,
        level,
        logMessage.message
    );
}

- (void)dealloc {
    LoggerStop(_logger);
    _logger = NULL;
}

@end
