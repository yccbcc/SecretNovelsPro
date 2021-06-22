//
//  HandleSystemFile.h
//  SecretNovelsPro
//
//  Created by cyou_zhb on 2021/4/6.
//  Copyright © 2021 zhaohongbin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HandleSystemFile : NSObject<UIDocumentPickerDelegate>

+ (instancetype)shareInstance;

@property (nonatomic, weak) UIViewController *controller;

- (void)saveToFile:(NSString *)filePath;
- (void)readFile;


@end

NS_ASSUME_NONNULL_END
