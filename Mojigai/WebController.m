//
//  WebController.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/15.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "WebController.h"
#import <WebKit/WebKit.h>
#import "TSWebView.h"
#import "HTMLTextTool.h"
#import "ConvertVideoFormat.h"
#import "HandleSystemFile.h"
#import "VideoStore.h"
#import "TSToast.h"

@interface WebController () <WKUIDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) TSWebView *wkWeb;
@property (nonatomic, strong) NSMutableArray<NSString *> *m3u8UrlArray;
@property (nonatomic, copy) NSString *pageHTMLString;
@property (nonatomic, copy) NSString *resultString;
@end

@implementation WebController
{
    NSMutableArray *_controlBtns;
    UIView *_controlBar;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    // 顶部操作行:所有按钮放进一个容器 view,统一背景色
    _controlBtns = [NSMutableArray array];
    UIView *controlBar = [[UIView alloc] initWithFrame:CGRectZero];
    controlBar.backgroundColor = [UIColor colorWithRed:1.00f green:0.99f blue:0.92f alpha:1.00f];
    [self.view addSubview:controlBar];
    _controlBar = controlBar;

    NSArray *titles  = @[@"上一页", @"URL", @"主页", @"关闭", @"copy", @"下载", @"下一页"];
    NSArray *tags    = @[@200, @251, @252, @250, @202, @203, @201];
    NSArray *actions = @[
        NSStringFromSelector(@selector(directedClick:)),
        NSStringFromSelector(@selector(urlClick)),
        NSStringFromSelector(@selector(homeClick)),
        NSStringFromSelector(@selector(closeClick)),
        NSStringFromSelector(@selector(copyClick:)),
        NSStringFromSelector(@selector(downloadClick:)),
        NSStringFromSelector(@selector(directedClick:)),
    ];
    for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectZero];
        b.tag = [tags[i] integerValue];
        [b setTitle:titles[i] forState:UIControlStateNormal];
        [b setTitleColor:[UIColor colorWithRed:0.20f green:0.47f blue:0.98f alpha:1.00f] forState:UIControlStateNormal];
        [b setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [b setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
        b.titleLabel.font = [UIFont systemFontOfSize:13];
        b.titleLabel.adjustsFontSizeToFitWidth = YES;
        b.titleLabel.minimumScaleFactor = 0.8;
        b.backgroundColor = [UIColor clearColor];
        b.layer.cornerRadius = 8.0;
        b.clipsToBounds = YES;
        SEL sel = NSSelectorFromString(actions[i]);
        [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
        [controlBar addSubview:b];
        [_controlBtns addObject:b];
    }

    // 网页视图:位于顶部操作行之下
    __weak typeof(self) weakSelf = self;
    TSWebView *wkWeb = [[TSWebView alloc] initWithFrame:CGRectZero configuration:[[WKWebViewConfiguration alloc] init]];
    wkWeb.UIDelegate = self;
    wkWeb.navigationDelegate = self;
    wkWeb.onNetworkRequest = ^(TSNetworkRequestInfo *request) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        NSString *urlString = request.url;
        if ([urlString isKindOfClass:[NSString class]] && [urlString containsString:@".m3u8"]) {
            if (!strongSelf.m3u8UrlArray) {
                strongSelf.m3u8UrlArray = [NSMutableArray array];
            }
            if (![strongSelf.m3u8UrlArray containsObject:urlString]) {
                [strongSelf.m3u8UrlArray addObject:urlString];
                NSLog(@"捕获 m3u8: %@", urlString);
            }
        }
    };
    [self.view addSubview:wkWeb];
    _wkWeb = wkWeb;

    // 下拉刷新(替代被移除的「刷新」按钮)
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(reloadClick) forControlEvents:UIControlEventValueChanged];
    wkWeb.scrollView.refreshControl = refresh;

    // 右滑手势:有网页历史时优先返回网页上一页,没有才允许 pop 回主页
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    UIScreenEdgePanGestureRecognizer *edge = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgeSwipe:)];
    edge.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:edge];

    // 打开逻辑:优先加载传入的 URL;否则加载上次记住的 URL;都没有则空白页
    NSString *savedURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastWebURL"];
    if (self.initialURLString.length > 0) {
        [self loadURL:self.initialURLString];
    } else if (savedURL.length > 0) {
        [self loadURL:savedURL];
    }
}

