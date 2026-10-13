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
    
    BOOL _isFirstShowSuc;
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
    //获取所有的html
    NSString *allHtml = @"document.documentElement.innerHTML";
    //获取网页title
    NSString *htmlTitle = @"document.title";
    //获取网页的一个值
    NSString *htmlNum = @"document.getElementById('title').innerText";

    [webView evaluateJavaScript:allHtml completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result isKindOfClass:[NSString class]]) {
            self.pageHTMLString = result;
            self->_resultString = [self filterHTML2:result];
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
            
            // 按组合字符拆分左右文本
            NSMutableArray<NSString *> *leftChars = [NSMutableArray array];
            NSMutableArray<NSString *> *rightChars = [NSMutableArray array];
            [_leftText enumerateSubstringsInRange:NSMakeRange(0, _leftText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                [leftChars addObject:substring];
            }];
            [_rightText enumerateSubstringsInRange:NSMakeRange(0, _rightText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                [rightChars addObject:substring];
            }];
            
            // ===== 替换规则(示例中 .. 表示任意空白: 空格/全角空格/换行/制表符,\s 已包含) =====
            // 一、两边字数相同时(如左栏"abc"→右栏"xyz"):逐字对应替换,空白原样保留
            //   1. 空白容错:"abc"→"xyz"   "a..bc"→"x..yz"   "ab..c"→"xy..z"   "a..b..c"→"x..y..z"
            //   2. 尾字可缺:"a..b"→"x..yz"   "ab"→"xyz"
            //   3. 后缀级联:整条替换完后,再从第2个字符起继续替换后缀
            //      "bc"→"yz"   "b..c"→"y..z"   "abcbc"→"xyzyz"
            //      (4字左栏依次为 bcd→xyz、cd→yz;后缀至少留2个字且字符齐全,单独的"b"不动;2字左栏不级联)
            // 二、左栏比右栏长时(如左栏"abc"→右栏"yz"):右栏对齐左栏末尾,多出的开头字去掉
            //   1. 整段替换:"abc"→"yz"("a..b..c"→"yz",空白只容错不保留)
            //   2. 后缀级联:继续去掉开头字替换,直到后缀与右栏等长(后缀至少留2个字):"bc"→"yz"   "b..c"→"y..z"(等长后缀按逐字对应保留空白)
            //      (4字左栏为整条"abcd"→"yz",再后缀"bcd"→"yz"、"cd"→"yz";后缀要求字符齐全)
            // 三、其他情况(左栏比右栏短):无法对应,整段替换(匹配内容连同内部空白整体替换为右栏文本)
            
            // alignByChar:两边字数相同,逐字对应(保留空白);leftLonger:左栏更长,右栏对齐左栏末尾
            BOOL alignByChar = leftChars.count == rightChars.count && leftChars.count > 1;
            BOOL leftLonger = leftChars.count > rightChars.count;
            NSString *result = _textView.text;
            // 替换轮数:第0轮匹配整条,后面每轮去掉开头一个字(后缀至少留2个字,避免单字满篇误替换);
            // 等长时换到只剩2个字,左长右短时换到后缀与右栏等长,如"abc"→"yz"依次替换"abc"、"bc"
            NSUInteger lastStart = 0;
            if (alignByChar) {
                lastStart = leftChars.count - 2;
            } else if (leftLonger) {
                NSUInteger minLen = MAX(rightChars.count, 2);
                lastStart = leftChars.count > minLen ? leftChars.count - minLen : 0;
            }
            for (NSUInteger k = 0; k <= lastStart; k++) {
                // 本轮匹配左栏从第k个字开始的后缀;先长后短,避免长串被短后缀提前拆坏
                // oneToOne:本轮是否逐字等长对应(等长时保留空白,不等长整段替换只能丢弃空白)
                BOOL oneToOne = alignByChar || (leftChars.count - k == rightChars.count);
                NSMutableString *pattern = [NSMutableString string];
                for (NSUInteger i = k; i < leftChars.count; i++) {
                    if (i > k) {
                        // 字与字之间允许夹杂任意空白;需要保留空白时用捕获组,替换时好按位置回填
                        [pattern appendString:oneToOne ? @"(\\s*)" : @"\\s*"];
                    }
                    // 转义正则特殊字符,保证左栏内容按普通文字匹配
                    NSString *escapedChar = [NSRegularExpression escapedPatternForString:leftChars[i]];
                    if (k == 0 && alignByChar && i == leftChars.count - 1) {
                        // 整条匹配时最后一个字符可有可无,非捕获组包住以免拆开 emoji 等代理对,也不影响 $1..$n 编号
                        [pattern appendFormat:@"(?:%@)?", escapedChar];
                    } else {
                        [pattern appendString:escapedChar];
                    }
                }
                
                // 替换模板:逐字对应时取右栏同位置字符,否则整段用完整右栏文本
                // tStart:左栏更长时每轮都替换成完整右栏(从右栏第1个字取起),其余情况从第k个字取起
                NSUInteger tStart = leftLonger ? 0 : k;
                NSMutableString *template = [NSMutableString string];
                for (NSUInteger i = tStart; i < rightChars.count; i++) {
                    if (i > tStart && oneToOne) {
                        // $n 对应本次匹配第 n-1 和第 n 个字符之间捕获到的空白
                        [template appendFormat:@"$%lu", (unsigned long)(i - tStart)];
                    }
                    // 替换文本中的 \ 和 $ 需要转义,避免被当成模板占位符
                    NSString *oneChar = [rightChars[i] stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
                    oneChar = [oneChar stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
                    [template appendString:oneChar];
                }
                
                // 执行本轮替换,结果作为下一轮的输入继续替换
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
                if (regex) {
                    result = [regex stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:template];
                }
            }
            _textView.text = result;
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
    
//    [HandleSystemFile shareInstance].controller = self;
//    [[HandleSystemFile shareInstance] readFile];
//    return;
    
    

    [self showWebView:@""];
}

- (void)searchClick{
    [self.view endEditing:YES];
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
- (void)refreshClick{
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

-(NSString *)filterHTML:(NSString *)html
{
    NSScanner * scanner = [NSScanner scannerWithString:html];
    NSString * text = nil;
    while([scanner isAtEnd]==NO)
    {
        //找到标签的起始位置
        [scanner scanUpToString:@"<" intoString:nil];
        //找到标签的结束位置
        [scanner scanUpToString:@">" intoString:&text];
        //替换字符
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>",text] withString:@""];
    }
//    NSString * regEx = @"<([^>]*)>";
//    html = [html stringByReplacingOccurrencesOfString:regEx withString:@""];
    return html;
}

- (NSString *)filterHTML2:(NSString *)html{
    NSString *content = html;
    NSRegularExpression *regularExpretion=[NSRegularExpression regularExpressionWithPattern:@"<[^>]*>|\n"  options:0  error:nil];
    
    //替换所有html和换行匹配元素为"-"
    content=[regularExpretion stringByReplacingMatchesInString:content options:NSMatchingReportProgress range:NSMakeRange(0, content.length) withTemplate:@"-"];
    
    regularExpretion=[NSRegularExpression regularExpressionWithPattern:@"-{1,}" options:0 error:nil] ;
    
    //把多个"-"匹配为一个"-"
    content=[regularExpretion stringByReplacingMatchesInString:content options:NSMatchingReportProgress range:NSMakeRange(0, content.length) withTemplate:@"-"];
    
    //根据"-"分割到数组
    NSArray *arr=[NSArray array];
    content=[NSString stringWithString:content];
    arr =  [content componentsSeparatedByString:@"-"];
    NSMutableArray *marr=[NSMutableArray arrayWithArray:arr];
    [marr removeObject:@""];
    return  [marr componentsJoinedByString:@"\n"];
}

#pragma mark - UI

- (void)showWebView:(NSString *)urlString{
    if(urlString.length == 0){
        if(!_isFirstShowSuc){
            if(_nameTf.text.length > 0 || _textView.text.length > 0){
                _tv.hidden = false;
                _isFirstShowSuc = true;
            }
        }else{
            _tv.hidden = false;
        }
        _bgBtn.hidden = false;
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
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(margin + 180 + gap, statusBarHeight, firstRowBtnW, 40)];
    [btn2 addTarget:self action:@selector(refreshClick) forControlEvents:UIControlEventTouchUpInside];
    [btn2 setTitle:@"更新" forState:UIControlStateNormal];
    [btn2 setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    btn2.backgroundColor = [UIColor blueColor];
    btn2.layer.cornerRadius = 8;
    btn2.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:btn2];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(margin + 180 + gap * 2 + firstRowBtnW, statusBarHeight, firstRowBtnW, 40)];
    [btn addTarget:self action:@selector(fetchClick) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"获取" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    btn.backgroundColor = [UIColor blueColor];
    btn.layer.cornerRadius = 8;
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    UIButton *saveToFileBtn = [[UIButton alloc] initWithFrame:CGRectMake(margin + 180 + gap * 3 + firstRowBtnW * 2, statusBarHeight, firstRowBtnW, 40)];
    [saveToFileBtn addTarget:self action:@selector(saveToFileClick) forControlEvents:UIControlEventTouchUpInside];
    [saveToFileBtn setTitle:@"toFile" forState:UIControlStateNormal];
    [saveToFileBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    saveToFileBtn.backgroundColor = [UIColor blueColor];
    saveToFileBtn.layer.cornerRadius = 8;
    saveToFileBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [saveToFileBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:saveToFileBtn];
    
    UITextField *tf1 = [[UITextField alloc] initWithFrame:CGRectMake(margin, statusBarHeight + 50, 100, 40)];
    tf1.placeholder = @"检索";
    tf1.returnKeyType = UIReturnKeyDone;
    tf1.borderStyle = UITextBorderStyleRoundedRect;
    tf1.font = [UIFont systemFontOfSize:14];
    tf1.inputAccessoryView = [self keyboardToolbar];
    tf1.delegate = self;
    [self.view addSubview:tf1];
    _leftTf = tf1;
    
    UIButton *searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(margin + 100 + gap, statusBarHeight + 50, secondRowBtnW, 40)];
    [searchBtn addTarget:self action:@selector(searchClick) forControlEvents:UIControlEventTouchUpInside];
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    searchBtn.backgroundColor=UIColor.blueColor;
    searchBtn.layer.cornerRadius = 8;
    searchBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [searchBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
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
    
    UIButton *webBtn = [[UIButton alloc] initWithFrame:CGRectMake(margin + 200 + gap * 3 + secondRowBtnW, statusBarHeight + 50, secondRowBtnW, 40)];
    [webBtn addTarget:self action:@selector(webClick) forControlEvents:UIControlEventTouchUpInside];
    [webBtn setTitle:@"Web" forState:UIControlStateNormal];
    webBtn.backgroundColor=UIColor.blueColor;
    webBtn.layer.cornerRadius = 8;
    webBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [webBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [webBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
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


#pragma mark - UI

- (UIButton *)bgBtn{
    if(!_bgBtn){
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat btnW = (screenW - 4 * 12) / 5.0;
        CGFloat btnH = 50.0;

        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, screenW, [UIScreen mainScreen].bounds.size.height)];
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        // 移除原来的 removeReader 背景点击事件
        [[UIApplication sharedApplication].delegate.window addSubview:btn];

        // 顺序：上一页、copy、下载、关闭、下一页
        NSArray *titles  = @[@"上一页", @"copy", @"下载", @"关闭", @"下一页"];
        NSArray *tags    = @[@200, @202, @203, @204, @201];
        NSArray *actions = @[
            NSStringFromSelector(@selector(directedClick:)),
            NSStringFromSelector(@selector(copyClick:)),
            NSStringFromSelector(@selector(downloadClick:)),
            NSStringFromSelector(@selector(removeReader)),
            NSStringFromSelector(@selector(directedClick:)),
        ];

        for (NSInteger i = 0; i < titles.count; i++) {
            UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(i * (btnW + 12), statusBarHeight, btnW, btnH)];
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
        NSError *regexError = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"src\\s*=\\s*[\"']([^\"']*\\.m3u8[^\"']*)[\"']"
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:&regexError];
        if (!regexError) {
            NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:self.pageHTMLString
                                                                      options:0
                                                                        range:NSMakeRange(0, self.pageHTMLString.length)];
            for (NSTextCheckingResult *match in matches) {
                if (match.numberOfRanges >= 2) {
                    NSString *src = [self.pageHTMLString substringWithRange:[match rangeAtIndex:1]];
                    // HTML 实体还原：&amp; -> & 等
                    src = [src stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                    src = [src stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
                    src = [src stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
                    src = [src stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
                    src = [src stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
                    if (src.length > 0 && ![self.m3u8UrlArray containsObject:src]) {
                        [self.m3u8UrlArray addObject:src];
                        NSLog(@"从 HTML 提取 m3u8 src: %@", src);
                    }
                }
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

- (void)showToast:(NSString *)message{
    if (message.length == 0) return;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 8;
    toast.clipsToBounds = YES;
    toast.font = [UIFont systemFontOfSize:14];
    toast.numberOfLines = 0;
    CGFloat maxW = [UIScreen mainScreen].bounds.size.width - 40;
    CGSize size = [message boundingRectWithSize:CGSizeMake(maxW, 100)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName: toast.font}
                                         context:nil].size;
    CGFloat w = size.width + 32;
    CGFloat h = size.height + 16;
    toast.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - w)/2,
                             CGRectGetHeight(window.bounds) - 180,
                             w, h);
    [window addSubview:toast];
    [UIView animateWithDuration:0.3 delay:1.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        toast.alpha = 0;
    } completion:^(BOOL finished) {
        [toast removeFromSuperview];
    }];
}

- (void)startConvertWithM3U8URL:(NSString *)m3u8URLString{
    if (m3u8URLString.length == 0) {
        return;
    }
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
    }
                                          completion:^(BOOL success, NSURL *url, NSString *error) {
        // 无论成功失败，都从列表里移除这个 url
        [self.m3u8UrlArray removeObject:m3u8URLString];

        if (success) {
            NSLog(@"转换完成: %@", url.path);
            [dlBtn setTitle:@"100%" forState:UIControlStateNormal];
            [self showToast:@"下载完成"];
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
            [self showToast:[NSString stringWithFormat:@"下载失败: %@", error ?: @"未知错误"]];
        }
    }];
}






@end
