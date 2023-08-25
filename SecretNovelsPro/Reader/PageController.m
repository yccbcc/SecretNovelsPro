//
//  PageController.m
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import "PageController.h"

@interface PageController ()<UITextViewDelegate>

@end
#define statusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height

@implementation PageController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:1.00f green:0.97f blue:0.85f alpha:1.00f];;

    [self.view addSubview:[self createReadTextView]];
}

- (UITextView *)createReadTextView{
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, statusBarHeight + 50, [UIScreen mainScreen].bounds.size.width, self.view.frame.size.height - (statusBarHeight + 50))];
    textView.backgroundColor = [UIColor colorWithRed:1.00f green:0.97f blue:0.85f alpha:1.00f];;
    textView.delegate = self;
    //    _readTXTView = textView;
    //    _readTXTView.text = _mArr[row][@"value"];
    //    NSString *offsetY = _mArr[row][@"offsety"];
    //    if (offsetY) {
    //        _readTXTView.contentOffset = CGPointMake(0, offsetY.integerValue);
    //    }
    textView.text = self.content;
    _readTXTView = textView;
    return textView;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    return NO;
}


@end
