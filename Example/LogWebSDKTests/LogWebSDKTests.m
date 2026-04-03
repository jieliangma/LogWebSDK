#import <XCTest/XCTest.h>
#import "LogWebSDK.h"

@interface LogWebSDKTests : XCTestCase
@end

@implementation LogWebSDKTests

- (void)tearDown {
    [LogWebSDK stop];
}

- (void)test_version_isNonEmpty {
    XCTAssertGreaterThan(LogWebSDK.version.length, 0);
}

- (void)test_initialState_isNotStarted {
    XCTAssertFalse(LogWebSDK.isStarted);
}

- (void)test_startWithPort_returnsYES {
    BOOL result = [LogWebSDK startWithPort:18080];
    XCTAssertTrue(result);
}

- (void)test_startWithPort_setsIsStarted {
    [LogWebSDK startWithPort:18081];
    XCTAssertTrue(LogWebSDK.isStarted);
}

- (void)test_startWithPort_setsCurrentPort {
    [LogWebSDK startWithPort:18082];
    XCTAssertEqualObjects([LogWebSDK configuration][@"port"], @(18082));
}

- (void)test_stopAfterStart_setsIsStartedToNO {
    [LogWebSDK startWithPort:18083];
    [LogWebSDK stop];
    XCTAssertFalse(LogWebSDK.isStarted);
}

- (void)test_startTwice_isIdempotent {
    [LogWebSDK startWithPort:18084];
    BOOL second = [LogWebSDK startWithPort:18084];
    XCTAssertTrue(second);
    XCTAssertTrue(LogWebSDK.isStarted);
}

- (void)test_stopWithoutStart_doesNotCrash {
    XCTAssertNoThrow([LogWebSDK stop]);
}

- (void)test_configuration_containsExpectedKeys {
    [LogWebSDK startWithPort:18085];
    NSDictionary *config = [LogWebSDK configuration];
    XCTAssertNotNil(config[@"version"]);
    XCTAssertNotNil(config[@"started"]);
    XCTAssertNotNil(config[@"port"]);
    XCTAssertNotNil(config[@"webServerRunning"]);
}

- (void)test_startDidStart_postsNotification {
    XCTestExpectation *exp = [self expectationWithDescription:@"LLWLogWebSDKDidStart"];
    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:@"LLWLogWebSDKDidStart"
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) { [exp fulfill]; }];
    [LogWebSDK startWithPort:18086];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

@end
