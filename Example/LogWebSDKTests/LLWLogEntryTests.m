#import <XCTest/XCTest.h>
#import "LogEntry.h"

@interface LLWLogEntryTests : XCTestCase
@end

@implementation LLWLogEntryTests

- (void)test_initWithLevelMessage_storesProperties {
    LLWLogEntry *entry = [[LLWLogEntry alloc] initWithLevel:LLWLogLevelError message:@"boom"];
    XCTAssertEqual(entry.level, LLWLogLevelError);
    XCTAssertEqualObjects(entry.message, @"boom");
}

- (void)test_allLevels_areStored {
    LLWLogLevel levels[] = {
        LLWLogLevelVerbose, LLWLogLevelDebug, LLWLogLevelInfo,
        LLWLogLevelWarning, LLWLogLevelError
    };
    for (NSUInteger i = 0; i < 5; i++) {
        LLWLogEntry *e = [[LLWLogEntry alloc] initWithLevel:levels[i] message:@"x"];
        XCTAssertEqual(e.level, levels[i]);
    }
}

- (void)test_message_isCopied {
    NSMutableString *msg = [NSMutableString stringWithString:@"hello"];
    LLWLogEntry *entry = [[LLWLogEntry alloc] initWithLevel:LLWLogLevelInfo message:msg];
    [msg appendString:@" world"];
    XCTAssertEqualObjects(entry.message, @"hello");
}

@end
