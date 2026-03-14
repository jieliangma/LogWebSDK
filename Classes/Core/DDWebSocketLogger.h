//
//  DDWebSocketLogger.h
//  LogWebSDK
//

#import <Foundation/Foundation.h>

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "LogEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface DDWebSocketLogger : DDAbstractLogger <DDLogger>

@property (class, nonatomic, strong, readonly) DDWebSocketLogger *sharedInstance;

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