// 隐藏导航栏,由操作行「关闭」返回
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - 右滑手势(网页返回优先)

// 系统右滑 pop 只有在网页没有上一页时才生效;有历史则让位给下面的边缘滑动
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        return ![self.wkWeb canGoBack];
    }
    return YES;
}

// 边缘滑动:有网页上一页则返回网页上一页,否则交给系统 pop
- (void)edgeSwipe:(UIScreenEdgePanGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateEnded || gr.state == UIGestureRecognizerStateRecognized) {
        if ([self.wkWeb canGoBack]) {
            [self.wkWeb goBack];
        }
    }
}

// 操作行放最上方,网页填满下方(含底部安全区)
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat barH = 50;
    CGFloat safeTop = self.view.safeAreaInsets.top;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;

    _controlBar.frame = CGRectMake(0, safeTop, w, barH);
    CGFloat space = 5;
    CGFloat btnW = (w - 6 * space) / 7.0;   // 7 个按钮(上一页/URL/主页/关闭/copy/下载/下一页)
    CGFloat btnH = barH - 12;
    for (NSInteger i = 0; i < _controlBtns.count; i++) {
        UIButton *b = _controlBtns[i];
        b.frame = CGRectMake(i * (btnW + space), (barH - btnH) / 2.0, btnW, btnH);
    }

    _wkWeb.frame = CGRectMake(0, safeTop + barH, w, h - safeTop - barH - safeBottom);
}

#pragma mark - 地址栏

// 加载地址并记住,供下次从主页进入时恢复
- (void)loadURL:(NSString *)urlString {
    urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (urlString.length == 0) {
        return;
    }
    // 无 scheme 时自动补 https://
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        urlString = [NSString stringWithFormat:@"https://%@", urlString];
    }
    [_wkWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:@"lastWebURL"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 顶部操作行事件

// 主页:打开 Google
- (void)homeClick {
    [self loadURL:@"https://www.google.com.hk"];
}

// 关闭 WebController(返回主页)
- (void)closeClick {
    [self.navigationController popViewControllerAnimated:YES];
}

// URL:弹窗输入网址(textview + 确定),网址有变化则加载新网址
- (void)urlClick {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入网址"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    // 占位空 textField,保留标准弹窗布局(不显示)
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.hidden = YES;
    }];

    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectZero];
    tv.layer.borderColor = [UIColor lightGrayColor].CGColor;
    tv.layer.borderWidth = 0.5;
    tv.layer.cornerRadius = 6;
    tv.font = [UIFont systemFontOfSize:14];
    tv.text = self.wkWeb.URL.absoluteString ?: @"";
    tv.tag = 901;
    [alert.view addSubview:tv];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        UITextView *input = (UITextView *)[alert.view viewWithTag:901];
        NSString *newURL = [input.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *current = strongSelf.wkWeb.URL.absoluteString ?: @"";
        // 去掉末尾斜杠再比较,只有真正变化才加载
        NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
        NSString *n1 = [newURL stringByTrimmingCharactersInSet:slash];
        NSString *n2 = [current stringByTrimmingCharactersInSet:slash];
        if (newURL.length > 0 && ![n1 isEqualToString:n2]) {
            [strongSelf loadURL:newURL];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        // 弹窗布局完成后,把 textView 覆盖到输入区并聚焦
        UITextView *input = (UITextView *)[alert.view viewWithTag:901];
        CGFloat tw = alert.view.bounds.size.width - 32;
        input.frame = CGRectMake(16, 60, tw, 64);
        [input becomeFirstResponder];
    }];
}

