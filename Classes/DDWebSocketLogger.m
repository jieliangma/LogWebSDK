//
//  DDWebSocketLogger.m
//  LogWebSDK
//

#import "DDWebSocketLogger.h"
#import "LogWebServer.h"  // 导入 WebSocket 服务器

@interface DDWebSocketLogger ()
@property (nonatomic, assign) BOOL isLogging;
@end

@implementation DDWebSocketLogger

+ (instancetype)sharedInstance {
    static DDWebSocketLogger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DDWebSocketLogger alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _enabled = YES;
        _isLogging = NO;
        // 设置日志格式：支持所有级别
        self.logFormatter = [[DefaultLogFormatter alloc] init];
    }
    return self;
}

#pragma mark - DDLogger Protocol

/// 实现 DDLogger 协议的核心方法
- (void)logMessage:(DDLogMessage *)logMessage {
    if (!self.enabled || !self.isLogging) {
        return;
    }
    
    // 格式化并添加到缓冲区
    [self formatMessage:logMessage];
}

- (void)didAddToLogger:(id<DDLogger>)logger {
    [self startLogging];
}

- (void)didRemoveFromLogger:(id<DDLogger>)logger {
    [self stopLogging];
}

#pragma mark - Public Methods

- (void)startLogging {
    if (self.isLogging) {
        return;
    }
    
    self.isLogging = YES;
    NSLog(@"[LogWebSDK] DDWebSocketLogger started");
}

- (void)stopLogging {
    if (!self.isLogging) {
        return;
    }
    
    self.isLogging = NO;
    NSLog(@"[LogWebSDK] DDWebSocketLogger stopped");
}

#pragma mark - Private Methods

/// 格式化日志消息
- (NSString *)formatMessage:(DDLogMessage *)logMessage {
    // 关键：立即推送给 WebSocket 服务器（实时推送）
    LLWLogWebServer *server = [LLWLogWebServer sharedInstance];
    if (server.isRunning) {
        // 提取文件名（不含路径）
        NSString *fileName = [logMessage.fileName lastPathComponent];
        
        // 转换日志级别
        LLWLogLevel level = [self convertLogLevel:logMessage.flag];
        
        // 创建日志条目
        NSString *tag = logMessage.representedObject ?: fileName;
        LLWLogEntry *entry = [[LLWLogEntry alloc] initWithLevel:level
                                                        message:[self formatLogMessage:logMessage]
                                                            tag:tag];
        
        [server pushLogToClients:entry];
    }
    
    return nil;  // DDLog 不需要返回值
}

/// 转换日志级别
- (LLWLogLevel)convertLogLevel:(DDLogFlag)flag {
    if (flag & DDLogFlagError) {
        return LLWLogLevelError;
    } else if (flag & DDLogFlagWarning) {
        return LLWLogLevelWarning;
    } else if (flag & DDLogFlagInfo) {
        return LLWLogLevelInfo;
    } else if (flag & DDLogFlagDebug) {
        return LLWLogLevelDebug;
    } else {
        return LLWLogLevelVerbose;
    }
}

/// 格式化日志消息内容
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    NSString *timestamp = [dateFormatter stringFromDate:logMessage.timestamp];
    
    return [NSString stringWithFormat:@"%@ [%@] %@:%lu %@ %@",
            timestamp,
            [self levelString:logMessage.flag],
            logMessage.fileName,
            (unsigned long)logMessage.line,
            logMessage.function ?: @"",
            logMessage.message];
}

/// 日志级别字符串
- (NSString *)levelString:(DDLogFlag)flag {
    if (flag & DDLogFlagError) {
        return @"[E]";
    } else if (flag & DDLogFlagWarning) {
        return @"[W]";
    } else if (flag & DDLogFlagInfo) {
        return @"[I]";
    } else if (flag & DDLogFlagDebug) {
        return @"[D]";
    } else {
        return @"[V]";
    }
}

/// 将日志条目转换为 JSON
- (NSString *)entryToJSON:(LLWLogEntry *)entry {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM-dd'T'HH:mm:ss.SSSZ";
    
    NSDictionary *dict = @{
        @"level": @(entry.level),
        @"levelStr": [self levelNumberToString:entry.level],
        @"message": entry.message,
        @"timestamp": [dateFormatter stringFromDate:entry.timestamp],
        @"tag": entry.tag
    };
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (error) {
        return @"";
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/// 日志级别数字转字符串
- (NSString *)levelNumberToString:(LLWLogLevel)level {
    switch (level) {
        case LLWLogLevelError:
            return @"[E]";
        case LLWLogLevelWarning:
            return @"[W]";
        case LLWLogLevelInfo:
            return @"[I]";
        case LLWLogLevelDebug:
            return @"[D]";
        case LLWLogLevelVerbose:
        default:
            return @"[V]";
    }
}

@end

#pragma mark - Default LogFormatter

@implementation DefaultLogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    return logMessage.message;
}

@end
