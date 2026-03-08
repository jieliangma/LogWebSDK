//
//  Example - ViewController.m
//  LogWebSDK Example
//
//  演示各种级别的日志输出
//

#import "ViewController.h"
#import <LogWebSDK/LogWebSDK.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

// 设置日志级别
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface ViewController ()
@property (nonatomic, strong) UITextView *accessTextView;  // 用 UITextView 支持长按复制
@property (nonatomic, strong) UIStackView *buttonStack;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    self.title = @"LogWebSDK Example";
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refreshAccessURL];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 标题标签
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = @"📊 LogWebSDK";
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:titleLabel];

    // 访问地址（UITextView：可选中文本，支持原生长按复制）
    self.accessTextView = [UITextView new];
    self.accessTextView.editable = NO;
    self.accessTextView.scrollEnabled = NO;
    self.accessTextView.textAlignment = NSTextAlignmentCenter;
    if (@available(iOS 13.0, *)) {
        self.accessTextView.font = [UIFont monospacedSystemFontOfSize:15 weight:UIFontWeightRegular];
    } else {
        self.accessTextView.font = [UIFont fontWithName:@"Courier" size:15];
    }
    self.accessTextView.textColor = [UIColor systemBlueColor];
    self.accessTextView.backgroundColor = [UIColor clearColor];
    self.accessTextView.text = @"获取访问地址中...";
    self.accessTextView.dataDetectorTypes = UIDataDetectorTypeLink;  // 链接可点击
    self.accessTextView.translatesAutoresizingMaskIntoConstraints = NO;
    // 去除 UITextView 默认内边距，使其与 UILabel 对齐一致
    self.accessTextView.textContainerInset = UIEdgeInsetsZero;
    self.accessTextView.textContainer.lineFragmentPadding = 0;
    [self.view addSubview:self.accessTextView];

    // 分割线
    UIView *separator = [UIView new];
    if (@available(iOS 13.0, *)) {
        separator.backgroundColor = [UIColor separatorColor];
    } else {
        separator.backgroundColor = [UIColor colorWithRed:0.24 green:0.24 blue:0.26 alpha:0.29];
    }
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:separator];

    // 说明标签
    UILabel *hintLabel = [UILabel new];
    hintLabel.text = @"点击下方按钮生成各级别日志：";
    hintLabel.font = [UIFont systemFontOfSize:14];
    if (@available(iOS 13.0, *)) {
        hintLabel.textColor = [UIColor secondaryLabelColor];
    } else {
        hintLabel.textColor = [UIColor grayColor];
    }
    hintLabel.textAlignment = NSTextAlignmentCenter;
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hintLabel];

    // 按钮栈
    self.buttonStack = [[UIStackView alloc] init];
    self.buttonStack.axis = UILayoutConstraintAxisVertical;
    self.buttonStack.spacing = 12;
    self.buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.buttonStack];

    NSArray *configs = @[
        @{@"title": @"Verbose", @"color": [UIColor systemGrayColor],   @"sel": @"logVerbose"},
        @{@"title": @"Debug",   @"color": [UIColor systemTealColor],   @"sel": @"logDebug"},
        @{@"title": @"Info",    @"color": [UIColor systemGreenColor],  @"sel": @"logInfo"},
        @{@"title": @"Warning", @"color": [UIColor systemOrangeColor], @"sel": @"logWarning"},
        @{@"title": @"Error",   @"color": [UIColor systemRedColor],    @"sel": @"logError"},
    ];

    for (NSDictionary *cfg in configs) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:cfg[@"title"] forState:UIControlStateNormal];
        btn.tintColor = cfg[@"color"];
        btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        btn.backgroundColor = [((UIColor *)cfg[@"color"]) colorWithAlphaComponent:0.1];
        btn.layer.cornerRadius = 10;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = ((UIColor *)cfg[@"color"]).CGColor;
        [btn addTarget:self action:NSSelectorFromString(cfg[@"sel"]) forControlEvents:UIControlEventTouchUpInside];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn.heightAnchor constraintEqualToConstant:48].active = YES;
        [self.buttonStack addArrangedSubview:btn];
    }

    // Auto Layout
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.accessTextView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:16],
        [self.accessTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.accessTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [separator.topAnchor constraintEqualToAnchor:self.accessTextView.bottomAnchor constant:20],
        [separator.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [separator.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [separator.heightAnchor constraintEqualToConstant:0.5],

        [hintLabel.topAnchor constraintEqualToAnchor:separator.bottomAnchor constant:16],
        [hintLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [hintLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.buttonStack.topAnchor constraintEqualToAnchor:hintLabel.bottomAnchor constant:16],
        [self.buttonStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.buttonStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
    ]];
}

#pragma mark - IP Address

- (NSString *)wifiIPAddress {
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    if (getifaddrs(&interfaces) == 0) {
        struct ifaddrs *temp = interfaces;
        while (temp != NULL) {
            if (temp->ifa_addr != NULL &&
                temp->ifa_addr->sa_family == AF_INET &&
                strcmp(temp->ifa_name, "en0") == 0) {
                address = [NSString stringWithUTF8String:
                           inet_ntoa(((struct sockaddr_in *)temp->ifa_addr)->sin_addr)];
                break;
            }
            temp = temp->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

- (void)refreshAccessURL {
    NSString *ip = [self wifiIPAddress];
    NSInteger port = [[LogWebSDK configuration][@"port"] integerValue] ?: 8080;
    if (ip) {
        NSString *url = [NSString stringWithFormat:@"http://%@:%ld", ip, (long)port];
        self.accessTextView.text = [NSString stringWithFormat:@"在局域网浏览器访问：\n%@", url];
        self.accessTextView.textColor = [UIColor systemBlueColor];
    } else {
        self.accessTextView.text = @"⚠️ 未连接 WiFi\n请连接后重新打开 App";
        self.accessTextView.textColor = [UIColor systemOrangeColor];
    }
}

#pragma mark - Button Actions

- (void)logVerbose {
    DDLogVerbose(@"User clicked verbose button - timestamp: %@", [NSDate date]);
}

- (void)logDebug {
    DDLogDebug(@"Button pressed - memory usage: %lu MB",
               (unsigned long)([[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024));
}

- (void)logInfo {
    DDLogInfo(@"Application state changed to active");
}

- (void)logWarning {
    DDLogWarn(@"Network connection unstable - signal strength: weak");
}

- (void)logError {
    DDLogError(@"Failed to load data from server - error code: 500");
}

@end
