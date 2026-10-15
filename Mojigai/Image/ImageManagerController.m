//
//  ImageManagerController.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/15.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "ImageManagerController.h"
#import "ImagePreviewController.h"
#import "ImageStore.h"
#import "TSToast.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ImageManagerController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIDocumentPickerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<NSString *> *imagePaths;

@end

@implementation ImageManagerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    // 被 push 进导航控制器:页面从导航栏之下开始,不复用自绘导航栏
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.imagePaths = [[ImageStore allImagePaths] mutableCopy];
    [self configNavigationBar];
    [self configCollectionView];
}

#pragma mark - UI

- (void)configNavigationBar {
    // 复用真实导航栏:返回由导航控制器自带,"导入"放右侧
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"导入"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(importClick)];
}

- (void)configCollectionView {
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat margin = 2;
    NSInteger columns = 3;
    CGFloat itemW = floor((screenW - margin * (columns + 1)) / columns);

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(itemW, itemW);
    layout.minimumLineSpacing = margin;
    layout.minimumInteritemSpacing = margin;
    layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);

    // 页面已在导航栏之下,网格从顶部开始铺满
    UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, screenW, self.view.bounds.size.height) collectionViewLayout:layout];
    cv.backgroundColor = UIColor.whiteColor;
    cv.dataSource = self;
    cv.delegate = self;
    [cv registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [self.view addSubview:cv];
    self.collectionView = cv;
}

#pragma mark - 事件

- (void)backClick {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)importClick {
    // 打开系统「文件」App，支持多选图片；asCopy:YES 让其先拷进 App 沙盒
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeImage] asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = YES;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagePaths.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    UIImageView *imageView = [cell.contentView viewWithTag:999];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
        imageView.tag = 999;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [cell.contentView addSubview:imageView];
    }
    imageView.frame = cell.contentView.bounds;
    // 列表用缩略图，避免直接加载原图
    imageView.image = [ImageStore thumbnailForPath:self.imagePaths[indexPath.item] maxPixel:300];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ImagePreviewController *preview = [[ImagePreviewController alloc] init];
    preview.imagePaths = self.imagePaths;
    preview.index = indexPath.item;
    preview.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:preview animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0) {
        return;
    }
    NSInteger failed = 0;
    for (NSURL *url in urls) {
        NSError *error = nil;
        NSString *stored = [ImageStore saveImageFromURL:url error:&error];
        if (!stored) {
            failed++;
            NSLog(@"导入图片失败: %@", error);
        }
    }
    self.imagePaths = [[ImageStore allImagePaths] mutableCopy];
    [self.collectionView reloadData];

    if (failed == urls.count) {
        [TSToast show:@"图片导入失败"];
    } else if (failed > 0) {
        [TSToast show:[NSString stringWithFormat:@"部分图片导入失败(%ld)", (long)failed]];
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSLog(@"取消导入图片");
}

@end