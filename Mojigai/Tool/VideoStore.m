//
//  VideoStore.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/16.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "VideoStore.h"

@implementation VideoStore

+ (NSString *)videosDirectory {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dir = [documents stringByAppendingPathComponent:@"videos"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dir]) {
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

+ (NSString *)ensureDefaultFolder {
    return [self folderPath:@"default"];
}

+ (NSArray<NSString *> *)folderNames {
    NSString *dir = [self videosDirectory];
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
    // 保证 default 总在列表中并排在最前
    if (![names containsObject:@"default"]) {
        [names addObject:@"default"];
    }
    return [names sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        // 首项(default)保持第 0,其余按名字升序
        if ([a isEqualToString:@"default"]) return NSOrderedAscending;
        if ([b isEqualToString:@"default"]) return NSOrderedDescending;
        return [a compare:b];
    }];
}

+ (NSString *)folderPath:(NSString *)name {
    NSString *dir = [self videosDirectory];
    NSString *full = [dir stringByAppendingPathComponent:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:full]) {
        [fileManager createDirectoryAtPath:full withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return full;
}

+ (BOOL)createFolder:(NSString *)name {
    NSString *clean = [self safeFolderName:name];
    if (clean.length == 0) return NO;
    NSString *full = [[self videosDirectory] stringByAppendingPathComponent:clean];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:full]) return YES;   // 已存在视为成功
    NSError *error = nil;
    BOOL ok = [fileManager createDirectoryAtPath:full withIntermediateDirectories:YES attributes:nil error:&error];
    if (!ok) {
        NSLog(@"创建视频文件夹失败: %@", error);
    }
    return ok;
}

+ (NSString *)safeFolderName:(NSString *)name {
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSCharacterSet *illegal = [NSCharacterSet characterSetWithCharactersInString:@"/\\:*?\"<>|%"];
    name = [[name componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];
    return name;
}

+ (NSArray<NSString *> *)videoPathsInFolder:(NSString *)name {
    NSString *dir = [self folderPath:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    for (NSString *n in contents) {
        if ([self isVideoName:n]) {
            [paths addObject:[dir stringByAppendingPathComponent:n]];
        }
    }
    return [paths sortedArrayUsingSelector:@selector(compare:)];
}

+ (BOOL)isVideoName:(NSString *)name {
    NSString *ext = name.pathExtension.lowercaseString;
    NSSet *videoExts = [NSSet setWithObjects:@"mp4", @"mov", @"m4v", @"m3u8", @"mpg", @"mpeg", @"avi", @"3gp", @"wmv", @"flv", nil];
    return [videoExts containsObject:ext];
}

+ (nullable NSString *)saveVideoFromURL:(NSURL *)url intoDirectory:(NSString *)dir error:(NSError **)error {
    NSString *name = url.lastPathComponent.length > 0 ? url.lastPathComponent : @"video.mp4";
    NSString *dest = [self uniquePathInDirectory:dir name:name];
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:dest] error:error];
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

+ (BOOL)deleteVideoAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) return YES;
    NSError *error = nil;
    BOOL ok = [fileManager removeItemAtPath:path error:&error];
    if (!ok) {
        NSLog(@"删除视频失败: %@", error);
    }
    return ok;
}

+ (BOOL)deleteFolder:(NSString *)name {
    // 防路径逃逸
    if ([name containsString:@"/"] || [name containsString:@"\\"]) return NO;
    NSString *full = [[self videosDirectory] stringByAppendingPathComponent:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:full]) return YES;
    NSError *error = nil;
    BOOL ok = [fileManager removeItemAtPath:full error:&error];
    if (!ok) {
        NSLog(@"删除视频文件夹失败: %@", error);
    }
    return ok;
}

@end
