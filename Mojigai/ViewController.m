//
//  ViewController.m
//  nameSaveDemo
//
//  Created by zhaohongbin on 2019/6/18.
//  Copyright © 2019 zhaohongbin. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "TSWebView.h"
#import "ReatTxtManager.h"
#import "HandleSystemFile.h"
#import "ReadViewController.h"
#import "ConvertVideoFormat.h"
#import "HTMLTextTool.h"
#import "TextReplaceManager.h"
#import "TSToast.h"

@interface ViewController ()
<
UITableViewDelegate,UITableViewDataSource,
UITextFieldDelegate,
UITextViewDelegate,
WKUIDelegate,WKNavigationDelegate,
UIScrollViewDelegate
>


@property (nonatomic, strong) UIButton *bgBtn;
@property (nonatomic, strong) TSWebView *wkWeb;
@property (nonatomic, strong) NSMutableArray<NSString *> *m3u8UrlArray;
@property (nonatomic, copy) NSString *pageHTMLString;


#define statusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height

@end

@implementation ViewController
{
    UITableView *_tv;
    NSMutableArray *_mArr;
    
    UITextField *_nameTf;
    UITextField *_leftTf;
    UITextField *_rightTf;
    
    UITextView *_textView;
    
    float _searchOffset;
    NSInteger _strCount;
    
    NSString *_resultString;  //加载的网页中的字符串
    
    HandleSystemFile *_handleManger;
}

