//
//  ImagePreviewController.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/15.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "ImagePreviewController.h"
#import "ImageStore.h"

#define statusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height

@interface ImagePreviewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation ImagePreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    if (self.imagePaths.count == 0) {
        return;
    }
    if (self.index < 0 || self.index >= self.imagePaths.count) {
        self.index = 0;
    }
    [self configScrollView];
    [self configCloseButton];
    [self configPageControl];
}

#pragma mark - UI

// 页码用最长边像素下采样到屏幕分辨率，既清晰又避免整幅原图占内存
- (CGFloat)displayMaxPixel {
    CGFloat maxSide = MAX(self.view.bounds.size.width, self.view.bounds.size.height);
    return maxSide * UIScreen.mainScreen.scale;
}

- (void)configScrollView {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(width * self.imagePaths.count, height);
    for (NSInteger i = 0; i < self.imagePaths.count; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(width * i, 0, width, height)];
        imageView.tag = 1000 + i;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [scrollView addSubview:imageView];
    }
    scrollView.contentOffset = CGPointMake(width * self.index, 0);
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;

    // 只加载当前页及相邻页
    [self loadImagesAroundIndex:self.index];
}

- (void)configCloseButton {
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(8, statusBarHeight, 60, 44)];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
}

- (void)configPageControl {
    CGFloat height = self.view.bounds.size.height;
    UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, height - 60, self.view.bounds.size.width, 20)];
    pageControl.numberOfPages = self.imagePaths.count;
    pageControl.currentPage = self.index;
    pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.4];
    pageControl.currentPageIndicatorTintColor = UIColor.whiteColor;
    pageControl.userInteractionEnabled = NO;
    [self.view addSubview:pageControl];
    self.pageControl = pageControl;
}

#pragma mark - 事件

- (void)closeClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 图片加载

- (void)loadImagesAroundIndex:(NSInteger)index {
    CGFloat maxPixel = [self displayMaxPixel];
    for (NSInteger i = index - 1; i <= index + 1; i++) {
        if (i < 0 || i >= self.imagePaths.count) {
            continue;
        }
        UIImageView *imageView = [self.scrollView viewWithTag:1000 + i];
        if (imageView && imageView.image == nil) {
            imageView.image = [ImageStore thumbnailForPath:self.imagePaths[i] maxPixel:maxPixel];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat width = scrollView.bounds.size.width;
    if (width <= 0) {
        return;
    }
    NSInteger page = (NSInteger)round(scrollView.contentOffset.x / width);
    page = MAX(0, MIN((NSInteger)self.imagePaths.count - 1, page));
    self.pageControl.currentPage = page;
    [self loadImagesAroundIndex:page];
}

@end