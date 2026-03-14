# LogWebSDK

[![Version](https://img.shields.io/cocoapods/v/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)
[![License](https://img.shields.io/cocoapods/l/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)
[![Platform](https://img.shields.io/cocoapods/p/LogWebSDK.svg?style=flat)](https://cocoapods.org/pods/LogWebSDK)

**零配置 iOS 日志查看 SDK — 局域网浏览器实时查看 CocoaLumberjack 日志**

## ✨ 特性

- 🚀 **零配置集成** — `pod install` 即用，无需任何代码
- 🌐 **内置 Web 服务器** — 局域网浏览器实时查看日志（基于 Network.framework NWListener）
- 📊 **日志分级筛选** — Verbose / Debug / Info / Warning / Error
- 🔎 **正则表达式过滤** — 实时高亮匹配
- 🔄 **断线自动重连** — 指数退避算法
- 📱 **响应式界面** — 桌面端与移动端浏览器均可使用
- 🔒 **线程安全** — 基于 GCD 串行队列的并发模型

## 📦 安装

### 默认支持 Web 查看器和 NSLogger

```ruby
# 推荐仅在 Debug 模式下启用，Release 包不含 SDK
pod 'LogWebSDK', :configurations => ['Debug']
```

### 基础版只支持 Web 查看器

```ruby
# 不支持 NSLogger Viewer（macOS 桌面应用）
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
- 正则表达式过滤（输入非法正则时显示红色边框提示）
- 智能自动滚动（用户上滚查阅历史时不强制跳底部）
- 最多保留 100000 条日志（自动丢弃最旧条目）
- 一键清空

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

## 🔌 NSLogger 集成（可选）

如果安装了 `LogWebSDK/NSLogger` 子组件，可以同时支持 NSLogger Viewer。

### 使用方式

安装后无需编写任何代码，NSLogger 会自动发现设备并接收日志。

**macOS 端：**
1. 下载并打开 [NSLogger Viewer](https://github.com/fpillet/NSLogger)
2. 设置 NSLogger 的 Bonjour 服务名。服务名会在控制台打印，搜索“LogWebSDK - NSLogger”可查找到。
3. 应用启动后，NSLogger 会自动发现 iOS 设备
4. 在左侧边栏选择设备即可查看实时日志

**特点：**
- ✅ 原生 macOS 应用，性能优秀
- ✅ 支持多设备同时监控
- ✅ 丰富的过滤和搜索功能
- ✅ 支持图形化显示日志统计

## ⚙️ Info.plist 配置

**注意：** 需要在宿主应用的 Info.plist 中手动添加以下配置（CocoaPods 不会自动注入）：

```xml
<!-- 宿主应用的 Info.plist -->
<key>NSLocalNetworkUsageDescription</key>
<string>用于在局域网内提供日志查看服务</string>

<key>NSBonjourServices</key>
<array>
    <string>_ioslog._tcp</string>      <!-- WebSocket 日志查看器 -->
</array>
```

### NSLogger 版本

如果使用了 `LogWebSDK/NSLogger` 子组件，需要在 Info.plist 中额外添加 NSLogger 的 Bonjour 服务：

```xml
<key>NSBonjourServices</key>
<array>
    <string>_ioslog._tcp</string>      <!-- WebSocket 日志查看器 -->
    <string>_nslogger._tcp</string>    <!-- NSLogger macOS Viewer -->
</array>
```

## 📋 系统要求

| 条件 | 要求 |
|---|---|
| iOS | 12.0+ |
| Xcode | 13.0+ |
| CocoaLumberjack | 3.x |

## 🏗️ 架构

```
LogWebSDK（门面，+load 自动启动）
├── DDWebSocketLogger   — DDLogger 实现，接收日志推送到服务器
├── LLWLogEntry         — 日志条目模型
├── LLWLogWebServer     — HTTP/WebSocket 服务器（Network.framework NWListener）
└── Resources/LogViewer.html — 内嵌浏览器日志查看页面
```

**数据流：**

```
DDLog → DDWebSocketLogger → LLWLogEntry
                                  ↓
                          LLWLogWebServer → WebSocket → 浏览器
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
