//
//  ViewController.m
//  nameSaveDemo
//
//  Created by zhaohongbin on 2019/6/18.
//  Copyright © 2019 zhaohongbin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UITextViewDelegate>

@end

@implementation ViewController
{
    UITableView *_tv;
    NSMutableArray *_mArr;
    
    UITextField *_tf;
    UITextField *_tf1;
    UITextField *_tf2;
    
    UITextView *_textView;
    
    float _searchOffset;
    NSInteger _strCount;
    NSString *_oriTF1Str;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _searchOffset = 0.0;
    _oriTF1Str = @"";
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(50, 20, 140, 40)];
    tf.placeholder = @"请输入";
    tf.returnKeyType = UIReturnKeyDone;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.delegate = self;
    [self.view addSubview:tf];
    _tf = tf;
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(200, 20, 50, 40)];
    [btn2 addTarget:self action:@selector(refreshClick) forControlEvents:UIControlEventTouchUpInside];
    [btn2 setTitle:@"更新" forState:UIControlStateNormal];
    [btn2 setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    btn2.backgroundColor = [UIColor blueColor];
    [self.view addSubview:btn2];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(260, 20, 50, 40)];
    [btn addTarget:self action:@selector(fetchClick) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"获取" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    btn.backgroundColor = [UIColor blueColor];
    [self.view addSubview:btn];
    
    UITextField *tf1 = [[UITextField alloc] initWithFrame:CGRectMake(50, 70, 100, 40)];
    tf1.placeholder = @"被替换";
    tf1.returnKeyType = UIReturnKeyDone;
    tf1.borderStyle = UITextBorderStyleRoundedRect;
    tf1.delegate = self;
    [self.view addSubview:tf1];
    _tf1 = tf1;
    
    UIButton *searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(155, 70, 60, 40)];
    [searchBtn addTarget:self action:@selector(searchClick) forControlEvents:UIControlEventTouchUpInside];
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    searchBtn.backgroundColor=UIColor.blueColor;
    [searchBtn setBackgroundImage:[UIImage imageNamed:@"redImage.png"] forState:UIControlStateHighlighted];
    [self.view addSubview:searchBtn];
    
    UITextField *tf2 = [[UITextField alloc] initWithFrame:CGRectMake(220, 70, 100, 40)];
    tf2.placeholder = @"替换者";
    tf2.returnKeyType = UIReturnKeyDone;
    tf2.borderStyle = UITextBorderStyleRoundedRect;
    tf2.delegate = self;
    [self.view addSubview:tf2];
    _tf2 = tf2;
    
    NSArray *arr = [[NSUserDefaults standardUserDefaults] valueForKey:@"names"];
    if (arr) {
        _mArr = [NSMutableArray arrayWithArray:arr];
    }else{
        _mArr = [@[] mutableCopy];
    }
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 120, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 120)];
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
        btn.backgroundColor = [UIColor grayColor];
        [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
        tv.tableHeaderView = btn;
        [self.view addSubview:tv];
        tv.hidden = YES;
        tv;
    });
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
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 375, [UIScreen mainScreen].bounds.size.height)];
    btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    btn.tag = 1000 + indexPath.row;
    [btn addTarget:self action:@selector(removeReader) forControlEvents:UIControlEventTouchUpInside];
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 50, 375, btn.frame.size.height - 50)];
    textView.tag = 123;
    textView.delegate = self;
    [btn addSubview:textView];
    [[UIApplication sharedApplication].delegate.window addSubview:btn];
    textView.text = _mArr[indexPath.row][@"value"];
    NSString *offsetY = _mArr[indexPath.row][@"offsety"];
    if (offsetY.integerValue != 0) {
        textView.contentOffset = CGPointMake(0, offsetY.integerValue);
    }
}
- (void)removeReader{
    for (UIView *btn in  [UIApplication sharedApplication].delegate.window.subviews) {
        if (btn.tag >= 1000) {
            UITextView *txtView = [btn viewWithTag:123];
            NSMutableDictionary *dict = [_mArr[btn.tag - 1000] mutableCopy];
            dict[@"offsety"] = [NSString stringWithFormat:@"%d",(int)txtView.contentOffset.y];
            [_mArr removeObjectAtIndex:btn.tag - 1000];
            [_mArr insertObject:dict atIndex:btn.tag - 1000];
            [[NSUserDefaults standardUserDefaults] setObject:_mArr forKey:@"names"];
            [btn removeFromSuperview];
        }
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if (textView != _textView) {
        return NO;
    }
    return YES;
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
