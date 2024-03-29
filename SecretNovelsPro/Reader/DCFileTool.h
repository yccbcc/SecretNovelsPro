//
//  DCFileTool.h
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCFileTool : NSObject
+(NSMutableArray *)getChapterArrWithString:(NSString *)text;
+(NSArray *)pagingWithContentString:(NSString *)contentString contentSize:(CGSize)contentSize textAttribute:(NSDictionary *)textAttribute;
@end

NS_ASSUME_NONNULL_END
