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

+ (NSArray<NSString *> *)imageSubfolderNames {
    NSString *dir = [self imagesDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSString *name in contents) {
        if ([name hasPrefix:@"."]) continue;
        BOOL isDir = NO;
        NSString *full = [dir stringByAppendingPathComponent:name];
        if ([fileManager fileExistsAtPath:full isDirectory:&isDir] && isDir) {
            [names addObject:name];
        }
    }
    return [names sortedArrayUsingSelector:@selector(compare:)];
}

+ (NSString *)subfolderPath:(NSString *)name {
    NSString *dir = [self imagesDirectory];
    NSString *full = [dir stringByAppendingPathComponent:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:full]) {
        [fileManager createDirectoryAtPath:full withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return full;
}

+ (BOOL)createSubfolder:(NSString *)name {
    NSString *clean = [self safeSubfolderName:name];
    if (clean.length == 0) return NO;
    NSString *full = [[self imagesDirectory] stringByAppendingPathComponent:clean];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:full]) return YES;   // 已存在视为成功
    NSError *error = nil;
    BOOL ok = [fileManager createDirectoryAtPath:full withIntermediateDirectories:YES attributes:nil error:&error];
    if (!ok) {
        NSLog(@"创建相册文件夹失败: %@", error);
    }
    return ok;
}

+ (NSString *)safeSubfolderName:(NSString *)name {
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSCharacterSet *illegal = [NSCharacterSet characterSetWithCharactersInString:@"/\\:*?\"<>|%"];
    name = [[name componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];
    return name;
}

+ (NSArray<NSString *> *)imagePathsInSubfolder:(NSString *)name {
    NSString *dir = [self subfolderPath:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    for (NSString *n in contents) {
        if ([self isImageName:n]) {
            [paths addObject:[dir stringByAppendingPathComponent:n]];
        }
    }
    return [paths sortedArrayUsingSelector:@selector(compare:)];
}

+ (BOOL)isImageName:(NSString *)name {
    NSString *ext = name.pathExtension.lowercaseString;
    NSSet *imageExts = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", @"heic", @"heif", @"webp", @"bmp", @"tiff", @"tif", nil];
    return [imageExts containsObject:ext];
}

+ (BOOL)deleteImageAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) return YES;
    NSError *error = nil;
    BOOL ok = [fileManager removeItemAtPath:path error:&error];
    if (!ok) {
        NSLog(@"删除图片失败: %@", error);
    }
    return ok;
}

+ (BOOL)deleteSubfolder:(NSString *)name {
    // 防路径逃逸:不允许名字里带路径分隔符
    if ([name containsString:@"/"] || [name containsString:@"\\"]) return NO;
    NSString *full = [[self imagesDirectory] stringByAppendingPathComponent:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:full]) return YES;
    NSError *error = nil;
    BOOL ok = [fileManager removeItemAtPath:full error:&error];
    if (!ok) {
        NSLog(@"删除相册失败: %@", error);
    }
    return ok;
}

+ (nullable NSString *)saveImageFromURL:(NSURL *)url error:(NSError **)error {
    return [self saveImageFromURL:url intoDirectory:[self imagesDirectory] error:error];
}

+ (nullable NSString *)saveImageFromURL:(NSURL *)url intoDirectory:(NSString *)dir error:(NSError **)error {
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