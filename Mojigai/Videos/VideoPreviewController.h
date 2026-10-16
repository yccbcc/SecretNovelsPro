//
//  VideoPreviewController.h
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/16.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

/*
 视频预览页
 最简单方案:用系统 AVPlayerViewController 全屏播放本地视频,支持常见格式(mp4/mov/m4v/m3u8 等)
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPreviewController : UIViewController

/// 要播放的视频本地路径
@property (nonatomic, copy) NSString *videoPath;

@end

NS_ASSUME_NONNULL_END