- (void)directedClick:(UIButton *)btn {
    if (btn.tag == 200) {
        if ([self.wkWeb canGoBack]) {
            [self.wkWeb goBack];
        }
    } else {
        if ([self.wkWeb canGoForward]) {
            [self.wkWeb goForward];
        }
    }
}

- (void)copyClick:(UIButton *)btn {
    if (self.resultString.length > 0) {
        [UIPasteboard generalPasteboard].string = self.resultString;
        [TSToast show:@"已复制"];
    } else {
        [TSToast show:@"暂无内容"];
    }
}

// 刷新(下拉刷新触发;同时清空捕获的 m3u8 列表)
- (void)reloadClick {
    [self.m3u8UrlArray removeAllObjects];
    [self.wkWeb reload];
}

// 刷新指示器收尾
- (void)endRefresh {
    UIRefreshControl *rc = self.wkWeb.scrollView.refreshControl;
    if (rc && rc.refreshing) {
        [rc endRefreshing];
    }
}

#pragma mark - 下载(m3u8 -> mp4)

// 递归查找指定 tag 的按钮(下载按钮在 _controlBar 容器内,不在 self.view 直接子视图里)
- (UIButton *)findButtonWithTag:(NSInteger)tag inView:(UIView *)view {
    for (UIView *v in view.subviews) {
        if ([v isKindOfClass:[UIButton class]] && v.tag == tag) {
            return (UIButton *)v;
        }
        UIButton *found = [self findButtonWithTag:tag inView:v];
        if (found) return found;
    }
    return nil;
}

- (UIButton *)downloadButton {
    return [self findButtonWithTag:203 inView:self.view];
}

- (void)downloadClick:(UIButton *)btn {
    // 先从当前网页原始 HTML 里正则提取 video/source 标签的 src（包含 .m3u8）
    if (self.pageHTMLString.length > 0) {
        if (!self.m3u8UrlArray) {
            self.m3u8UrlArray = [NSMutableArray array];
        }
        for (NSString *src in [HTMLTextTool extractM3U8URLsFromHTML:self.pageHTMLString]) {
            if (![self.m3u8UrlArray containsObject:src]) {
                [self.m3u8UrlArray addObject:src];
                NSLog(@"从 HTML 提取 m3u8 src: %@", src);
            }
        }
    }

    if (self.m3u8UrlArray.count == 0) {
        UIAlertController *tip = [UIAlertController alertControllerWithTitle:@"提示"
                                                                    message:@"暂未捕获到 m3u8 地址"
                                                             preferredStyle:UIAlertControllerStyleAlert];
        [tip addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:tip animated:YES completion:nil];
        return;
    }

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择要下载的 m3u8"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *urlString in self.m3u8UrlArray) {
        NSString *title = urlString;
        if (title.length > 40) {
            title = [NSString stringWithFormat:@"%@...", [urlString substringToIndex:37]];
        }
        UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            // 先选保存文件夹,再开始下载
            [self chooseFolderAndDownloadM3U8:urlString button:btn];
        }];
        [sheet addAction:action];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    // iPad 适配：actionSheet 必须指定 popover 锚点
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = btn;
        sheet.popoverPresentationController.sourceRect = btn.bounds;
    }

    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - 缓存清理

// 清理 Caches 里历次转换残留的 mp4。
- (void)removeOldCachedMP4Files {
    NSURL *cachesURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
    NSArray<NSURL *> *fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:cachesURL
                                                               includingPropertiesForKeys:nil
                                                                                  options:0
                                                                                    error:nil];
    for (NSURL *fileURL in fileURLs) {
        if ([fileURL.pathExtension.lowercaseString isEqualToString:@"mp4"]) {
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        }
    }
}

