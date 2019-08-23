//
//  ViewController.m
//  nameSaveDemo
//
//  Created by zhaohongbin on 2019/6/18.
//  Copyright © 2019 zhaohongbin. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UITextViewDelegate,WKUIDelegate,WKNavigationDelegate>

#define statusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height

@end

@implementation ViewController
{
    UITableView *_tv;
    NSMutableArray *_mArr;
    
    UITextField *_tf;
    UITextField *_tf1;
    UITextField *_tf2;
    
    UITextView *_textView;
    
    UIButton *_bgBtn;
    WKWebView *_wkWeb;
    UITextView *_readTXTView;
    
    float _searchOffset;
    NSInteger _strCount;
    NSString *_oriTF1Str;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    _searchOffset = 0.0;
    _oriTF1Str = @"";
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(50, statusBarHeight, 140, 40)];
    tf.placeholder = @"请输入";
    tf.returnKeyType = UIReturnKeyDone;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.delegate = self;
    [self.view addSubview:tf];
    _tf = tf;
    
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
    
    UITextField *tf1 = [[UITextField alloc] initWithFrame:CGRectMake(50, statusBarHeight + 50, 100, 40)];
    tf1.placeholder = @"被替换";
    tf1.returnKeyType = UIReturnKeyDone;
    tf1.borderStyle = UITextBorderStyleRoundedRect;
    tf1.delegate = self;
    [self.view addSubview:tf1];
    _tf1 = tf1;
    
    UIButton *searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(155, statusBarHeight + 50, 60, 40)];
    [searchBtn addTarget:self action:@selector(searchClick) forControlEvents:UIControlEventTouchUpInside];
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    searchBtn.backgroundColor=UIColor.blueColor;
    [searchBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    [self.view addSubview:searchBtn];
    
    UITextField *tf2 = [[UITextField alloc] initWithFrame:CGRectMake(220, statusBarHeight + 50, 100, 40)];
    tf2.placeholder = @"替换者";
    tf2.returnKeyType = UIReturnKeyDone;
    tf2.borderStyle = UITextBorderStyleRoundedRect;
    tf2.delegate = self;
    [self.view addSubview:tf2];
    _tf2 = tf2;
    
    UIButton *webBtn = [[UIButton alloc] initWithFrame:CGRectMake(330, statusBarHeight + 50, 40, 40)];
    [webBtn addTarget:self action:@selector(showWebClick) forControlEvents:UIControlEventTouchUpInside];
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
        [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
        tv.tableHeaderView = btn;
        [self.view addSubview:tv];
        tv.hidden = YES;
        tv;
    });
}
- (void)showWebClick{
    if (_wkWeb && _bgBtn) {
        _bgBtn.hidden = NO;
        _wkWeb.hidden = NO;
    }
}

- (void)searchClick{
    [self.view endEditing:YES];
    if (_textView.text.length <= _tf1.text.length || _tf1.text.length == 0) {
        return;
    }
    
    if (_strCount > _textView.text.length) {
        _strCount = 0;
    }
    
    NSRange range = [_textView.text rangeOfString:_tf1.text options:NSCaseInsensitiveSearch range:NSMakeRange(_strCount,_textView.text.length - _strCount)];
    if (range.location != NSNotFound) {
        NSString *subStr = [_textView.text substringToIndex:range.location];
        float offsetY = [self sizeWithStr:subStr font:[UIFont systemFontOfSize:12] maxWidth:375 maxHeight:MAXFLOAT].height;
        _textView.contentOffset = CGPointMake(0, offsetY - 15);
        _strCount = range.location + 1;
    }else{
        if (_strCount == 0) {
            
        }else{
            _strCount = 0;
            range = [_textView.text rangeOfString:_tf1.text options:NSCaseInsensitiveSearch range:NSMakeRange(_strCount,_textView.text.length - _strCount)];
            NSString *subStr = [_textView.text substringToIndex:range.location];
            float offsetY = [self sizeWithStr:subStr font:[UIFont systemFontOfSize:12] maxWidth:375 maxHeight:MAXFLOAT].height;
            _textView.contentOffset = CGPointMake(0, offsetY - 15);
            _strCount = range.location + 1;
        }
    }
}

- (void)fetchClick{
    [self.view endEditing:YES];
    if (_tf.text.length == 0) {
        return;
    }
    for (NSDictionary *dict in _mArr) {
        if ([dict[@"key"] isEqualToString:_tf.text]) {
            _textView.text = dict[@"value"];
        }
    }
}
- (void)refreshClick{
    [self.view endEditing:YES];
    if (_tf.text.length > 0) {
        if ([_tf.text isEqualToString:@"0912"]) {
            _tv.hidden = NO;
            [_tv reloadData];
        }else{
            if (![_mArr containsObject:_tf.text]  && _textView.text.length > 0) {
                [_mArr addObject:@{@"key":_tf.text,@"value":_textView.text,@"offsety":@"0"}];
                [[NSUserDefaults standardUserDefaults] setObject:_mArr forKey:@"names"];
            }
        }
        _tf.text = @"";
    }
}


