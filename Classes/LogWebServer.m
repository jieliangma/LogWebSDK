//
//  LogWebServer.m
//  LogWebSDK
//
//  基于 CFNetwork 的原生 HTTP/WebSocket 服务器实现
//

#import "LogWebServer.h"
#import <CFNetwork/CFNetwork.h>
#import <CommonCrypto/CommonCrypto.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <sys/ioctl.h>  // 用于 ioctl 和 FIONREAD

// WebSocket 相关常量
static const uint8_t OPCODE_TEXT = 0x1;
static const uint8_t OPCODE_CLOSE = 0x8;
static const uint8_t OPCODE_PING = 0x9;
// static const uint8_t OPCODE_PONG = 0xA;  // 保留但暂时未使用

// WebSocket Connection 类的声明
@interface LLWWebSocketConnection : NSObject
@property (nonatomic, assign) int socket;
@property (nonatomic, assign) BOOL isClosed;
@property (nonatomic, weak) LLWLogWebServer *server;
@property (nonatomic, strong) NSString *handshakeKey;
@property (nonatomic, assign) BOOL isWebSocket;
@property (nonatomic, strong) dispatch_queue_t socketQueue;  // 专用的 socket IO 队列
@property (nonatomic, strong) dispatch_source_t readSource;  // 监视 socket 可读事件
@property (nonatomic, strong) NSMutableData *inputBuffer;    // 输入缓冲区
- (instancetype)initWithSocket:(int)socket server:(LLWLogWebServer *)server;
- (void)startReading;
- (void)sendData:(NSData *)data;
- (void)close;
@end

// 前向声明
@class LLWWebSocketConnection;

// CFSocket 回调函数前向声明
static void llw_socketCallback(CFSocketRef s, CFSocketCallBackType type, const CFDataRef address, const void *data, void *info);

@interface LLWLogWebServer () {
    CFSocketRef _socketRef;
    CFRunLoopSourceRef _runLoopSource;
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, LLWHTTPRequestHandler> *getRoutes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, LLWHTTPRequestHandler> *postRoutes;
@property (nonatomic, strong) NSMutableArray<LLWWebSocketConnection *> *websocketConnections;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) dispatch_queue_t serverQueue;

@end

@implementation LLWWebSocketConnection

- (instancetype)initWithSocket:(int)socket server:(LLWLogWebServer *)server {
    if (self = [super init]) {
        _socket = socket;
        _server = server;
        _isClosed = NO;
        _isWebSocket = NO;  // 初始为普通 HTTP 连接，握手后升级为 WebSocket
        _socketQueue = dispatch_queue_create("com.logweb.sdk.socket", DISPATCH_QUEUE_SERIAL);
        _inputBuffer = [NSMutableData data];
    }
    return self;
}

- (void)startReading {
    // 创建 dispatch source 监听 socket 可读事件
    self.readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, self.socket, 0, self.socketQueue);
    
    dispatch_source_set_event_handler(self.readSource, ^{
        [self readFromSocket];
    });
    
    dispatch_resume(self.readSource);
}

- (void)readFromSocket {
    // 使用 dispatch_source_get_data() 获取可读取的字节数
    size_t bytesAvailable = dispatch_source_get_data(self.readSource);
    
    if (bytesAvailable == 0) {
        return;  // 没有数据可读
    }
    
    // 一次性读取所有可用数据
    uint8_t buffer[bytesAvailable];
    ssize_t bytesRead = recv(self.socket, buffer, sizeof(buffer), 0);
    
    if (bytesRead > 0) {
        // 追加到输入缓冲区
        [self.inputBuffer appendBytes:buffer length:bytesRead];
        
        if (!self.isWebSocket) {
            // 检查 HTTP 请求是否完整
            if ([self isHTTPRequestComplete]) {
                [self processHTTPRequest];
                return;
            }
        } else {
            // WebSocket 帧处理
            [self processWebSocketFrame];
        }
    } else if (bytesRead == 0) {
        // 连接关闭
        [self close];
    } else if (errno == EAGAIN || errno == EWOULDBLOCK) {
        // 没有更多数据
    } else {
        // 其他错误
        [self close];
    }
}

