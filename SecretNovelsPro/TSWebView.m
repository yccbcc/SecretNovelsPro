//
//  TSWebView.m
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2019/9/2.
//  Copyright © 2019 zhaohongbin. All rights reserved.
//

#import "TSWebView.h"

@implementation TSWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration{
    if (self = [super initWithFrame:frame configuration:configuration]) {
        [self createMenu];
    }
    return self;
}

//构建UIMenuController
//新添加的菜单
- (void)createMenu {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    UIMenuItem *item0 = [[UIMenuItem alloc] initWithTitle:@"复制2" action:@selector(haha:)];
    [menu setMenuItems:@[item0]];
}
//决定展示哪个菜单
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action ==@selector(copy:) || action == @selector(selectAll:) || action == @selector(paste:) || action == @selector(haha:)) {
        return YES;
    }
    return NO;
}

//自定义菜单按钮的执行方法
- (void)haha:(id)sender{
    
    //有问题,会获得上一次的选中信息
//    [self copy:sender];
//    NSLog(@"%@",[UIPasteboard generalPasteboard].string);
    
    [self evaluateJavaScript:@"window.getSelection().toString()" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"%@",result);
    }];
}

- (void)showWeb{
    self.hidden = NO;
    if ([self canBecomeFirstResponder]) {
        [self becomeFirstResponder];
    }
}
- (void)hideWeb{
    self.hidden = YES;
    if ([self canResignFirstResponder]) {
        [self resignFirstResponder];
    }
}

/**
 
 //    @protocol UIResponderStandardEditActions <NSObject>
 //    @optional
 //    - (void)cut:(nullable id)sender NS_AVAILABLE_IOS(3_0); //剪切
 //    - (void)copy:(nullable id)sender NS_AVAILABLE_IOS(3_0); //复制
 //    - (void)paste:(nullable id)sender NS_AVAILABLE_IOS(3_0); //粘贴
 //    - (void)select:(nullable id)sender NS_AVAILABLE_IOS(3_0); //选择
 //    - (void)selectAll:(nullable id)sender NS_AVAILABLE_IOS(3_0); //全选
 //    - (void)delete:(nullable id)sender NS_AVAILABLE_IOS(3_2);    //删除
 //    - (void)makeTextWritingDirectionLeftToRight:(nullable id)sender NS_AVAILABLE_IOS(5_0); //改变书写模式为从左向右按钮触发
 //    - (void)makeTextWritingDirectionRightToLeft:(nullable id)sender NS_AVAILABLE_IOS(5_0); //改变书写模式为从右向左按钮触发
 
 ————————————————
 版权声明：本文为CSDN博主「唐云T_yun」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
 原文链接：https://blog.csdn.net/xmy0010/article/details/52945689
 
 */

@end
