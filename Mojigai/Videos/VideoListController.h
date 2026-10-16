//
//  VideoListController.h
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/16.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

/*
 视频列表页
 以网格列出指定文件夹下的视频;点击播放预览,长按删除
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoListController : UIViewController

/// 视频所在文件夹名
@property (nonatomic, copy) NSString *folderName;

@end

NS_ASSUME_NONNULL_END
