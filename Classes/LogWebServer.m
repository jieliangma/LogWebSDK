#import "LogWebServer.h"
#import <Network/Network.h>
#import <CommonCrypto/CommonCrypto.h>

static const uint8_t OPCODE_TEXT  = 0x1;
static const uint8_t OPCODE_CLOSE = 0x8;
static const uint8_t OPCODE_PING  = 0x9;

#pragma mark - LLWWebSocketConnection

@interface LLWWebSocketConnection : NSObject
@property (nonatomic, strong) nw_connection_t  nwConnection;
@property (nonatomic, assign) BOOL             isClosed;
@property (nonatomic, assign) BOOL             isWebSocket;
@property (nonatomic, weak)   LLWLogWebServer *server;
@property (nonatomic, strong) NSMutableData   *inputBuffer;
@property (nonatomic, strong) dispatch_queue_t connQueue;
- (instancetype)initWithNWConnection:(nw_connection_t)conn server:(LLWLogWebServer *)server;
- (void)start;
- (void)sendData:(NSData *)data;
- (void)close;
@end

@interface LLWLogWebServer ()
@property (nonatomic, strong) dispatch_queue_t serverQueue;
@property (nonatomic, strong) NSMutableArray<LLWWebSocketConnection *> *connections;
@property (nonatomic, strong) NSMutableDictionary<NSString *, LLWHTTPRequestHandler> *getRoutes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, LLWHTTPRequestHandler> *postRoutes;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) nw_listener_t listener;
@end

@implementation LLWWebSocketConnection

