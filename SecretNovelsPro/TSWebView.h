//
//  TSWebView.h
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2019/9/2.
//  Copyright © 2019 zhaohongbin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSWebView : WKWebView

- (void)showWeb;
- (void)hideWeb;

@end

NS_ASSUME_NONNULL_END
