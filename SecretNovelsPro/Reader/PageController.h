//
//  PageController.h
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PageController : UIViewController

@property (nonatomic, strong) UITextView *readTXTView;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, assign) int index;

@end

NS_ASSUME_NONNULL_END