- (instancetype)initWithNWConnection:(nw_connection_t)conn server:(LLWLogWebServer *)server {
    if (self = [super init]) {
        _nwConnection = conn;
        _server       = server;
        _isClosed     = NO;
        _isWebSocket  = NO;
        _inputBuffer  = [NSMutableData data];
        _connQueue    = dispatch_queue_create("com.logweb.sdk.conn", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)start {
    nw_connection_t conn = self.nwConnection;
    __weak typeof(self) weak = self;
    nw_connection_set_state_changed_handler(conn, ^(nw_connection_state_t state,
                                                     nw_error_t _Nullable error) {
        if (state == nw_connection_state_ready) {
            [weak receiveNextData];
        } else if (state == nw_connection_state_failed ||
                   state == nw_connection_state_cancelled) {
            [weak close];
        }
    });
    nw_connection_set_queue(conn, self.connQueue);
    nw_connection_start(conn);
}

- (void)receiveNextData {
    if (self.isClosed) return;
    nw_connection_t conn = self.nwConnection;
    __weak typeof(self) weak = self;
    nw_connection_receive(conn, 1, 65536,
                          ^(dispatch_data_t content,
                            nw_content_context_t context,
                            bool is_complete,
                            nw_error_t error) {
        __strong typeof(self) strongSelf = weak;
        if (!strongSelf || strongSelf.isClosed) return;

        if (content) {
            dispatch_data_apply(content, ^bool(dispatch_data_t region,
                                               size_t offset,
                                               const void *buffer,
                                               size_t size) {
                [strongSelf.inputBuffer appendBytes:buffer length:size];
                return true;
            });

            if (!strongSelf.isWebSocket) {
                if ([strongSelf isHTTPRequestComplete]) {
                    [strongSelf processHTTPRequest];
                }
            } else {
                [strongSelf processWebSocketFrames];
            }
        }

        if (error || is_complete) {
            [strongSelf close];
            return;
        }
        [strongSelf receiveNextData];
    });
}

#pragma mark - HTTP

- (BOOL)isHTTPRequestComplete {
    return [self.inputBuffer rangeOfData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]
                                 options:0
                                   range:NSMakeRange(0, self.inputBuffer.length)].location != NSNotFound;
}

- (void)processHTTPRequest {
    NSString *request = [[NSString alloc] initWithData:self.inputBuffer encoding:NSUTF8StringEncoding];
    if (!request) { [self close]; return; }

    NSArray  *lines = [request componentsSeparatedByString:@"\r\n"];
    if (lines.count == 0) return;

    NSArray  *parts = [lines[0] componentsSeparatedByString:@" "];
    if (parts.count < 2) return;

    NSString *method = parts[0];
    NSString *path   = parts[1];

    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    for (NSUInteger i = 1; i < lines.count; i++) {
        NSString *line = lines[i];
        if (line.length == 0) break;
        NSRange r = [line rangeOfString:@":"];
        if (r.location != NSNotFound) {
            NSString *k = [[line substringToIndex:r.location]
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *v = [[line substringFromIndex:NSMaxRange(r)]
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            headers[k] = v;
        }
    }

    if ([method isEqualToString:@"GET"] &&
        [[headers[@"Upgrade"] lowercaseString] isEqualToString:@"websocket"]) {
        [self handleWebSocketHandshake:headers];
        return;
    }

    if ([method isEqualToString:@"GET"]) {
        LLWHTTPRequestHandler handler = self.server.getRoutes[path];
        if (handler) {
            handler(headers, ^(NSInteger code, NSString *ct, NSString *body) {
                [self sendHTTPResponse:code contentType:ct body:body ?: @""];
            });
        } else {
            [self sendHTTPResponse:404 contentType:@"text/plain" body:@"Not Found"];
        }
    } else if ([method isEqualToString:@"POST"]) {
        NSArray  *bodyParts = [request componentsSeparatedByString:@"\r\n\r\n"];
        NSString *reqBody   = bodyParts.count > 1 ? bodyParts[1] : @"";
        (void)reqBody;
        LLWHTTPRequestHandler handler = self.server.postRoutes[path];
        if (handler) {
            handler(headers, ^(NSInteger code, NSString *ct, NSString *responseBody) {
                [self sendHTTPResponse:code contentType:ct body:responseBody ?: @""];
            });
        } else {
            [self sendHTTPResponse:404 contentType:@"text/plain" body:@"Not Found"];
        }
    }
}

- (void)sendHTTPResponse:(NSInteger)code contentType:(NSString *)ct body:(NSString *)body {
    NSData   *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSString *status;
    switch (code) {
        case 200: status = @"OK"; break;
        case 400: status = @"Bad Request"; break;
        case 404: status = @"Not Found"; break;
        default:  status = @"Internal Server Error"; break;
    }
    NSString *header = [NSString stringWithFormat:
        @"HTTP/1.1 %ld %@\r\n"
        @"Content-Type: %@; charset=utf-8\r\n"
        @"Content-Length: %lu\r\n"
        @"Connection: close\r\n"
        @"\r\n",
        (long)code, status, ct, (unsigned long)bodyData.length];
    NSMutableData *resp = [NSMutableData dataWithData:[header dataUsingEncoding:NSUTF8StringEncoding]];
    [resp appendData:bodyData];
    [self nwSendData:resp isComplete:YES];
}

#pragma mark - WebSocket Handshake

- (void)handleWebSocketHandshake:(NSDictionary *)headers {
    NSString *key = headers[@"Sec-WebSocket-Key"];
    if (!key) { [self close]; return; }

    // RFC 6455 §1.3: Accept key = base64(SHA-1(key + magic))
    NSString *magic    = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    NSData   *combined = [[key stringByAppendingString:magic] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char sha1[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(combined.bytes, (CC_LONG)combined.length, sha1);
    NSString *accept = [[NSData dataWithBytes:sha1 length:CC_SHA1_DIGEST_LENGTH]
                        base64EncodedStringWithOptions:0];

    NSString *resp = [NSString stringWithFormat:
        @"HTTP/1.1 101 Switching Protocols\r\n"
        @"Upgrade: websocket\r\n"
        @"Connection: Upgrade\r\n"
        @"Sec-WebSocket-Accept: %@\r\n\r\n", accept];
    [self nwSendData:[resp dataUsingEncoding:NSUTF8StringEncoding] isComplete:NO];

    self.isWebSocket = YES;
    [self.inputBuffer setLength:0];
}

#pragma mark - WebSocket Frames

- (void)processWebSocketFrames {
    while (self.inputBuffer.length >= 2) {
        const uint8_t *b      = self.inputBuffer.bytes;
        uint8_t  opcode = b[0] & 0x0F;
        BOOL   hasMask  = (b[1] & 0x80) != 0;
        uint64_t payLen = b[1] & 0x7F;

        NSUInteger headerLen = 2;
        if (payLen == 126)      headerLen += 2;
        else if (payLen == 127) headerLen += 8;
        if (hasMask)            headerLen += 4;

        if (self.inputBuffer.length < headerLen) return;

        b = self.inputBuffer.bytes;
        if (payLen == 126) {
            uint16_t v; memcpy(&v, b + 2, 2); payLen = CFSwapInt16BigToHost(v);
        } else if (payLen == 127) {
            uint64_t v; memcpy(&v, b + 2, 8); payLen = CFSwapInt64BigToHost(v);
        }

        NSUInteger totalLen = headerLen + (NSUInteger)payLen;
        if (self.inputBuffer.length < totalLen) return;

        if      (opcode == OPCODE_PING)  { [self sendPong]; }
        else if (opcode == OPCODE_CLOSE) { [self close]; return; }

        [self.inputBuffer replaceBytesInRange:NSMakeRange(0, totalLen)
                                    withBytes:NULL length:0];
    }
}

- (void)sendPong {
    uint8_t pong[] = {0x8A, 0x00};
    [self nwSendData:[NSData dataWithBytes:pong length:2] isComplete:NO];
}

#pragma mark - Send

- (void)sendData:(NSData *)data {
    if (self.isClosed || !self.isWebSocket) return;

    NSMutableData *frame = [NSMutableData dataWithCapacity:data.length + 10];
    uint8_t fh = 0x80 | OPCODE_TEXT;
    [frame appendBytes:&fh length:1];

    uint64_t len = data.length;
    if (len < 126) {
        uint8_t l = (uint8_t)len; [frame appendBytes:&l length:1];
    } else if (len < 65536) {
        uint8_t l = 126;          [frame appendBytes:&l length:1];
        uint16_t l16 = CFSwapInt16HostToBig((uint16_t)len);
        [frame appendBytes:&l16 length:2];
    } else {
        uint8_t l = 127;          [frame appendBytes:&l length:1];
        uint64_t l64 = CFSwapInt64HostToBig(len);
        [frame appendBytes:&l64 length:8];
    }
    [frame appendData:data];
    [self nwSendData:frame isComplete:NO];
}

- (void)nwSendData:(NSData *)data isComplete:(BOOL)isComplete {
    if (self.isClosed) return;
    dispatch_data_t dispatchData = dispatch_data_create(data.bytes, data.length,
                                                        nil, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    nw_connection_t conn = self.nwConnection;
    __weak typeof(self) weak = self;
    nw_connection_send(conn, dispatchData, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, isComplete,
                       ^(nw_error_t error) {
        if (error) [weak close];
    });
}

- (void)close {
    if (_isClosed) return;
    _isClosed = YES;
    nw_connection_cancel(self.nwConnection);
    if (self.server) {
        LLWWebSocketConnection *me = self;
        dispatch_async(self.server.serverQueue, ^{
            [me.server.connections removeObject:me];
        });
    }
}

@end

#pragma mark - LLWLogWebServer

@implementation LLWLogWebServer

+ (instancetype)sharedInstance {
    static LLWLogWebServer *inst;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [LLWLogWebServer new]; });
    return inst;
}

- (instancetype)init {
    if (self = [super init]) {
        _port        = 8080;
        _getRoutes   = [NSMutableDictionary dictionary];
        _postRoutes  = [NSMutableDictionary dictionary];
        _connections = [NSMutableArray array];
        _serverQueue = dispatch_queue_create("com.logweb.sdk.server", DISPATCH_QUEUE_SERIAL);
        _listener    = nil;
        [self registerDefaultRoutes];
    }
    return self;
}

- (BOOL)startWithPort:(NSInteger)port error:(NSError **)error {
    if (self.isRunning) return YES;

    nw_parameters_t params = nw_parameters_create_secure_tcp(
        NW_PARAMETERS_DISABLE_PROTOCOL,
        NW_PARAMETERS_DEFAULT_CONFIGURATION);

    NSString *portStr = [NSString stringWithFormat:@"%ld", (long)port];
    nw_listener_t listener = nw_listener_create_with_port(portStr.UTF8String, params);
    if (!listener) {
        if (error) *error = [NSError errorWithDomain:@"LogWebSDK" code:1
                                            userInfo:@{NSLocalizedDescriptionKey: @"nw_listener_create failed"}];
        return NO;
    }

    self.listener = listener;
    __weak typeof(self) weak = self;

    nw_listener_set_new_connection_handler(listener, ^(nw_connection_t connection) {
        __strong typeof(self) strongSelf = weak;
        if (!strongSelf) { nw_connection_cancel(connection); return; }
        LLWWebSocketConnection *conn =
            [[LLWWebSocketConnection alloc] initWithNWConnection:connection server:strongSelf];
        dispatch_async(strongSelf.serverQueue, ^{
            [strongSelf.connections addObject:conn];
        });
        [conn start];
    });

    nw_listener_set_state_changed_handler(listener, ^(nw_listener_state_t state,
                                                       nw_error_t _Nullable err) {
        if (state == nw_listener_state_failed) {
            // 监听失败是需要关注的异常，保留此日志
            NSLog(@"[LogWebSDK] Listener failed: %@",
                  err ? (id)CFBridgingRelease(nw_error_copy_cf_error(err)) : @"unknown");
        }
    });

    nw_listener_set_queue(listener, self.serverQueue);
    nw_listener_start(listener);

    _running = YES;
    _port    = port;
    return YES;
}

- (void)stop {
    if (!self.isRunning) return;
    _running = NO;

    if (self.listener) {
        nw_listener_cancel(self.listener);
        self.listener = nil;
    }

    dispatch_async(self.serverQueue, ^{
        for (LLWWebSocketConnection *conn in [self.connections copy]) {
            [conn close];
        }
        [self.connections removeAllObjects];
    });
}

- (void)registerGETPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler {
    self.getRoutes[path] = handler;
}

- (void)registerPOSTPath:(NSString *)path handler:(LLWHTTPRequestHandler)handler {
    self.postRoutes[path] = handler;
}

#pragma mark - Log Push

- (void)pushLogToClients:(LLWLogEntry *)entry {
    dispatch_async(self.serverQueue, ^{
        if (self.connections.count == 0) return;
        NSData *json = [self entryToJSON:entry];
        if (!json) return;
        for (LLWWebSocketConnection *conn in [self.connections copy]) {
            if (!conn.isClosed && conn.isWebSocket) {
                [conn sendData:json];
            }
        }
    });
}

#pragma mark - Private

- (NSData *)entryToJSON:(LLWLogEntry *)entry {
    
    NSDictionary *d = @{
        @"level":     @(entry.level),
        @"message":   entry.message
    };
    NSError *err;
    NSData  *json = [NSJSONSerialization dataWithJSONObject:d options:0 error:&err];
#ifdef DEBUG
    if (err) NSLog(@"[LogWebSDK] JSON serialization error: %@", err);
#endif
    return json;
}

- (void)registerDefaultRoutes {
    [self registerGETPath:@"/" handler:^(NSDictionary *h, void(^cb)(NSInteger, NSString *, NSString *)) {
        NSBundle *sdkBundle      = [NSBundle bundleForClass:[LLWLogWebServer class]];
        NSString *bundlePath     = [sdkBundle pathForResource:@"LogWebSDK" ofType:@"bundle"];
        NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
        NSString *htmlPath       = [resourceBundle pathForResource:@"LogViewer" ofType:@"html"];
        NSError  *readError      = nil;
        NSString *html           = htmlPath ? [NSString stringWithContentsOfFile:htmlPath
                                                                         encoding:NSUTF8StringEncoding
                                                                            error:&readError] : nil;
#ifdef DEBUG
        if (!html) NSLog(@"[LogWebSDK] LogViewer.html not found: %@", readError);
#endif
        cb(200, @"text/html", html ?: @"<h1>LogWebSDK</h1>");
    }];

    [self registerPOSTPath:@"/clear" handler:^(NSDictionary *h, void(^cb)(NSInteger, NSString *, NSString *)) {
        cb(200, @"application/json", @"{\"success\":true}");
    }];
}

@end