- (BOOL)isHTTPRequestComplete {
    NSString *request = [[NSString alloc] initWithData:self.inputBuffer encoding:NSUTF8StringEncoding];
    BOOL complete = [request containsString:@"\r\n\r\n"];
    return complete;
}

- (void)processHTTPRequest {
    NSString *request = [[NSString alloc] initWithData:self.inputBuffer encoding:NSUTF8StringEncoding];
    NSLog(@"📥 [LogWebSDK] Received HTTP request:\n%@", request);
    
    // 解析 HTTP 请求行
    NSArray *lines = [request componentsSeparatedByString:@"\r\n"];
    if (lines.count == 0) return;
    
    NSString *requestLine = lines[0];
    NSArray *parts = [requestLine componentsSeparatedByString:@" "];
    if (parts.count < 2) return;
    
    NSString *method = parts[0];
    NSString *path = parts[1];
    
    // 提取 headers
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    for (NSInteger i = 1; i < lines.count; i++) {
        NSString *line = lines[i];
        if (line.length == 0) break;
        
        // 支持多种分隔符格式
        NSRange colonRange = [line rangeOfString:@":"];
        if (colonRange.location != NSNotFound) {
            NSString *key = [[line substringToIndex:colonRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [[line substringFromIndex:NSMaxRange(colonRange)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            headers[key] = value;
        }
    }
    
    // 检查是否是 WebSocket 升级请求
    if ([method isEqualToString:@"GET"] &&
        [headers[@"Upgrade"] length] > 0 &&
        [headers[@"Upgrade"] caseInsensitiveCompare:@"websocket"] == NSOrderedSame) {
        [self handleWebSocketHandshake:request];
        return;
    }
    
    // 普通 HTTP 请求处理
    if ([method isEqualToString:@"GET"]) {
        [self handleHTTPGetRequest:path headers:headers];
    } else if ([method isEqualToString:@"POST"]) {
        [self handleHTTPPostRequest:path headers:headers body:[self extractBody:request]];
    }
}

- (void)handleHTTPGetRequest:(NSString *)path headers:(NSDictionary *)headers {
    NSLog(@"📥 [LogWebSDK] Handling GET request: %@", path);
    
    LLWHTTPRequestHandler handler = self.server.getRoutes[path];
    if (!handler) {
        NSLog(@"⚠️ [LogWebSDK] No handler found for path: %@", path);
        [self sendResponse:404 contentType:@"text/plain" body:@"Not Found"];
        return;
    }
    
    // 简化处理：直接调用 handler
    handler(nil, headers, ^(NSInteger statusCode, NSString *contentType, NSString *body) {
        NSLog(@"📤 [LogWebSDK] Sending response: %ld - %@", (long)statusCode, contentType);
        [self sendResponse:statusCode contentType:contentType body:body ?: @""];
    });
}

- (void)handleHTTPPostRequest:(NSString *)path headers:(NSDictionary *)headers body:(NSString *)body {
    LLWHTTPRequestHandler handler = self.server.postRoutes[path];
    if (!handler) {
        [self sendResponse:404 contentType:@"text/plain" body:@"Not Found"];
        return;
    }
    
    handler(nil, headers, ^(NSInteger statusCode, NSString *contentType, NSString *responseBody) {
        [self sendResponse:statusCode contentType:contentType body:responseBody ?: @""];
    });
}

- (NSString *)extractBody:(NSString *)request {
    NSArray *parts = [request componentsSeparatedByString:@"\r\n\r\n"];
    return parts.count > 1 ? parts[1] : @"";
}

- (void)sendResponse:(NSInteger)statusCode contentType:(NSString *)contentType body:(NSString *)body {
    NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSString *response = [NSString stringWithFormat:
        @"HTTP/1.1 %ld OK\r\n"
        @"Content-Type: %@\r\n"
        @"Content-Length: %lu\r\n"
        @"Connection: close\r\n"
        @"\r\n",
        (long)statusCode, contentType, (unsigned long)bodyData.length];
    
    NSMutableData *fullResponse = [NSMutableData dataWithData:[response dataUsingEncoding:NSUTF8StringEncoding]];
    [fullResponse appendData:bodyData];
    
    [self writeToSocket:fullResponse];
    
    // 非 WebSocket 连接，发送完响应后关闭
    if (!self.isWebSocket) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), self.socketQueue, ^{
            [self close];
        });
    }
}

- (void)handleWebSocketHandshake:(NSString *)request {
    NSLog(@"🤝 [LogWebSDK] Handling WebSocket handshake");
    
    // 提取 Sec-WebSocket-Key
    NSArray *lines = [request componentsSeparatedByString:@"\r\n"];
    NSString *key = nil;
    for (NSString *line in lines) {
        if ([line hasPrefix:@"Sec-WebSocket-Key:"]) {
            key = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            key = [key substringFromIndex:19];  // 去掉 "Sec-WebSocket-Key:"
            break;
        }
    }
    
    if (key) {
        // 生成 Accept Key
        NSString *magicString = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
        NSString *combined = [key stringByAppendingString:magicString];
        NSData *combinedData = [combined dataUsingEncoding:NSUTF8StringEncoding];
        unsigned char sha1Sum[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1(combinedData.bytes, (CC_LONG)combinedData.length, sha1Sum);
        NSString *acceptKey = [self base64Encode:sha1Sum length:CC_SHA1_DIGEST_LENGTH];
        
        // 发送握手响应
        NSString *response = [NSString stringWithFormat:
            @"HTTP/1.1 101 Switching Protocols\r\n"
            @"Upgrade: websocket\r\n"
            @"Connection: Upgrade\r\n"
            @"Sec-WebSocket-Accept: %@\r\n\r\n", acceptKey];
        
        NSLog(@"📤 [LogWebSDK] Sending WebSocket handshake response:\n%@", response);
        [self writeToSocket:[response dataUsingEncoding:NSUTF8StringEncoding]];
        
        self.isWebSocket = YES;
        NSLog(@"✅ [LogWebSDK] WebSocket connection established");
    } else {
        // 发送握手响应
        NSString *response = @"HTTP/1.1 400 Bad Request\r\n";
        
        NSLog(@"📤 [LogWebSDK] Sending WebSocket handshake response:\n%@", response);
        [self writeToSocket:[response dataUsingEncoding:NSUTF8StringEncoding]];
        
        self.isWebSocket = NO;
        NSLog(@"✅ [LogWebSDK] not WebSocket");
    }
}

- (void)processWebSocketFrame {
    // 简单的 WebSocket 帧处理
    if (self.inputBuffer.length < 2) return;
    
    const uint8_t *bytes = self.inputBuffer.bytes;
    uint8_t opcode = bytes[0] & 0x0F;
    
    if (opcode == OPCODE_TEXT) {
        // 文本消息
        // 这里可以处理客户端发送的消息
    } else if (opcode == OPCODE_PING) {
        // 回复 PONG
        [self sendPong];
    } else if (opcode == OPCODE_CLOSE) {
        // 关闭连接
        [self close];
    }
}

- (void)sendData:(NSData *)data {
    dispatch_async(self.socketQueue, ^{
        if (self.isClosed) return;
        
        // 构造 WebSocket 文本帧
        NSMutableData *frame = [NSMutableData data];
        
        // FIN + 文本帧
        uint8_t header = 0x80 | OPCODE_TEXT;
        [frame appendBytes:&header length:1];
        
        // 数据长度（不掩码，服务器到客户端不需要掩码）
        uint64_t length = data.length;
        if (length < 126) {
            uint8_t len = (uint8_t)length;
            [frame appendBytes:&len length:1];
        } else if (length < 65536) {
            uint8_t len = 126;
            [frame appendBytes:&len length:1];
            uint16_t len16 = CFSwapInt16HostToBig((uint16_t)length);
            [frame appendBytes:&len16 length:2];
        } else {
            uint8_t len = 127;
            [frame appendBytes:&len length:1];
            uint64_t len64 = CFSwapInt64HostToBig(length);
            [frame appendBytes:&len64 length:8];
        }
        
        // 数据
        [frame appendData:data];
        
        [self writeToSocket:frame];
    });
}

- (void)writeToSocket:(NSData *)data {
    if (self.isClosed) return;
    
    ssize_t bytesSent = send(self.socket, data.bytes, data.length, 0);
    if (bytesSent < 0) {
        NSLog(@"❌ [LogWebSDK] Failed to send data: %s", strerror(errno));
        [self close];
    }
}

- (void)sendPong {
    // 发送 PONG 响应
    uint8_t pong[] = {0x8A, 0x00};  // FIN + PONG opcode, 长度 0
    [self writeToSocket:[NSData dataWithBytes:pong length:2]];
}

- (NSString *)base64Encode:(const unsigned char *)data length:(NSUInteger)length {
    NSData *nsData = [NSData dataWithBytes:data length:length];
    return [nsData base64EncodedStringWithOptions:0];
}

- (void)close {
    if (_isClosed) return;
    
    _isClosed = YES;
    int socketToClose = _socket;
    
    // 取消 read source
    if (self.readSource) {
        dispatch_source_cancel(self.readSource);
        self.readSource = nil;
    }
    
    // 关闭 socket
    if (socketToClose >= 0) {
        close(socketToClose);
    }
    
    // 从连接列表中移除
    if (self.server) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.server.websocketConnections removeObject:self];
        });
    }
}

