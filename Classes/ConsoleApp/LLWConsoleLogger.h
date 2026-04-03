#import <CocoaLumberjack/CocoaLumberjack.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLWConsoleLogger : DDAbstractLogger <DDLogger>

- (instancetype)initWithSubsystem:(NSString *)subsystem category:(NSString *)category;

@end

NS_ASSUME_NONNULL_END
