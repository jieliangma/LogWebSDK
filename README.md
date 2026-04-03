# LogWebSDK

[![Version](https://img.shields.io/cocoapods/v/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)
[![License](https://img.shields.io/cocoapods/l/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)
[![Platform](https://img.shields.io/cocoapods/p/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)

**零配置 iOS 日志查看 SDK — 局域网浏览器实时查看 CocoaLumberjack 日志**

## ✨ 特性

- 🚀 **零配置集成** — `pod install` 即用，无需任何代码
- 🌐 **内置 Web 服务器** — 局域网浏览器实时查看日志（基于 Network.framework NWListener）
- 🖥️ **NSLogger.app 支持**（默认）— 自动通过 Bonjour 连接 NSLogger.app，实时查看结构化日志
- 📡 **Console.app 支持**（可选子规格）— 通过 os_log 将日志写入系统日志，配合 Bonjour 广播可在 Console.app 发现设备
- 📊 **日志分级筛选** — Verbose / Debug / Info / Warning / Error
- 🔎 **正则表达式过滤** — 实时高亮匹配
- 🔄 **断线自动重连** — 指数退避算法
- 📱 **响应式界面** — 桌面端与移动端浏览器均可使用
- 🔒 **线程安全** — 基于 GCD 串行队列的并发模型

## 📦 安装

SDK 提供三个子规格，按需选择：

```ruby
# 默认：含 NSLogger.app 支持（推荐）
pod 'LogWebSDK', :configurations => ['Debug']

# 含 Console.app 支持（替代 NSLogger）
pod 'LogWebSDK/ConsoleApp', :configurations => ['Debug']

# 仅核心功能（浏览器查看，不含额外日志输出）
pod 'LogWebSDK/Core', :configurations => ['Debug']
```

然后执行：

```bash
pod install
```

## 🚀 快速开始

集成后**无需编写任何代码**，App 启动时 SDK 自动初始化。

```objc
// AppDelegate.m — 不需要任何代码
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}
```

打开 App 后，Example 界面会显示当前设备的局域网访问地址，在同一 WiFi 的浏览器中直接打开即可。

## 📖 使用说明

### 浏览器查看日志

```
http://<设备 IP>:8080
```

首次访问时 iOS 会弹出「本地网络访问」授权请求，点击「好」后即可正常访问。

**功能：**
- 实时日志推送（WebSocket）
- 日志分级筛选
- 正则表达式过滤：勾选单选框启用正则模式，取消勾选则为纯文本搜索（输入非法正则时显示红色边框提示）
- 智能自动滚动（用户上滚查阅历史时不强制跳底部）
- 最多保留 100000 条日志（自动丢弃最旧条目）
- 一键清空

### NSLogger.app 查看日志（默认子规格）

使用默认子规格（`pod 'LogWebSDK'`）时，SDK 会自动加载 `LLWNSLogger`，通过 Bonjour 连接局域网内正在运行的 NSLogger.app。

1. 在 App 的 `Info.plist` 中手动添加以下配置：
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>用于在局域网内提供日志查看服务</string>
<key>NSBonjourServices</key>
<array>
    <string>_ioslog._tcp</string>    <!-- 浏览器查看 -->
    <string>_nslogger._tcp</string>  <!-- NSLogger 查看 -->
</array>
```

2. 在 Mac 上打开 [NSLogger.app](https://github.com/fpillet/NSLogger)
3. 运行 App，SDK 自动发现并连接

### Console.app 查看日志（ConsoleApp 子规格）

使用 `pod 'LogWebSDK/ConsoleApp'` 时，SDK 通过 `os_log` 将日志写入系统日志，并通过 Bonjour 广播设备信息。

在 Console.app 中按如下条件筛选即可看到 SDK 日志：

```
subsystem:<应用 Bundle ID>  category:LogWebSDK
```

### 手动控制（可选）

```objc
#import <LogWebSDK/LogWebSDK.h>

[LogWebSDK start];              // 默认端口 8080
[LogWebSDK startWithPort:9000]; // 指定端口
[LogWebSDK stop];

NSDictionary *config = [LogWebSDK configuration];
// 包含 key: version, started, port, webServerRunning
```

### 禁用自动启动

在 App 的 `Info.plist` 中添加：

```xml
<key>LogWebSDKAutoStart</key>
<false/>
```

然后在合适时机手动调用 `[LogWebSDK start]`。

### 配合 CocoaLumberjack

SDK 自动注册为 `DDLogger`，所有通过 CocoaLumberjack 写入的日志均会实时推送：

```objc
DDLogVerbose(@"Verbose message");
DDLogDebug(@"Debug message");
DDLogInfo(@"Info message");
DDLogWarn(@"Warning message");
DDLogError(@"Error message");
```

## ⚙️ Info.plist 配置

以下配置需手动添加到宿主 App 的 `Info.plist`（CocoaPods `info_plist` 仅注入 SDK framework 自身，不会合并到宿主 App）：

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>用于在局域网内提供日志查看服务</string>
<key>NSBonjourServices</key>
<array>
    <string>_ioslog._tcp</string>    <!-- 浏览器查看 / Console.app -->
    <string>_nslogger._tcp</string>  <!-- NSLogger.app（使用 NSLogger 子规格时） -->
</array>
```

## 📋 系统要求

| 条件 | 要求 |
|---|---|
| iOS | 12.0+ |
| Xcode | 13.0+ |
| CocoaLumberjack | 3.x |

## 🏗️ 架构

SDK 按子规格划分：

```
Core（所有子规格共享）
├── LogWebSDK           — 门面，+load 自动启动，发送 LLWLogWebSDKDidStart / LLWLogWebSDKDidStop 通知
├── DDWebSocketLogger   — DDLogger 实现，接收日志推送到服务器
├── LLWLogEntry         — 日志条目模型
├── LLWLogWebServer     — HTTP/WebSocket 服务器（Network.framework NWListener）
└── Resources/LogViewer.html — 内嵌浏览器日志查看页面

NSLogger（默认子规格）
└── LLWNSLogger         — 监听 LLWLogWebSDKDidStart，通过 Bonjour 连接 NSLogger.app

ConsoleApp（可选子规格）
├── LLWConsoleLogger    — 通过 os_log 写入系统日志
└── LLWLogBroadcastService — Bonjour 服务广播（NSNetService）
```

**数据流：**

```
DDLog → DDWebSocketLogger → LLWLogEntry
                                  ↓
                          LLWLogWebServer → WebSocket → 浏览器

                          LLWLogWebSDKDidStart
                                  ↓
              ┌───────────────────┴───────────────────┐
              ↓（NSLogger 子规格）                     ↓（ConsoleApp 子规格）
         LLWNSLogger                           LLWConsoleLogger (os_log)
      (Bonjour → NSLogger.app)          LLWLogBroadcastService (Bonjour)
```

## 📝 示例项目

```bash
cd Example
pod install
open LogWebSDK_Example.xcworkspace
```

## 📄 许可证

MIT License — 详见 LICENSE 文件。

## 👨‍💻 作者

马杰亮 <majieliang@yeah.net>