@end

@implementation LLWLogWebServer

+ (instancetype)sharedInstance {
    static LLWLogWebServer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LLWLogWebServer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _port = 8080;
        _getRoutes = [NSMutableDictionary dictionary];
        _postRoutes = [NSMutableDictionary dictionary];
        _websocketConnections = [NSMutableArray array];
        _serverQueue = dispatch_queue_create("com.logweb.sdk.server", DISPATCH_QUEUE_SERIAL);
        
        // 注册默认路由
        [self registerDefaultRoutes];
    }
    return self;
}

- (BOOL)startWithPort:(NSInteger)port error:(NSError **)error {
    if (self.isRunning) {
        NSLog(@"[LogWebSDK] Server already running");
        return YES;
    }
    
    // 创建 socket
    struct sockaddr_in addr;
    socklen_t addrSize = sizeof(addr);
    bzero(&addr, addrSize);
    addr.sin_len = (uint8_t)addrSize;
    addr.sin_family = AF_INET;
    addr.sin_port = htons((uint16_t)port);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"LogWebSDK" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create socket"}];
        }
        return NO;
    }
    
    // 设置 socket 选项，允许端口重用
    int reuse = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    
    // 设置为非阻塞模式（dispatch_source 需要）
    int flags = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, flags | O_NONBLOCK);
    
    // 绑定地址
    if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(sock);
        if (error) {
            *error = [NSError errorWithDomain:@"LogWebSDK" code:2 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to bind port %ld", (long)port]
            }];
        }
        return NO;
    }
    
    // 开始监听
    int listenResult = listen(sock, 10);
    if (listenResult < 0) {
        close(sock);
        if (error) {
            *error = [NSError errorWithDomain:@"LogWebSDK" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Failed to listen"}];
        }
        return NO;
    }
    
    // 创建 CFSocket
    CFSocketContext context;
    socklen_t contextSize = sizeof(CFSocketContext);
    bzero(&context, contextSize);
    context.version = 0;
    context.info = (__bridge void *)self;
    _socketRef = CFSocketCreateWithNative(
        kCFAllocatorDefault,
        sock,
        kCFSocketAcceptCallBack,
        llw_socketCallback,
        &context
    );
    
    if (!_socketRef) {
        close(sock);
        if (error) {
            *error = [NSError errorWithDomain:@"LogWebSDK" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create CFSocket"}];
        }
        return NO;
    }
    
    // 添加到 RunLoop
    _runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socketRef, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
    
    _isRunning = YES;
    _port = port;
    
    return YES;
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }
    
    // 关闭所有 WebSocket 连接
    for (LLWWebSocketConnection *connection in [self.websocketConnections copy]) {
        [connection close];
    }
    [self.websocketConnections removeAllObjects];
    
    // 关闭服务器 socket
    if (_runLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
        CFRelease(_runLoopSource);
        _runLoopSource = NULL;
    }
    
    if (_socketRef) {
        CFSocketInvalidate(_socketRef);
        CFRelease(_socketRef);
        _socketRef = NULL;
    }
    
    _isRunning = NO;
    NSLog(@"[LogWebSDK] Server stopped");
}

