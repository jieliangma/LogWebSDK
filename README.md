# LogWebSDK

[![Version](https://img.shields.io/cocoapods/v/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)
[![License](https://img.shields.io/cocoapods/l/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)
[![Platform](https://img.shields.io/cocoapods/p/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)

**专家级 iOS 日志收集 SDK - 零配置实时查看 CocoaLumberjack 日志**

LogWebSDK 是一个强大的 iOS 日志收集工具，无需编写任何代码即可通过局域网实时查看 CocoaLumberjack 日志。内置 Web 服务器和 Bonjour 服务发现，支持浏览器和 macOS Console.app 查看日志。

## ✨ 特性

- 🚀 **零配置集成** - 集成即用，无需编写任何代码
- 🌐 **内置 Web 服务器** - 局域网浏览器实时查看日志
- 🔍 **Bonjour 服务发现** - macOS Console.app 自动发现设备
- 📊 **日志分级筛选** - 支持 Verbose/Debug/Info/Warn/Error 级别筛选
- 🔎 **正则表达式过滤** - 强大的日志搜索功能
- 🔄 **断线重连** - 自动重连机制，指数退避算法
- 🗑️ **一键清空** - 快速清空日志缓冲区
- 📱 **响应式设计** - 完美支持桌面端和移动端浏览器
- 🔒 **线程安全** - 专业级的并发处理
- ⚡ **高性能** - 纯实时流设计，极低内存占用
- 🎨 **优美界面** - 现代化暗色主题，12px 等宽字体

## 📦 安装

### 使用 CocoaPods

在项目的 `Podfile` 中添加：

```ruby
# 推荐仅在 Debug 模式下启用
pod 'LogWebSDK', :configurations => ['Debug']
```

然后执行：

```bash
$ pod install
```

### 手动安装

将 `Classes` 目录下的所有文件拖入项目中即可。

## 🚀 快速开始

### 基础使用

集成后**无需编写任何代码**，SDK 会自动启动并开始收集日志！

```objc
// AppDelegate.m
#import <LogWebSDK/LogWebSDK.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 不需要任何代码！SDK 会自动启动
    return YES;
}
```

### 手动控制（可选）

如果需要手动控制启动和停止：

```objc
#import <LogWebSDK/LogWebSDK.h>

// 启动 SDK（默认端口 8080）
[LogWebSDK start];

// 或指定端口
[LogWebSDK startWithPort:9000];

// 停止 SDK
[LogWebSDK stop];

// 获取配置信息
NSDictionary *config = [LogWebSDK configuration];
NSLog(@"Configuration: %@", config);
```

## 📖 使用说明

### 1. 通过浏览器查看日志

启动应用后，在局域网内的任意设备上打开浏览器访问：

```
http://<device-ip>:8080
```

例如：`http://192.168.1.100:8080`

**功能说明：**
- ✅ 实时日志推送（WebSocket）
- ✅ 日志分级筛选（Verbose/Debug/Info/Warn/Error）
- ✅ 正则表达式过滤
- ✅ 自动滚动到底部
- ✅ 断线重连（指数退避）
- ✅ 一键清空日志
- ✅ 响应式设计

### 2. 通过 macOS Console.app 查看

macOS 的 Console.app 会自动发现运行中的设备：

1. 打开 macOS 的 **Console.app**（控制台）
2. 在左侧边栏找到你的设备
3. 点击即可查看实时日志

**原理：** SDK 通过 Bonjour 广播 `_ioslog._tcp` 服务，macOS 会自动发现。

### 3. 配合 CocoaLumberjack 使用

SDK 会自动拦截所有通过 CocoaLumberjack 写入的日志：

```objc
#import <CocoaLumberjack/CocoaLumberjack.h>

// 正常使用 CocoaLumberjack
DDLogVerbose(@"This is a verbose message");
DDLogDebug(@"This is a debug message");
DDLogInfo(@"This is an info message");
DDLogWarning(@"This is a warning message");
DDLogError(@"This is an error message");

// 所有日志都会自动同步到 LogWebSDK
```

## ⚙️ 高级配置

### 修改默认端口

```objc
[LogWebSDK startWithPort:9000];
```

### 调整缓冲区大小

```objc
[[LLWLogBuffer sharedInstance] setMaxBufferSize:2000];
```

### 仅在 Debug 模式下启用

推荐在 Podfile 中配置：

```ruby
pod 'LogWebSDK', :configurations => ['Debug']
```

这样 Release 包不会包含 SDK，减小应用体积。

### 禁用自动启动

如果不希望 SDK 自动启动，可以在 Info.plist 中添加：

```xml
<key>LogWebSDKAutoStart</key>
<false/>
```

然后手动调用 `[LogWebSDK start]`。

## 🛡️ 隐私与权限

### Info.plist 配置

SDK 需要以下权限：

```xml
<!-- 本地网络访问描述 -->
<key>NSLocalNetworkUsageDescription</key>
<string>用于在局域网内提供日志查看服务</string>

<!-- Bonjour 服务 -->
<key>NSBonjourServices</key>
<array>
    <string>_ioslog._tcp</string>
</array>
```

这些配置会在安装时自动添加。

## 📋 系统要求

- iOS 11.0+
- CocoaLumberjack 3.x+
- Xcode 12.0+

## 🏗️ 架构设计

### 核心组件

```
LogWebSDK/
├── LogWebSDK           # 主入口，负责协调各组件
├── DDWebSocketLogger   # 自定义 Logger，收集 CocoaLumberjack 日志
├── LLWLogBuffer        # 线程安全的循环日志缓冲区
├── LLWLogWebServer     # HTTP/WebSocket 服务器
├── LLWLogBroadcastService  # Bonjour 服务发现
└── LogViewer.html      # 内嵌的日志查看器页面
```

### 工作流程

```
CocoaLumberjack → DDWebSocketLogger → LLWLogBuffer
                                              ↓
                                    LLWLogWebServer ←→ Browser/Console
                                              ↓
                                    LLWLogBroadcastService (Bonjour)
```

## 🔧 技术亮点

### 1. 零配置集成
- 使用 Objective-C `+load` 方法自动初始化
- Runtime 动态注册 Logger
- 智能检测测试环境和 Release 模式

### 2. 线程安全
- 串行队列保护缓冲区
- 弱引用表管理观察者
- 无锁设计，高性能

### 3. 性能优化
- 纯实时流，不存储历史
- WebSocket 批量推送
- 异步日志处理

### 4. 错误处理
- 端口冲突自动重试
- 断线重连（指数退避）
- 完善的错误日志

## 📝 示例项目

查看 Example 目录获取完整的使用示例。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

LogWebSDK 使用 MIT 许可证，详见 LICENSE 文件。

## 👨‍💻 作者

马杰亮 <majieliang@yeah.net>

## 🙏 致谢

- [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) - 优秀的日志框架
- 感谢所有贡献者

---

**Happy Logging! 🎉**
