//
//  Example - AppDelegate.m
//  LogWebSDK Example
//
//  零配置集成示例 - 不需要写任何代码！
//

#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    return YES;
}

@end
