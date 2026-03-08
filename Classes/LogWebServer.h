//
//  LogWebServer.h
//  LogWebSDK
//

#import <Foundation/Foundation.h>
#import "LogEntry.h"

NS_ASSUME_NONNULL_BEGIN

/// HTTP 请求处理方法
typedef void (^LLWHTTPRequestHandler)(NSDictionary *headers, void (^responseCallback)(NSInteger statusCode, NSString *contentType, NSString *body));

/// 嵌入式 HTTP/WebSocket 服务器
@interface LLWLogWebServer : NSObject

/// 单例实例
@property (class, nonatomic, strong, readonly) LLWLogWebServer *sharedInstance;

/// 服务器端口（默认 8080）
@property (nonatomic, assign) NSInteger port;

/// 是否正在运行
@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;

/// 启动服务器
- (BOOL)startWithPort:(NSInteger)port error:(NSError **)error;

/// 停止服务器
- (void)stop;

/// 注册 HTTP GET 路由
- (void)registerGETPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler;

/// 注册 HTTP POST 路由
- (void)registerPOSTPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler;

/// 实时推送日志到所有 WebSocket 客户端
- (void)pushLogToClients:(LLWLogEntry *)entry;

@end

NS_ASSUME_NONNULL_END
