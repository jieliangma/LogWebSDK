#import "LLWDefaultLogFormatter.h"

@implementation LLWDefaultLogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    static NSDateFormatter *fmt;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        fmt = [NSDateFormatter new];
        fmt.dateFormat = @"MM-dd HH:mm:ss.SSS";
    });

    NSString *timestamp = [fmt stringFromDate:logMessage.timestamp];
    NSString *level = [self levelWithMessage:logMessage];
    NSString *extraInfo = [self extraInfoWithMessage:logMessage];
    NSString *tag = [self tagWithMessage:logMessage];

    return [[NSString alloc] initWithFormat:@"%@ %@%@ %@ %@",
            timestamp,
            level,
            extraInfo,
            tag,
            logMessage.message];
}

#pragma mark - Private

- (NSString *)levelWithMessage:(DDLogMessage *)logMessage {
    switch (logMessage.flag) {
        case DDLogFlagError:   return @"E";
        case DDLogFlagWarning: return @"W";
        case DDLogFlagInfo:    return @"I";
        case DDLogFlagDebug:   return @"D";
        case DDLogFlagVerbose: return @"V";
        default:               return @"";
    }
}

- (NSString *)extraInfoWithMessage:(DDLogMessage *)logMessage {
    if (logMessage.flag & DDLogFlagError ||
        logMessage.flag & DDLogFlagWarning) {
        return [NSString stringWithFormat:@" [%@:%lu]",
                [logMessage.fileName lastPathComponent],
                (unsigned long)logMessage.line];
    }
    return @"";
}

- (NSString *)tagWithMessage:(DDLogMessage *)logMessage {
    NSString *tag = logMessage.tag ?: [self tagFromFileName:logMessage.fileName];
    if (![tag isKindOfClass:NSString.class]) {
        return @"";
    }
    if ([tag hasPrefix:@"["] || [tag hasPrefix:@"【"]) {
        return tag;
    }
    return [[NSString alloc] initWithFormat:@"[%@]", tag];
}

- (NSString *)tagFromFileName:(NSString *)fileName {
    return [fileName stringByDeletingPathExtension] ?: fileName;
}

@end