/*
 info.plist -> Supports opening documents in place   会导致"共享"到app功能失效.
 UIDocument 保存/打开 "文件" 可能会用到这个 key
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _handleManger = [[HandleSystemFile alloc] init];
    _handleManger.controller = self;
    _searchOffset = 0.0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileNotification:) name:@"FileNotification" object:nil];
    [self createUI];
}

#pragma mark - 处理外部打开文件(File.app通过分享"文件"使用,本app打开本项目)
- (void)fileNotification:(NSNotification *)notifcation {
    NSDictionary *info = notifcation.userInfo;
    // fileName是文件名称、filePath是文件存储在本地的路径
    // jfkdfj123a.pdf
    NSString *fileName = [info objectForKey:@"fileName"];
    // /private/var/mobile/Containers/Data/Application/83643509-E90E-40A6-92EA-47A44B40CBBF/Documents/Inbox/jfkdfj123a.pdf
    NSString *filePath = [info objectForKey:@"filePath"];
    NSLog(@"fileName=%@  \nfilePath=%@", fileName, filePath);
    NSString *string = [ReatTxtManager readTxtWithPath:filePath txtName:fileName];
    if (!string) { //读取失败返回 nil：提示后不更新界面
        [TSToast show:@"文件读取失败"];
        return;
    }
    NSArray *names = [fileName componentsSeparatedByString:@"."];
    fileName = (names && names.count > 0) ? names.firstObject : fileName;
    _nameTf.text = fileName;
    _textView.text = string;
}

#pragma mark - 保存到"文件"app

- (void)saveToFileClick{
    if (_nameTf.text.length <= 0 || _textView.text.length <= 0) {
        return;
    }
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    filePath = [NSString stringWithFormat:@"%@/file_app",filePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExit = [fileManager fileExistsAtPath:filePath];
    if (!isExit) {
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    filePath = [filePath stringByAppendingPathComponent:_nameTf.text];
    if (![filePath hasSuffix:@".txt"]) {
        filePath = [NSString stringWithFormat:@"%@.txt",filePath];
    }
    
    [_textView.text writeToFile:filePath atomically:true encoding:NSUTF8StringEncoding error:nil];
    
    [HandleSystemFile shareInstance].controller = self;
    [[HandleSystemFile shareInstance] saveToFile:filePath];
}


#pragma mark - tableview代理
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _mArr.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"abc"];
    if (!cell) {
        cell= [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"abc"];
    }
    cell.textLabel.text = _mArr[indexPath.row][@"key"];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// 定义编辑样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

// 进入编辑模式，按下出现的编辑按钮后,进行删除操作
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [_mArr removeObjectAtIndex:indexPath.row];
        [[NSUserDefaults standardUserDefaults] setObject:_mArr forKey:@"names"];
        [tableView reloadData];
    }
}

// 修改编辑按钮文字
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

   NSString *key = _mArr[indexPath.row][@"key"];
    if ([key hasPrefix:@"http"]) {
        self.bgBtn.hidden = false;
        _bgBtn.tag = 1000 + indexPath.row;
        [self showWebView:_mArr[indexPath.row][@"key"]];
    }else{
        ReadViewController *vc = [[ReadViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{}];
        vc.row = (int)indexPath.row;
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:true completion:nil];
    }
}

#pragma mark - webviewdelegate
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    // 支持window.open(),需要打开新界面是,WKWebView的代理```WKUIDelegate```方法
    // 会拦截到window.open()事件. 只需要我们在在方法内进行处理
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    //获取所有的html(下载m3u8等仍用原始HTML)
    NSString *allHtml = @"document.documentElement.innerHTML";
    [webView evaluateJavaScript:allHtml completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result isKindOfClass:[NSString class]]) {
            self.pageHTMLString = result;
            //拿不到innerText时的兜底:用原始HTML过滤出文本
            if (self->_resultString.length == 0) {
                self->_resultString = [HTMLTextTool filterHTML:result];
            }
        }
    }];

    //复制按钮用:取页面可见文本,脚本/样式/隐藏元素会被自动排除
    [webView evaluateJavaScript:@"document.body.innerText" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result isKindOfClass:[NSString class]] && [(NSString *)result length] > 0) {
            self->_resultString = result;
        }
    }];
}

#pragma mark - textView代理

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if (textView != _textView) {
        return NO;
    }
    return YES;
}

#pragma mark - textField代理

- (void)textFieldDidEndEditing:(UITextField *)textField{

    if (textField == _rightTf){
        NSString *_leftText = _leftTf.text;
        NSString *_rightText = _rightTf.text.length > 0 ? _rightTf.text : [NSString stringWithFormat:@"%@改%@", @"张", @"生"];
        _rightText = [_rightText isEqualToString:@"2"] ? [NSString stringWithFormat:@"%@峰", @"云"] : _rightText;
        if (_leftText.length > 0) {
            // 替换规则见 TextReplaceManager
            _textView.text = [TextReplaceManager replaceText:_textView.text leftText:_leftText rightText:_rightText];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField endEditing:YES];
    return YES;
}


#pragma mark - 键盘

- (UIToolbar *)keyboardToolbar {
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIView *closeView = nil;
    if (@available(iOS 13.0, *)) {
        // 系统自带的半透明圆底 X 按钮
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeClose];
        [closeBtn addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
        closeView = closeBtn;
    } else {
        closeView = [self customCloseButton];
    }
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithCustomView:closeView];
    toolbar.items = @[flexItem, closeItem];
    return toolbar;
}

// iOS 12 及以下: 自绘半透明圆底 X 按钮
- (UIView *)customCloseButton {
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.12];
    btn.layer.cornerRadius = 14;
    [btn setTitle:@"✕" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRed:0.48 green:0.48 blue:0.48 alpha:1] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [btn addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - 事件

- (void)webClick{
    [self showWebView:@""];
}

- (void)searchClick{
    [self.view endEditing:YES];
    // 读取文件
    [HandleSystemFile shareInstance].controller = self;
    [[HandleSystemFile shareInstance] readFile];
    return;

    //原搜索功能 暂时屏蔽
    if (_textView.text.length <= _leftTf.text.length || _leftTf.text.length == 0) {
        return;
    }
    
    if (_strCount > _textView.text.length) {
        _strCount = 0;
    }
    
    NSRange range = [_textView.text rangeOfString:_leftTf.text options:NSCaseInsensitiveSearch range:NSMakeRange(_strCount,_textView.text.length - _strCount)];
    if (range.location != NSNotFound) {
        NSString *subStr = [_textView.text substringToIndex:range.location];
        float offsetY = [self sizeWithStr:subStr font:[UIFont systemFontOfSize:12] maxWidth:375 maxHeight:MAXFLOAT].height;
        _textView.contentOffset = CGPointMake(0, offsetY - 15);
        _strCount = range.location + 1;
    }else{
        if (_strCount == 0) {
            
        }else{
            _strCount = 0;
            range = [_textView.text rangeOfString:_leftTf.text options:NSCaseInsensitiveSearch range:NSMakeRange(_strCount,_textView.text.length - _strCount)];
            NSString *subStr = [_textView.text substringToIndex:range.location];
            float offsetY = [self sizeWithStr:subStr font:[UIFont systemFontOfSize:12] maxWidth:375 maxHeight:MAXFLOAT].height;
            _textView.contentOffset = CGPointMake(0, offsetY - 15);
            _strCount = range.location + 1;
        }
    }
}

- (void)fetchClick{
    if (_nameTf.text.length == 0) {
        return;
    }
    [self.view endEditing:YES];
    for (NSDictionary *dict in _mArr) {
        if ([dict[@"key"] isEqualToString:_nameTf.text]) {
            _textView.text = dict[@"value"];
        }
    }
}
- (void)saveClick{
    [self.view endEditing:YES];
    if (_nameTf.text.length > 0) {
        if ([_nameTf.text isEqualToString:@"0912"]) {
            _tv.hidden = NO;
            [_tv reloadData];
        }else{
            if (![_mArr containsObject:_nameTf.text]  && _textView.text.length > 0) {
                [_mArr addObject:@{@"key":_nameTf.text,@"value":_textView.text,@"offsety":@"0",@"readType":@"0"}];
                [[NSUserDefaults standardUserDefaults] setObject:_mArr forKey:@"names"];
            }
        }
        _nameTf.text = @"";
    }
}


- (void)backClick{
    _tv.hidden = YES;
}

//已经打开列表后的事件
- (void)copyClick:(UIButton *)btn{
    _textView.text = _resultString;
}

- (void)directedClick:(UIButton *)btn{
    if (_wkWeb.isHidden == NO) {
        if (btn.tag == 200) {
            if ([_wkWeb canGoBack]) {
                [_wkWeb goBack];
            }
        }else{
            if ([_wkWeb canGoForward]) {
                [_wkWeb goForward];
            }
        }
    }
}

- (void)reloadClick{
    [self.m3u8UrlArray removeAllObjects];
    [_wkWeb reload];
}

- (void)removeReader{
    [_wkWeb hideWeb];
    _bgBtn.hidden = YES;
    //        NSMutableDictionary *dict = [_mArr[_bgBtn.tag - 1000] mutableCopy];
    //        dict[@"offsety"] = [NSString stringWithFormat:@"%d",(int)_readTXTView.contentOffset.y];
    //        [_mArr removeObjectAtIndex:_bgBtn.tag - 1000];
    //        [_mArr insertObject:dict atIndex:_bgBtn.tag - 1000];
    //        [[NSUserDefaults standardUserDefaults] setObject:_mArr forKey:@"names"];
    //        _readTXTView.hidden = YES;
}


#pragma mark - tool

- (CGSize)sizeWithStr:(NSString *)str font:(UIFont *)font maxWidth:(CGFloat)width maxHeight:(CGFloat)height {
    NSMutableDictionary *attr = [NSMutableDictionary dictionary];
    CGSize maxSize = CGSizeMake(width, height);
    attr[NSFontAttributeName] = font;
    CGSize theSize = [str boundingRectWithSize:maxSize options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attr context:nil].size;
    return CGSizeMake(ceil(theSize.width), ceil(theSize.height));
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

#pragma mark - UI

- (void)showWebView:(NSString *)urlString{
    if(urlString.length == 0){
        if (!_wkWeb) return;
        _bgBtn.hidden = false;
        _tv.hidden = false;
        [_wkWeb showWeb];
        return;
    }

    if (_wkWeb) {
        [_wkWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    }else{
        __weak typeof(self) weakSelf = self;
        TSWebView *wkWeb = [[TSWebView alloc] initWithFrame:CGRectMake(0, statusBarHeight + 50, [UIScreen mainScreen].bounds.size.width, _bgBtn.frame.size.height - (statusBarHeight + 50)) configuration:[[WKWebViewConfiguration alloc] init]];
        [wkWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
        wkWeb.tag = 123;
        wkWeb.UIDelegate = self;
        wkWeb.navigationDelegate = self;
        wkWeb.onNetworkRequest = ^(TSNetworkRequestInfo *request) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            NSString *urlString = request.url;
            if ([urlString isKindOfClass:[NSString class]] &&
                [urlString containsString:@".m3u8"]) {
                if (!strongSelf.m3u8UrlArray) {
                    strongSelf.m3u8UrlArray = [NSMutableArray array];
                }
                if (![strongSelf.m3u8UrlArray containsObject:urlString]) {
                    [strongSelf.m3u8UrlArray addObject:urlString];
                    NSLog(@"捕获 m3u8: %@", urlString);
                }
            }
        };
        _wkWeb = wkWeb;
        [_bgBtn addSubview:wkWeb];
    }
    [_wkWeb showWeb];
}

// 统一样式的功能按钮(保存/获取/toFile/搜索/Web 共用)
- (UIButton *)standardButtonWithTitle:(NSString *)title action:(SEL)action frame:(CGRect)frame{
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    btn.backgroundColor = [UIColor blueColor];
    btn.layer.cornerRadius = 8;
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)createUI{
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat margin = 16;   // 左右边距(对称)
    CGFloat gap = 8;       // 组件间距
    CGFloat firstRowBtnW = (screenW - margin * 2 - 180 - gap * 3) / 3.0;
    CGFloat secondRowBtnW = (screenW - margin * 2 - 100 * 2 - gap * 3) / 2.0;
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(margin, statusBarHeight, 180, 40)];
    tf.placeholder = @"请输入";
    tf.returnKeyType = UIReturnKeyDone;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:14];
    tf.inputAccessoryView = [self keyboardToolbar];
    tf.delegate = self;
    [self.view addSubview:tf];
    _nameTf = tf;
    
    // 第一行按钮: 保存、获取、toFile
    NSArray *firstRowTitles  = @[@"保存", @"获取", @"toFile"];
    NSArray *firstRowActions = @[NSStringFromSelector(@selector(saveClick)),
                                 NSStringFromSelector(@selector(fetchClick)),
                                 NSStringFromSelector(@selector(saveToFileClick))];
    for (NSInteger i = 0; i < firstRowTitles.count; i++) {
        SEL action = NSSelectorFromString(firstRowActions[i]);
        CGRect frame = CGRectMake(margin + 180 + gap + i * (firstRowBtnW + gap), statusBarHeight, firstRowBtnW, 40);
        UIButton *btn = [self standardButtonWithTitle:firstRowTitles[i] action:action frame:frame];
        [self.view addSubview:btn];
    }
    
    UITextField *tf1 = [[UITextField alloc] initWithFrame:CGRectMake(margin, statusBarHeight + 50, 100, 40)];
    tf1.placeholder = @"检索";
    tf1.returnKeyType = UIReturnKeyDone;
    tf1.borderStyle = UITextBorderStyleRoundedRect;
    tf1.font = [UIFont systemFontOfSize:14];
    tf1.inputAccessoryView = [self keyboardToolbar];
    tf1.delegate = self;
    [self.view addSubview:tf1];
    _leftTf = tf1;
    
    UIButton *searchBtn = [self standardButtonWithTitle:@"搜索" action:@selector(searchClick) frame:CGRectMake(margin + 100 + gap, statusBarHeight + 50, secondRowBtnW, 40)];
    [self.view addSubview:searchBtn];
    
    UITextField *tf2 = [[UITextField alloc] initWithFrame:CGRectMake(margin + 100 + gap * 2 + secondRowBtnW, statusBarHeight + 50, 100, 40)];
    tf2.placeholder = @"替换";
    tf2.returnKeyType = UIReturnKeyDone;
    tf2.borderStyle = UITextBorderStyleRoundedRect;
    tf2.font = [UIFont systemFontOfSize:14];
    tf2.inputAccessoryView = [self keyboardToolbar];
    tf2.delegate = self;
    [self.view addSubview:tf2];
    _rightTf = tf2;
    
    UIButton *webBtn = [self standardButtonWithTitle:@"Web" action:@selector(webClick) frame:CGRectMake(margin + 200 + gap * 3 + secondRowBtnW, statusBarHeight + 50, secondRowBtnW, 40)];
    [self.view addSubview:webBtn];
    
    NSArray *arr = [[NSUserDefaults standardUserDefaults] valueForKey:@"names"];
    if (arr) {
        _mArr = [NSMutableArray arrayWithArray:arr];
    }else{
        _mArr = [@[] mutableCopy];
    }
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 100 + statusBarHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 100 - statusBarHeight - 34)];
    textView.delegate = self;
    textView.inputAccessoryView = [self keyboardToolbar];
    textView.font = [UIFont systemFontOfSize:12];
    textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    float linePading = textView.textContainer.lineFragmentPadding;
    textView.textContainerInset = UIEdgeInsetsMake(0, -linePading, 200, -linePading);
    [self.view addSubview:textView];
    _textView=textView;
    
    _tv = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 0) style:UITableViewStylePlain];
        tv.delegate = self;
        tv.dataSource = self;
        if (@available(iOS 11.0, *)) {
            tv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        } else {
            // Fallback on earlier versions
        }
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, tv.frame.size.width, 64)];
        btn.backgroundColor = [UIColor lightGrayColor];
        [btn setTitle:@"返回" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        tv.tableHeaderView = btn;
        [self.view addSubview:tv];
        tv.hidden = YES;
        tv;
    });
}

- (UIButton *)bgBtn{
    if(!_bgBtn){
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat space = 5;
        CGFloat btnW = (screenW - 5 * space) / 6.0;
        CGFloat btnH = 50.0;

        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, screenW, [UIScreen mainScreen].bounds.size.height)];
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        // 移除原来的 removeReader 背景点击事件
        [[UIApplication sharedApplication].delegate.window addSubview:btn];

        // 顺序：上一页、copy、下载、关闭、下一页、刷新
        NSArray *titles  = @[@"上一页", @"copy", @"下载", @"关闭", @"下一页", @"刷新"];
        NSArray *tags    = @[@200, @202, @203, @204, @201, @205];
        NSArray *actions = @[
            NSStringFromSelector(@selector(directedClick:)),
            NSStringFromSelector(@selector(copyClick:)),
            NSStringFromSelector(@selector(downloadClick:)),
            NSStringFromSelector(@selector(removeReader)),
            NSStringFromSelector(@selector(directedClick:)),
            NSStringFromSelector(@selector(reloadClick)),
        ];

        for (NSInteger i = 0; i < titles.count; i++) {
            UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(i * (btnW + space), statusBarHeight, btnW, btnH)];
            b.tag = [tags[i] integerValue];
            [b setTitle:titles[i] forState:UIControlStateNormal];
            [b setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
            [b setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
            b.titleLabel.font = [UIFont systemFontOfSize:14];
            b.titleLabel.adjustsFontSizeToFitWidth = YES;
            b.titleLabel.minimumScaleFactor = 0.8;
            b.backgroundColor = [UIColor colorWithRed:1.00f green:0.99f blue:0.92f alpha:1.00f];
            b.layer.cornerRadius = 6.0;
            b.clipsToBounds = YES;
            b.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 4);
            SEL sel = NSSelectorFromString(actions[i]);
            [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
            [btn addSubview:b];
        }

        _bgBtn = btn;
    }
    return _bgBtn;
}

- (void)downloadClick:(UIButton *)btn{
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
            // 点了某个 url：系统会自动关闭弹窗，然后走转换逻辑
            [self startConvertWithM3U8URL:urlString];
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


- (UIButton *)downloadButton{
    for (UIView *v in self.bgBtn.subviews) {
        if ([v isKindOfClass:[UIButton class]] && v.tag == 203) {
            return (UIButton *)v;
        }
    }
    return nil;
}

#pragma mark - 缓存清理

// 清理 Caches 里历次转换残留的 mp4。
// 背景:转换产物导出到"文件"App 是拷贝,本 app 中的副本不会自动删除,不清理会随每次下载一直堆积。
// 扩展提醒:将来若提供预览等视频缓存功能,若视频也存于 Caches 会被这里一并清掉;
// 届时请把转换产物改放独立子目录(如 Caches/VideoConvert/),将清理范围收窄到该目录。
- (void)removeOldCachedMP4Files{
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

- (void)startConvertWithM3U8URL:(NSString *)m3u8URLString{
    if (m3u8URLString.length == 0) {
        return;
    }
    // 新任务开始前,先清掉上次转换残留在 Caches 的 mp4(见 removeOldCachedMP4Files)
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
        // ffmpeg 回传的是已处理的毫秒数，不是百分比；这里用假进度推到 90% 封顶
        dispatch_async(dispatch_get_main_queue(), ^{
                if (fakeProgress < 90) {
                    fakeProgress += 3;
                    if (fakeProgress > 90) fakeProgress = 90;
                    [dlBtn setTitle:[NSString stringWithFormat:@"%ld%%", (long)fakeProgress] forState:UIControlStateNormal];
                }
            });
        } completion:^(BOOL success, NSURL *url, NSString *error) {
            // 无论成功失败，都从列表里移除这个 url
            [self.m3u8UrlArray removeObject:m3u8URLString];

            if (success) {
                NSLog(@"转换完成: %@", url.path);
                [dlBtn setTitle:@"100%" forState:UIControlStateNormal];
                [TSToast show:@"下载完成"];
                // 弹系统 Files 保存面板
                [HandleSystemFile shareInstance].controller = self;
                [[HandleSystemFile shareInstance] saveToFile:url.path];
                // 2 秒后按钮标题恢复成"下载"
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [dlBtn setTitle:@"下载" forState:UIControlStateNormal];
                });
            } else {
                NSLog(@"转换失败: %@", error);
                [dlBtn setTitle:@"下载" forState:UIControlStateNormal];
                [TSToast show:[NSString stringWithFormat:@"下载失败: %@", error ?: @"未知错误"]];
            }
        }
    ];
}






@end
