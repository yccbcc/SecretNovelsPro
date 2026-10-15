//
//  ImageStore.h
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/15.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

/*
 图片本地存取工具
 把从「文件」App 导入的图片复制到 Documents/Images 目录，并提供列表与缩略图读取
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageStore : NSObject

/// Documents/Images 目录(不存在会自动创建)
+ (NSString *)imagesDirectory;

/// 目录下所有图片的本地绝对路径(按文件名升序)
+ (NSArray<NSString *> *)allImagePaths;

/// 把外部选中的图片复制到 Images 目录，返回复制后的本地路径；失败返回 nil
+ (nullable NSString *)saveImageFromURL:(NSURL *)url error:(NSError **)error;

/// 读取缩略图(用于列表，避免直接加载原图爆内存)，maxPixel 为最长边像素
+ (nullable UIImage *)thumbnailForPath:(NSString *)path maxPixel:(CGFloat)maxPixel;

@end

NS_ASSUME_NONNULL_END