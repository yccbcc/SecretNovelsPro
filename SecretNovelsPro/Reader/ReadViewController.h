//
//  ReadViewController.h
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReadViewController : UIPageViewController<UIPageViewControllerDelegate,UIPageViewControllerDataSource>

@property (nonatomic, assign) int row;

@end

NS_ASSUME_NONNULL_END
