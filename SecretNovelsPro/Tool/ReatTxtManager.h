//
//  ReatTxtManager.h
//  SecretNovelsPro
//
//  Created by 赵宏彬 on 2020/12/11.
//  Copyright © 2020 zhaohongbin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReatTxtManager : NSObject

+ (NSString *)readTxtWithPath:(NSString *)txtPath txtName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
