//
//  DCFileTool.h
//  MojiGai
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCFileTool : NSObject
+(NSMutableArray *)getChapterArrWithString:(NSString *)text;
+(NSArray *)pagingWithContentString:(NSString *)contentString contentSize:(CGSize)contentSize textAttribute:(NSDictionary *)textAttribute;

#pragma mark - 文本内容落盘(Documents/txts),UserDefaults 只留轻量元数据
/// 正文存储目录(自动创建)
+ (NSString *)txtsDirPath;
/// 把正文写入文件,并在 entry 中记录文件名;返回是否成功
+ (BOOL)saveValue:(NSString *)value toEntry:(NSMutableDictionary *)entry;
/// 读取正文(优先读文件;老格式无文件时回退 entry[@"value"])
+ (NSString *)readValueForEntry:(NSDictionary *)entry;

#pragma mark - 分页结果缓存(与正文同目录,存 .pages 文件)
+ (BOOL)savePages:(NSArray *)pages forEntry:(NSMutableDictionary *)entry;
+ (NSArray *)readPagesForEntry:(NSDictionary *)entry;
+ (void)removePagesForEntry:(NSDictionary *)entry;

#pragma mark - 删除条目相关文件(正文 + 分页缓存)
+ (void)removeEntryFiles:(NSDictionary *)entry;
@end

NS_ASSUME_NONNULL_END