// 选好 m3u8 后:再让用户选择保存到 Documents/videos 下的哪个文件夹(默认 default)
- (void)chooseFolderAndDownloadM3U8:(NSString *)m3u8URLString button:(UIButton *)btn {
    NSArray<NSString *> *folders = [VideoStore folderNames];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择保存位置"
                                                                    message:@"保存到 Documents/videos 下的文件夹"
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *folder in folders) {
        NSString *title = folder;
        if ([folder isEqualToString:@"default"]) {
            title = @"default(默认)";
        }
        UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            [self startConvertWithM3U8URL:m3u8URLString targetFolder:folder];
        }];
        [sheet addAction:action];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    // iPad 适配:actionSheet 必须指定 popover 锚点
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = btn;
        sheet.popoverPresentationController.sourceRect = btn.bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)startConvertWithM3U8URL:(NSString *)m3u8URLString targetFolder:(NSString *)folderName {
    if (m3u8URLString.length == 0) {
        return;
    }
    [self removeOldCachedMP4Files];

    NSURL *outputURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *fileName = [NSString stringWithFormat:@"%.0f.mp4", [[NSDate date] timeIntervalSince1970]];
    outputURL = [outputURL URLByAppendingPathComponent:fileName];

    UIButton *dlBtn = [self downloadButton];
    [dlBtn setTitle:@"0%" forState:UIControlStateNormal];

    __block NSInteger fakeProgress = 0;
    [ConvertVideoFormat convertM3U8ToMP4WithInputURL:[NSURL URLWithString:m3u8URLString]
                                          outputURL:outputURL
                                            progress:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (fakeProgress < 90) {
                fakeProgress += 3;
                if (fakeProgress > 90) fakeProgress = 90;
                [dlBtn setTitle:[NSString stringWithFormat:@"%ld%%", (long)fakeProgress] forState:UIControlStateNormal];
            }
        });
    } completion:^(BOOL success, NSURL *url, NSString *error) {
        [self.m3u8UrlArray removeObject:m3u8URLString];

        if (success) {
            NSLog(@"转换完成: %@", url.path);
            // 复制到 Documents/videos/<folderName>,并清理 Caches 临时文件
            NSError *copyError = nil;
            NSString *targetDir = [VideoStore folderPath:folderName];
            NSString *stored = [VideoStore saveVideoFromURL:url intoDirectory:targetDir error:&copyError];
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            if (stored) {
                [dlBtn setTitle:@"100%" forState:UIControlStateNormal];
                [TSToast show:@"下载完成"];
            } else {
                [dlBtn setTitle:@"下载" forState:UIControlStateNormal];
                [TSToast show:[NSString stringWithFormat:@"保存失败: %@", copyError ?: @"未知错误"]];
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [dlBtn setTitle:@"下载" forState:UIControlStateNormal];
            });
        } else {
            NSLog(@"转换失败: %@", error);
            [dlBtn setTitle:@"下载" forState:UIControlStateNormal];
            [TSToast show:[NSString stringWithFormat:@"下载失败: %@", error ?: @"未知错误"]];
        }
    }];
}

#pragma mark - WKUIDelegate / WKNavigationDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self endRefresh];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self endRefresh];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self endRefresh];
    // 记住最新打开的网址(含页内点击跳转),供下次进入恢复
    if (navigation) {
        NSString *current = webView.URL.absoluteString;
        if (current.length > 0 && ([current hasPrefix:@"http://"] || [current hasPrefix:@"https://"])) {
            [[NSUserDefaults standardUserDefaults] setObject:current forKey:@"lastWebURL"];
        }
    }
    NSString *allHtml = @"document.documentElement.innerHTML";
    [webView evaluateJavaScript:allHtml completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result isKindOfClass:[NSString class]]) {
            self.pageHTMLString = result;
            if (self.resultString.length == 0) {
                self.resultString = [HTMLTextTool filterHTML:result];
            }
        }
    }];

    [webView evaluateJavaScript:@"document.body.innerText" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result isKindOfClass:[NSString class]] && [(NSString *)result length] > 0) {
            self.resultString = result;
        }
    }];
}

@end
