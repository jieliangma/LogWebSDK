//
//  LogWebServer.h
//  LogWebSDK
//
//  嵌入式 HTTP/WebSocket 服务器（基于原生 CFNetwork）
//

#import <Foundation/Foundation.h>

#import "LogEntry.h"

NS_ASSUME_NONNULL_BEGIN

/// HTTP 请求处理方法
typedef void (^LLWHTTPRequestHandler)(NSDictionary *queryParams, NSDictionary *headers, void (^responseCallback)(NSInteger statusCode, NSString *contentType, NSString *body));

/// WebSocket 消息处理方法
typedef void (^LLWWebSocketMessageHandler)(NSString *message);

/// Web 服务器 - 单例模式
@interface LLWLogWebServer : NSObject

@property (class, nonatomic, strong, readonly) LLWLogWebServer *sharedInstance;

/// 服务器端口（默认 8080）
@property (nonatomic, assign) NSInteger port;

/// 是否正在运行
@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;

/// 启动服务器
/// @param port 端口号
/// @param error 错误信息
- (BOOL)startWithPort:(NSInteger)port error:(NSError **)error;

/// 停止服务器
- (void)stop;

/// 注册 HTTP GET 路由
/// @param path 路径
/// @param handler 处理回调
- (void)registerGETPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler;

/// 注册 HTTP POST 路由
/// @param path 路径
/// @param handler 处理回调
- (void)registerPOSTPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler;

/// 广播日志到所有 WebSocket 连接
/// @param entry 日志条目
- (void)broadcastLog:(LLWLogEntry *)entry;

/// 实时推送日志到所有 WebSocket 客户端（立即发送）
/// @param entry 日志条目
- (void)pushLogToClients:(LLWLogEntry *)entry;

@end

NS_ASSUME_NONNULL_END
