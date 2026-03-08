# LogWebSDK 快速参考

## 📦 安装

```ruby
# Podfile
pod 'LogWebSDK', :configurations => ['Debug']
```

```bash
$ pod install
```

## 🚀 使用

### 零配置（推荐）

```objc
// 不需要任何代码！SDK 会自动启动
```

### 手动控制

```objc
#import <LogWebSDK/LogWebSDK.h>

// 启动
[LogWebSDK startWithPort:8080];

// 停止
[LogWebSDK stop];
```

## 🌐 访问日志

### 浏览器访问

```
http://<device-ip>:8080
```

例如：`http://192.168.1.100:8080`

### macOS Console.app

自动发现设备名 `_ioslog._tcp`

## 🎨 Web 界面功能

- ✅ **实时推送** - WebSocket 实时更新
- ✅ **分级筛选** - Verbose/Debug/Info/Warn/Error
- ✅ **正则过滤** - 支持正则表达式搜索
- ✅ **断线重连** - 自动重连（指数退避）
- ✅ **一键清空** - 清空所有日志
- ✅ **响应式** - 支持桌面和移动端

## 📊 日志级别

| 级别 | 说明 | 颜色 |
|------|------|------|
| Verbose | 详细日志 | 灰色 |
| Debug | 调试日志 | 青色 |
| Info | 信息日志 | 绿色 |
| Warning | 警告日志 | 黄色 |
| Error | 错误日志 | 红色 |

## ⚙️ 配置选项

### 修改端口

```objc
[LogWebSDK startWithPort:9000];
```

### 禁用自动启动

在 Info.plist 中添加：

```xml
<key>LogWebSDKAutoStart</key>
<false/>
```

## 🔧 配合 CocoaLumberjack

```objc
#import <CocoaLumberjack/CocoaLumberjack.h>

DDLogVerbose(@"📝 Verbose message");
DDLogDebug(@"🔍 Debug message");
DDLogInfo(@"ℹ️ Info message");
DDLogWarning(@"⚠️ Warning message");
DDLogError(@"❌ Error message");
```

## 🛡️ 权限配置

SDK 会自动添加以下配置到 Info.plist：

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>用于在局域网内提供日志查看服务</string>

<key>NSBonjourServices</key>
<array>
    <string>_ioslog._tcp</string>
</array>
```

## 🏗️ 架构组件

```
LogWebSDK
├── LogWebSDK              # 主入口
├── DDWebSocketLogger      # CocoaLumberjack Logger
├── LLWLogBuffer          # 线程安全缓冲区
├── LLWLogWebServer       # HTTP/WebSocket 服务器
└── LogViewer.html        # Web UI
```

## 📋 系统要求

- iOS 11.0+
- CocoaLumberjack 3.x+
- Xcode 12.0+

## 🔍 故障排查

### SDK 未自动启动

检查是否在 Release 模式或测试环境，SDK 默认仅在 Debug 模式下自动启动。

### 无法连接

1. 确保设备和电脑在同一局域网
2. 检查防火墙设置
3. 确认端口未被占用

### Bonjour 未发现

1. 检查 Info.plist 中是否配置了 NSBonjourServices
2. 重启应用
3. 等待几秒让服务广播

## 📞 API 参考

### LogWebSDK

```objc
+ (BOOL)start;
+ (BOOL)startWithPort:(NSInteger)port;
+ (void)stop;
+ (NSDictionary *)configuration;
+ (NSString *)version;
+ (BOOL)isStarted;
```

### LLWLogWebServer

```objc
+ (instancetype)sharedInstance;
@property NSInteger port;
@property (readonly, getter=isRunning) BOOL running;
- (BOOL)startWithPort:(NSInteger)port error:(NSError **)error;
- (void)stop;
- (void)broadcastLog:(LLWLogEntry *)entry;
```
---

**更多详细信息请查看 README.md**
