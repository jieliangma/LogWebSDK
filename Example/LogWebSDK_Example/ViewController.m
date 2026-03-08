//
//  Example - ViewController.m
//  LogWebSDK Example
//
//  演示各种级别的日志输出
//

#import "ViewController.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

// 设置日志级别
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 添加按钮
    [self createButtons];
}

- (void)createButtons {
    NSArray *titles = @[@"Verbose", @"Debug", @"Info", @"Warning", @"Error"];
    SEL selectors[] = {@selector(logVerbose), @selector(logDebug), @selector(logInfo), @selector(logWarning), @selector(logError)};
    
    for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(50, 100 + i * 60, 200, 44);
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button addTarget:self action:selectors[i] forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

#pragma mark - Button Actions

- (void)logVerbose {
    DDLogVerbose(@"📝 Verbose: User clicked verbose button - timestamp: %@", [NSDate date]);
}

- (void)logDebug {
    DDLogDebug(@"🔍 Debug: Button pressed - memory usage: %lu MB", (unsigned long)([[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024));
}

- (void)logInfo {
    DDLogInfo(@"ℹ️ Info: Application state changed to active");
}

- (void)logWarning {
    DDLogWarn(@"⚠️ Warning: Network connection unstable - signal strength: weak");
}

- (void)logError {
    DDLogError(@"❌ Error: Failed to load data from server - error code: 500");
}

@end
