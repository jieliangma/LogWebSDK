#import <XCTest/XCTest.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "LLWDefaultLogFormatter.h"

static DDLogMessage *makeMessage(DDLogFlag flag, NSString *msg, NSString *tag,
                                 NSString *file, NSUInteger line) {
    return [[DDLogMessage alloc] initWithMessage:msg
                                          level:DDLogLevelVerbose
                                           flag:flag
                                        context:0
                                           file:file
                                       function:@"testFunc"
                                           line:line
                                            tag:tag
                                        options:DDLogMessageDontCopyMessage
                                      timestamp:[NSDate date]];
}

@interface LLWDefaultLogFormatterTests : XCTestCase
@property (nonatomic, strong) LLWDefaultLogFormatter *formatter;
@end

@implementation LLWDefaultLogFormatterTests

- (void)setUp {
    self.formatter = [LLWDefaultLogFormatter new];
}

- (void)test_errorFlag_producesELevelPrefix {
    DDLogMessage *m = makeMessage(DDLogFlagError, @"oops", nil, @"/path/File.m", 42);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@" E "], @"Error prefix missing: %@", result);
}

- (void)test_warningFlag_producesWLevelPrefix {
    DDLogMessage *m = makeMessage(DDLogFlagWarning, @"warn", nil, @"/path/File.m", 10);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@" W "], @"Warning prefix missing: %@", result);
}

- (void)test_infoFlag_producesILevelPrefix {
    DDLogMessage *m = makeMessage(DDLogFlagInfo, @"info", nil, @"/path/File.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@" I "], @"Info prefix missing: %@", result);
}

- (void)test_debugFlag_producesDLevelPrefix {
    DDLogMessage *m = makeMessage(DDLogFlagDebug, @"dbg", nil, @"/path/File.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@" D "], @"Debug prefix missing: %@", result);
}

- (void)test_verboseFlag_producesVLevelPrefix {
    DDLogMessage *m = makeMessage(DDLogFlagVerbose, @"verbose", nil, @"/path/File.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@" V "], @"Verbose prefix missing: %@", result);
}

- (void)test_errorAndWarning_includeFileAndLineInfo {
    DDLogMessage *errMsg = makeMessage(DDLogFlagError, @"err", nil, @"/path/MyFile.m", 99);
    NSString *result = [self.formatter formatLogMessage:errMsg];
    XCTAssertTrue([result containsString:@"MyFile"], @"File name missing: %@", result);
    XCTAssertTrue([result containsString:@"99"], @"Line number missing: %@", result);
}

- (void)test_infoLevel_doesNotIncludeFileInfo {
    DDLogMessage *m = makeMessage(DDLogFlagInfo, @"info", nil, @"/path/MyFile.m", 5);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertFalse([result containsString:@"MyFile.m"], @"File info should not appear: %@", result);
}

- (void)test_tagFromString_isWrappedInBrackets {
    DDLogMessage *m = makeMessage(DDLogFlagDebug, @"msg", @"MyTag", @"/path/File.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@"[MyTag]"], @"Tag not wrapped: %@", result);
}

- (void)test_tagAlreadyBracketed_isNotDoubleWrapped {
    DDLogMessage *m = makeMessage(DDLogFlagDebug, @"msg", @"[AlreadyWrapped]", @"/path/File.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@"[AlreadyWrapped]"], @"Tag missing: %@", result);
    XCTAssertFalse([result containsString:@"[["], @"Double wrap detected: %@", result);
}

- (void)test_noTag_fallsBackToFileName {
    DDLogMessage *m = makeMessage(DDLogFlagDebug, @"msg", nil, @"/path/MyController.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@"[MyController]"], @"Filename tag missing: %@", result);
}

- (void)test_messageContent_isIncludedInOutput {
    DDLogMessage *m = makeMessage(DDLogFlagInfo, @"hello world", nil, @"/path/F.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    XCTAssertTrue([result containsString:@"hello world"]);
}

- (void)test_timestampFormat_matchesPattern {
    DDLogMessage *m = makeMessage(DDLogFlagInfo, @"t", nil, @"/path/F.m", 1);
    NSString *result = [self.formatter formatLogMessage:m];
    NSRegularExpression *re = [NSRegularExpression
        regularExpressionWithPattern:@"^\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d{3}"
                             options:0 error:nil];
    NSUInteger matches = [re numberOfMatchesInString:result
                                            options:0
                                              range:NSMakeRange(0, result.length)];
    XCTAssertEqual(matches, 1, @"Timestamp format mismatch: %@", result);
}

@end
