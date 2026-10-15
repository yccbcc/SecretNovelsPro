//
//  ImageStore.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/15.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "ImageStore.h"
#import <ImageIO/ImageIO.h>

@implementation ImageStore

+ (NSString *)imagesDirectory {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dir = [documents stringByAppendingPathComponent:@"Images"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dir]) {
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

+ (NSArray<NSString *> *)allImagePaths {
    NSString *dir = [self imagesDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    for (NSString *name in contents) {
        if ([self isImageName:name]) {
            [paths addObject:[dir stringByAppendingPathComponent:name]];
        }
    }
    return [paths sortedArrayUsingSelector:@selector(compare:)];
}

+ (BOOL)isImageName:(NSString *)name {
    NSString *ext = name.pathExtension.lowercaseString;
    NSSet *imageExts = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", @"heic", @"heif", @"webp", @"bmp", @"tiff", @"tif", nil];
    return [imageExts containsObject:ext];
}

+ (nullable NSString *)saveImageFromURL:(NSURL *)url error:(NSError **)error {
    NSString *dir = [self imagesDirectory];
    NSString *name = url.lastPathComponent.length > 0 ? url.lastPathComponent : @"image.dat";
    NSString *dest = [self uniquePathInDirectory:dir name:name];
    // 普通路径下 start 是 no-op，返回值不可当可读性门禁，仅记录并配对 stop
    BOOL didStart = [url startAccessingSecurityScopedResource];
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:dest] error:error];
    if (didStart) {
        [url stopAccessingSecurityScopedResource];
    }
    return success ? dest : nil;
}

+ (NSString *)uniquePathInDirectory:(NSString *)dir name:(NSString *)name {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dest = [dir stringByAppendingPathComponent:name];
    if (![fileManager fileExistsAtPath:dest]) {
        return dest;
    }
    NSString *base = name.stringByDeletingPathExtension;
    NSString *ext = name.pathExtension;
    NSInteger index = 1;
    while (YES) {
        NSString *candidate = ext.length > 0 ? [NSString stringWithFormat:@"%@_%ld.%@", base, (long)index, ext]
                                             : [NSString stringWithFormat:@"%@_%ld", base, (long)index];
        dest = [dir stringByAppendingPathComponent:candidate];
        if (![fileManager fileExistsAtPath:dest]) {
            return dest;
        }
        index++;
    }
}

+ (nullable UIImage *)thumbnailForPath:(NSString *)path maxPixel:(CGFloat)maxPixel {
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!source) {
        return nil;
    }
    NSDictionary *options = @{
        (__bridge id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
        (__bridge id)kCGImageSourceCreateThumbnailWithTransform: @YES,
        (__bridge id)kCGImageSourceThumbnailMaxPixelSize: @(maxPixel),
    };
    CGImageRef cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    if (!cgImage) {
        return nil;
    }
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

@end