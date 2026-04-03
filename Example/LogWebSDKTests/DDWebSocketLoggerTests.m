#import <XCTest/XCTest.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "DDWebSocketLogger.h"
#import "LogEntry.h"

@interface DDWebSocketLogger (Testing)
- (LLWLogLevel)llw_convertFlag:(DDLogFlag)flag;
@end

@interface DDWebSocketLoggerTests : XCTestCase
@property (nonatomic, strong) DDWebSocketLogger *logger;
@end

@implementation DDWebSocketLoggerTests

- (void)setUp {
    self.logger = [DDWebSocketLogger new];
}

- (void)test_errorFlag_mapsToErrorLevel {
    XCTAssertEqual([self.logger llw_convertFlag:DDLogFlagError], LLWLogLevelError);
}

- (void)test_warningFlag_mapsToWarningLevel {
    XCTAssertEqual([self.logger llw_convertFlag:DDLogFlagWarning], LLWLogLevelWarning);
}

- (void)test_infoFlag_mapsToInfoLevel {
    XCTAssertEqual([self.logger llw_convertFlag:DDLogFlagInfo], LLWLogLevelInfo);
}

- (void)test_debugFlag_mapsToDebugLevel {
    XCTAssertEqual([self.logger llw_convertFlag:DDLogFlagDebug], LLWLogLevelDebug);
}

- (void)test_verboseFlag_mapsToVerboseLevel {
    XCTAssertEqual([self.logger llw_convertFlag:DDLogFlagVerbose], LLWLogLevelVerbose);
}

- (void)test_defaultEnabled_isYES {
    XCTAssertTrue([DDWebSocketLogger new].enabled);
}

- (void)test_sharedInstance_returnsSameObject {
    XCTAssertEqual([DDWebSocketLogger sharedInstance], [DDWebSocketLogger sharedInstance]);
}

@end
