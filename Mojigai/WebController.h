//
//  WebController.h
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/15.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 网页浏览 + m3u8 下载转 mp4
@interface WebController : UIViewController

/// 初始加载地址(可为空)
@property (nonatomic, copy, nullable) NSString *initialURLString;

@end

NS_ASSUME_NONNULL_END