- (void)btnClick{
    _tv.hidden = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    
    if (textField == _tf1) {
        
        if ([_oriTF1Str isEqualToString:textField.text]) {
            return;
        }else{
            _oriTF1Str = textField.text;
            _strCount = 0;
        }
        
    }else if (textField == _tf2){
        if (_tf1.text.length > 0 && _tf2.text.length > 0) {
            
            _textView.text = [_textView.text stringByReplacingOccurrencesOfString:_tf1.text withString:_tf2.text];
            NSArray *otherChars = @[@" ",@"  ",@"   ",@"    ",@"     ",@"\n",@"\n\n",@"\n\n\n",@"　",@"　　",@"　　　",@"\n　",@"\n　　",@"\n　　　",@"\n　　　　",@"\n\n　",@"\n\n　　",@"\n\n　　　",@"\n\n　　　　"];
            for (int i = 1; i < _tf1.text.length; i++) {
                for (NSString *oneChar in otherChars) {
                    NSMutableString *str = [_tf1.text mutableCopy];
                    [str insertString:oneChar atIndex:i];
                    _textView.text = [_textView.text stringByReplacingOccurrencesOfString:_tf1.text withString:_tf2.text];
                }
            }
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField endEditing:YES];
    return YES;
}

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
    
    if (_bgBtn) {
        _bgBtn.hidden = NO;
    }else{
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
       
        [btn addTarget:self action:@selector(removeReader) forControlEvents:UIControlEventTouchUpInside];
        [[UIApplication sharedApplication].delegate.window addSubview:btn];
        _bgBtn = btn;
        
        UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, statusBarHeight, 80, 50)];
        backBtn.tag = 200;
        backBtn.backgroundColor = [UIColor colorWithRed:1.00f green:0.99f blue:0.92f alpha:1.00f];
        [backBtn setTitle:@"上一页" forState:UIControlStateNormal];
        [backBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(directedClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn addSubview:backBtn];
        
        UIButton *nextBtn = [[UIButton alloc] initWithFrame:CGRectMake( btn.frame.size.width - 80, statusBarHeight, 80, 50)];
        [nextBtn setTitle:@"下一页" forState:UIControlStateNormal];
        [nextBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        nextBtn.backgroundColor = [UIColor colorWithRed:1.00f green:0.99f blue:0.92f alpha:1.00f];
        [nextBtn addTarget:self action:@selector(directedClick:) forControlEvents:UIControlEventTouchUpInside];
        [btn addSubview:nextBtn];
    }
    _bgBtn.tag = 1000 + indexPath.row;

   NSString *key = _mArr[indexPath.row][@"key"];
    if ([key hasPrefix:@"http"]) {
        
        if (_wkWeb) {
            _wkWeb.hidden = NO;
            [_wkWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_mArr[indexPath.row][@"key"]]]];
        }else{
            WKWebView *wkWeb = [[WKWebView alloc] initWithFrame:CGRectMake(0, statusBarHeight + 50, [UIScreen mainScreen].bounds.size.width, _bgBtn.frame.size.height - (statusBarHeight + 50)) configuration:[[WKWebViewConfiguration alloc] init]];
            [wkWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_mArr[indexPath.row][@"key"]]]];
            wkWeb.tag = 123;
            wkWeb.UIDelegate = self;
            wkWeb.navigationDelegate = self;
            _wkWeb = wkWeb;
            [_bgBtn addSubview:wkWeb];
        }
    }else{

        if (_readTXTView) {
            _readTXTView.hidden = NO;
             _readTXTView.text = _mArr[indexPath.row][@"value"];
        }else{
            UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, statusBarHeight + 50, [UIScreen mainScreen].bounds.size.width, _bgBtn.frame.size.height - (statusBarHeight + 50))];
            textView.tag = 123;
            textView.delegate = self;
            [_bgBtn addSubview:textView];
            textView.text = _mArr[indexPath.row][@"value"];
            NSString *offsetY = _mArr[indexPath.row][@"offsety"];
            if (offsetY.integerValue != 0) {
                textView.contentOffset = CGPointMake(0, offsetY.integerValue);
            }
            _readTXTView = textView;
        }
    }
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
    
    NSString *key = _mArr[_bgBtn.tag - 1000][@"key"];
    if ([key hasPrefix:@"http"]) {
        _wkWeb.hidden = YES;
    }else{
        NSMutableDictionary *dict = [_mArr[_bgBtn.tag - 1000] mutableCopy];
        dict[@"offsety"] = [NSString stringWithFormat:@"%d",(int)_readTXTView.contentOffset.y];
        [_mArr removeObjectAtIndex:_bgBtn.tag - 1000];
        [_mArr insertObject:dict atIndex:_bgBtn.tag - 1000];
        [[NSUserDefaults standardUserDefaults] setObject:_mArr forKey:@"names"];
        _readTXTView.hidden = YES;
    }
    _bgBtn.hidden = YES;
    
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if (textView != _textView) {
        return NO;
    }
    return YES;
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
//    //获取所有的html
//    NSString *allHtml = @"document.documentElement.innerHTML";
//    //获取网页title
//    NSString *htmlTitle = @"document.title";
//    //获取网页的一个值
//    NSString *htmlNum = @"document.getElementById('title').innerText";
//
//    [webView evaluateJavaScript:allHtml completionHandler:^(id _Nullable result, NSError * _Nullable error) {
//        NSString *a = result;
//
//
//
//    }];
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

@end
