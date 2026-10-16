//
//  VideoListController.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/16.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "VideoListController.h"
#import "VideoPreviewController.h"
#import "VideoStore.h"
#import "TSToast.h"

@interface VideoListController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<NSString *> *videoPaths;

@end

@implementation VideoListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.videoPaths = [[VideoStore videoPathsInFolder:self.folderName] mutableCopy];
    [self configCollectionView];
    [self reloadDataIfNeeded];   // 回到页面时刷新(可能有新下载的视频)
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadDataIfNeeded];
}

// 数据变了才刷新,避免每次进入都重排
- (void)reloadDataIfNeeded {
    NSArray<NSString *> *latest = [VideoStore videoPathsInFolder:self.folderName];
    if (![latest isEqualToArray:self.videoPaths]) {
        self.videoPaths = [latest mutableCopy];
        [self.collectionView reloadData];
    }
}

#pragma mark - UI

- (void)configCollectionView {
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat margin = 8;
    NSInteger columns = 2;
    CGFloat itemW = floor((screenW - margin * (columns + 1)) / columns);
    CGFloat itemH = itemW * 0.72;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(itemW, itemH);
    layout.minimumLineSpacing = margin;
    layout.minimumInteritemSpacing = margin;
    layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);

    UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, screenW, self.view.bounds.size.height) collectionViewLayout:layout];
    cv.backgroundColor = UIColor.whiteColor;
    cv.dataSource = self;
    cv.delegate = self;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressCell:)];
    [cv addGestureRecognizer:longPress];
    [cv registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"VideoCell"];
    [self.view addSubview:cv];
    self.collectionView = cv;
}

#pragma mark - 事件

- (void)longPressCell:(UILongPressGestureRecognizer *)lp {
    if (lp.state != UIGestureRecognizerStateBegan) return;
    CGPoint p = [lp locationInView:self.collectionView];
    NSIndexPath *ip = [self.collectionView indexPathForItemAtPoint:p];
    if (!ip) return;
    NSString *path = self.videoPaths[ip.item];

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:[path lastPathComponent]
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *export = [UIAlertAction actionWithTitle:@"导出到文件" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self exportVideoAtPath:path];
    }];
    UIAlertAction *del = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self confirmDeleteVideoAtPath:path];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [sheet addAction:export];
    [sheet addAction:del];
    [sheet addAction:cancel];
    // iPad 适配:actionSheet 必须指定 popover 锚点
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.collectionView;
        sheet.popoverPresentationController.sourceRect = CGRectMake(p.x, p.y, 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

// 导出到系统「文件」App(用户自选位置)
- (void)exportVideoAtPath:(NSString *)path {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithURL:[NSURL fileURLWithPath:path] inMode:UIDocumentPickerModeExportToService];
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)confirmDeleteVideoAtPath:(NSString *)path {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除视频" message:@"确定删除这个视频吗？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *del = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        if ([VideoStore deleteVideoAtPath:path]) {
            self.videoPaths = [[VideoStore videoPathsInFolder:self.folderName] mutableCopy];
            [self.collectionView reloadData];
        } else {
            [TSToast show:@"删除失败"];
        }
    }];
    [alert addAction:cancel];
    [alert addAction:del];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.videoPaths.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.97f alpha:1.00f];
    cell.layer.cornerRadius = 10;
    cell.layer.masksToBounds = YES;

    // 播放图标(占位)
    UIImageView *play = [cell.contentView viewWithTag:1201];
    if (!play) {
        play = [[UIImageView alloc] init];
        play.tag = 1201;
        play.contentMode = UIViewContentModeCenter;
        [cell.contentView addSubview:play];
    }
    play.frame = CGRectMake(0, 8, cell.contentView.bounds.size.width, cell.contentView.bounds.size.height - 40);
    if (@available(iOS 13.0, *)) {
        play.image = [[UIImage systemImageNamed:@"play.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        play.tintColor = [UIColor colorWithRed:0.90f green:0.32f blue:0.29f alpha:1.00f];
    }

    UILabel *label = [cell.contentView viewWithTag:1202];
    if (!label) {
        label = [[UILabel alloc] init];
        label.tag = 1202;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = UIColor.darkGrayColor;
        label.numberOfLines = 2;
        [cell.contentView addSubview:label];
    }
    label.frame = CGRectMake(6, cell.contentView.bounds.size.height - 34, cell.contentView.bounds.size.width - 12, 28);
    label.text = [self.videoPaths[indexPath.item] lastPathComponent];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    VideoPreviewController *preview = [[VideoPreviewController alloc] init];
    preview.videoPath = self.videoPaths[indexPath.item];
    preview.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:preview animated:YES completion:nil];
}

@end
