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
        if (_leftTf.text.length > 0 && _rightTf.text.length > 0) {
            
            _textView.text = [_textView.text stringByReplacingOccurrencesOfString:_leftTf.text withString:_rightTf.text];
            NSArray *otherChars = @[@" ",@"  ",@"   ",@"    ",@"     ",@"\n",@"\n\n",@"\n\n\n",@"　",@"　　",@"　　　",@"\n  ",@"\n　",@"\n　　",@"\n　　　",@"\n　　　　",@"\n\n　",@"\n\n　　",@"\n\n　　　",@"\n\n　　　　",@"\n\n\n　",@"\n\n\n　　",@"\n\n\n　　　",@"\n\n\n　　　　"];
            for (int i = 1; i < _leftTf.text.length; i++) {
                for (NSString *oneChar in otherChars) {
                    NSMutableString *str = [_leftTf.text mutableCopy];
                    [str insertString:oneChar atIndex:i];
                    _textView.text = [_textView.text stringByReplacingOccurrencesOfString:str withString:_rightTf.text];
                }
            }
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField endEditing:YES];
    return YES;
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
        TSWebView *wkWeb = [[TSWebView alloc] initWithFrame:CGRectMake(0, statusBarHeight + 50, [UIScreen mainScreen].bounds.size.width, _bgBtn.frame.size.height - (statusBarHeight + 50)) configuration:[[WKWebViewConfiguration alloc] init]];
        [wkWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
        wkWeb.tag = 123;
        wkWeb.UIDelegate = self;
        wkWeb.navigationDelegate = self;
        _wkWeb = wkWeb;
        [_bgBtn addSubview:wkWeb];
    }
    [_wkWeb showWeb];
}

- (void)createUI{
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(50, statusBarHeight, 140, 40)];
    tf.placeholder = @"请输入";
    tf.returnKeyType = UIReturnKeyDone;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.delegate = self;
    [self.view addSubview:tf];
    _nameTf = tf;
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(200, statusBarHeight, 50, 40)];
    [btn2 addTarget:self action:@selector(refreshClick) forControlEvents:UIControlEventTouchUpInside];
    [btn2 setTitle:@"更新" forState:UIControlStateNormal];
    [btn2 setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    btn2.backgroundColor = [UIColor blueColor];
    [self.view addSubview:btn2];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(260, statusBarHeight, 50, 40)];
    [btn addTarget:self action:@selector(fetchClick) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"获取" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    btn.backgroundColor = [UIColor blueColor];
    [self.view addSubview:btn];
    
    UIButton *saveToFileBtn = [[UIButton alloc] initWithFrame:CGRectMake(320, statusBarHeight, 50, 40)];
    [saveToFileBtn addTarget:self action:@selector(saveToFileClick) forControlEvents:UIControlEventTouchUpInside];
    [saveToFileBtn setTitle:@"toFile" forState:UIControlStateNormal];
    [saveToFileBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    saveToFileBtn.backgroundColor = [UIColor blueColor];
    [self.view addSubview:saveToFileBtn];
    
    UITextField *tf1 = [[UITextField alloc] initWithFrame:CGRectMake(50, statusBarHeight + 50, 100, 40)];
    tf1.placeholder = @"检索";
    tf1.returnKeyType = UIReturnKeyDone;
    tf1.borderStyle = UITextBorderStyleRoundedRect;
    tf1.delegate = self;
    [self.view addSubview:tf1];
    _leftTf = tf1;
    
    UIButton *searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(155, statusBarHeight + 50, 60, 40)];
    [searchBtn addTarget:self action:@selector(searchClick) forControlEvents:UIControlEventTouchUpInside];
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    searchBtn.backgroundColor=UIColor.blueColor;
    [searchBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    [self.view addSubview:searchBtn];
    
    UITextField *tf2 = [[UITextField alloc] initWithFrame:CGRectMake(220, statusBarHeight + 50, 100, 40)];
    tf2.placeholder = @"替换";
    tf2.returnKeyType = UIReturnKeyDone;
    tf2.borderStyle = UITextBorderStyleRoundedRect;
    tf2.delegate = self;
    [self.view addSubview:tf2];
    _rightTf = tf2;
    
    UIButton *webBtn = [[UIButton alloc] initWithFrame:CGRectMake(330, statusBarHeight + 50, 40, 40)];
    [webBtn addTarget:self action:@selector(webClick) forControlEvents:UIControlEventTouchUpInside];
    [webBtn setTitle:@"Web" forState:UIControlStateNormal];
    webBtn.backgroundColor=UIColor.blueColor;
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
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
       
        [btn addTarget:self action:@selector(removeReader) forControlEvents:UIControlEventTouchUpInside];
        [[UIApplication sharedApplication].delegate.window addSubview:btn];
        
        UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, statusBarHeight, 80, 50)];
        backBtn.tag = 200;
        backBtn.backgroundColor = [UIColor colorWithRed:1.00f green:0.99f blue:0.92f alpha:1.00f];
        [backBtn setTitle:@"上一页" forState:UIControlStateNormal];
        [backBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [backBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
        [backBtn addTarget:self action:@selector(directedClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn addSubview:backBtn];
        
        UIButton *nextBtn = [[UIButton alloc] initWithFrame:CGRectMake( btn.frame.size.width - 80, statusBarHeight, 80, 50)];
        nextBtn.tag = 201;
        [nextBtn setTitle:@"下一页" forState:UIControlStateNormal];
        [nextBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [nextBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
        nextBtn.backgroundColor = [UIColor colorWithRed:1.00f green:0.99f blue:0.92f alpha:1.00f];
        [nextBtn addTarget:self action:@selector(directedClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn addSubview:nextBtn];
        
        UIButton *copyBtn = [[UIButton alloc] initWithFrame:CGRectMake( btn.frame.size.width - 180, statusBarHeight, 80, 50)];
        copyBtn.tag = 202;
        [copyBtn setTitle:@"copy" forState:UIControlStateNormal];
        [copyBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [copyBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
        copyBtn.backgroundColor = [UIColor colorWithRed:1.00f green:0.99f blue:0.92f alpha:1.00f];
        [copyBtn addTarget:self action:@selector(copyClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn addSubview:copyBtn];
        
        _bgBtn = btn;
    }
    return _bgBtn;
}






@end
