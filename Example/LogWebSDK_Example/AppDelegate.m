//
//  Example - AppDelegate.m
//  LogWebSDK Example
//
//  零配置集成示例 - 不需要写任何代码！
//

#import "AppDelegate.h"
#import <LogWebSDK/LogWebSDK.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

// 定义日志级别
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // ========== CocoaLumberjack 初始化 ==========
    // 添加控制台日志输出
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    
    // 输出测试日志
    DDLogVerbose(@"🚀 Application launched!");
    
    return YES;
}

@end