- (void)registerGETPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler {
    self.getRoutes[path] = handler;
}

- (void)registerPOSTPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler {
    self.postRoutes[path] = handler;
}

#pragma mark - Log Push

/**
 * 推送日志到所有已连接的 WebSocket 客户端
 */
- (void)pushLogToWebSocketClients:(LLWLogEntry *)entry {
    if (self.websocketConnections.count == 0) {
        return;  // 没有客户端连接
    }
    
    // 转换为 JSON
    NSString *jsonString = [self entryToJSON:entry];
    if (!jsonString) {
        return;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 发送到所有 WebSocket 连接
    for (LLWWebSocketConnection *connection in self.websocketConnections) {
        if (!connection.isClosed && connection.isWebSocket) {
            [connection sendData:jsonData];
        }
    }
}

/**
 * 将日志条目转换为 JSON 字符串
 */
- (NSString *)entryToJSON:(LLWLogEntry *)entry {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM-dd'T'HH:mm:ss.SSSZ";
    
    NSDictionary *dict = @{
        @"level": @(entry.level),
        @"levelStr": [self levelNumberToString:entry.level],
        @"message": entry.message,
        @"tag": entry.tag ?: @"Unknown",
        @"timestamp": [dateFormatter stringFromDate:[NSDate date]]
    };
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (error) {
        NSLog(@"❌ [LogWebSDK] Failed to serialize log entry to JSON: %@", error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 * 日志级别数字转字符串
 */
- (NSString *)levelNumberToString:(NSInteger)level {
    switch (level) {
        case 0: return @"VERBOSE";
        case 1: return @"DEBUG";
        case 2: return @"INFO";
        case 3: return @"WARNING";
        case 4: return @"ERROR";
        default: return @"UNKNOWN";
    }
}

#pragma mark - Private Methods

- (void)registerDefaultRoutes {
    // GET / - 返回日志查看器页面
    [self registerGETPath:@"/" handler:^void(NSDictionary *queryParams, NSDictionary *headers, void (^responseCallback)(NSInteger, NSString *, NSString *)) {
        NSString *htmlPath = nil;
        
        // LogViewer.html 在 LogWebSDK.bundle 根目录
        NSBundle *sdkBundle = [NSBundle bundleForClass:[self class]];
        NSString *resourceBundlePath = [sdkBundle pathForResource:@"LogWebSDK" ofType:@"bundle"];
        NSBundle *resourceBundle = [NSBundle bundleWithPath:resourceBundlePath];
        NSString *bundlePath = [resourceBundle pathForResource:@"LogViewer" ofType:@"html"];
        if (bundlePath && [[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
            htmlPath = bundlePath;
        }
        
        NSString *html = nil;
        if (htmlPath) {
            html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
        } else {
            NSLog(@"⚠️ [LogWebSDK] Warning: LogViewer.html not found in any location!");
        }
        
        responseCallback(200, @"text/html", html ?: @"<h1>LogWebSDK</h1><p>Log viewer not found</p>");
    }];
    
    // POST /clear - 清空日志
    [self registerPOSTPath:@"/clear" handler:^(NSDictionary *queryParams, NSDictionary *headers, void (^responseCallback)(NSInteger, NSString *, NSString *) ) {
        responseCallback(200, @"application/json", @"{\"success\":true}");
    }];
}

#pragma mark - Log Push

- (void)pushLogToClients:(LLWLogEntry *)entry {
    if (self.websocketConnections.count == 0) {
        return;
    }
    
    NSString *jsonString = [self entryToJSON:entry];
    if (!jsonString) {
        return;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    for (LLWWebSocketConnection *connection in self.websocketConnections) {
        if (!connection.isClosed && connection.isWebSocket) {
            [connection sendData:jsonData];
        }
    }
}

@end

#pragma mark - CFSocket Callback

static void llw_socketCallback(CFSocketRef s, CFSocketCallBackType type, const CFDataRef address, const void *data, void *info) {
    if (type == kCFSocketAcceptCallBack) {
        LLWLogWebServer *server = (__bridge LLWLogWebServer *)info;
        int newSocket = *((int *)data);
        
        dispatch_async(server.serverQueue, ^{
            // 创建连接对象
            LLWWebSocketConnection *connection = [[LLWWebSocketConnection alloc] initWithSocket:newSocket server:server];
            
            // 添加到连接列表（必须在主线程）
            dispatch_async(dispatch_get_main_queue(), ^{
                [server.websocketConnections addObject:connection];
            });
            
            // 启动读取流程（开始监视 socket 可读事件）
            [connection startReading];
        });
    }
}
