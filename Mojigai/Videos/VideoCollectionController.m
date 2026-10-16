//
//  VideoCollectionController.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/16.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "VideoCollectionController.h"
#import "VideoListController.h"
#import "VideoStore.h"
#import "TSToast.h"

@interface VideoCollectionController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<NSString *> *folderNames;

@end

@implementation VideoCollectionController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [VideoStore ensureDefaultFolder];   // 确保 default 文件夹存在
    self.folderNames = [[VideoStore folderNames] mutableCopy];
    [self configNavigationBar];
    [self configCollectionView];
}

#pragma mark - UI

- (void)configNavigationBar {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"新建"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(newFolderClick)];
}

- (void)configCollectionView {
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat margin = 12;
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
    [cv registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"VideoFolderCell"];
    [self.view addSubview:cv];
    self.collectionView = cv;
}

#pragma mark - 事件

- (void)newFolderClick {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建视频文件夹" message:@"输入文件夹名称" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"文件夹名";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length == 0) {
            [TSToast show:@"请输入文件夹名称"];
            return;
        }
        if ([VideoStore createFolder:name]) {
            self.folderNames = [[VideoStore folderNames] mutableCopy];
            [self.collectionView reloadData];
        } else {
            [TSToast show:@"创建失败"];
        }
    }];
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)longPressCell:(UILongPressGestureRecognizer *)lp {
    if (lp.state != UIGestureRecognizerStateBegan) return;
    CGPoint p = [lp locationInView:self.collectionView];
    NSIndexPath *ip = [self.collectionView indexPathForItemAtPoint:p];
    if (!ip) return;
    NSString *folder = self.folderNames[ip.item];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除视频文件夹"
                                                                  message:[NSString stringWithFormat:@"确定删除文件夹「%@」及其中的全部视频吗？", folder]
                                                           preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *del = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        if ([VideoStore deleteFolder:folder]) {
            self.folderNames = [[VideoStore folderNames] mutableCopy];
            [self.collectionView reloadData];
        } else {
            [TSToast show:@"删除失败"];
        }
    }];
    [alert addAction:cancel];
    [alert addAction:del];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openFolderAtIndexPath:(NSIndexPath *)indexPath {
    NSString *folder = self.folderNames[indexPath.item];
    VideoListController *vc = [[VideoListController alloc] init];
    vc.folderName = folder;
    vc.title = folder;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.folderNames.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoFolderCell" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:0.95f green:0.97f blue:1.00f alpha:1.00f];
    cell.layer.cornerRadius = 10;
    cell.layer.masksToBounds = YES;

    UIImageView *icon = [cell.contentView viewWithTag:1101];
    if (!icon) {
        icon = [[UIImageView alloc] init];
        icon.tag = 1101;
        icon.contentMode = UIViewContentModeCenter;
        [cell.contentView addSubview:icon];
    }
    icon.frame = CGRectMake(0, 16, cell.contentView.bounds.size.width, 56);
    if (@available(iOS 13.0, *)) {
        icon.image = [[UIImage systemImageNamed:@"folder.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        icon.tintColor = [UIColor colorWithRed:0.60f green:0.30f blue:0.85f alpha:1.00f];
    }

    UILabel *label = [cell.contentView viewWithTag:1102];
    if (!label) {
        label = [[UILabel alloc] init];
        label.tag = 1102;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        label.textColor = UIColor.darkGrayColor;
        [cell.contentView addSubview:label];
    }
    label.frame = CGRectMake(8, 72, cell.contentView.bounds.size.width - 16, 24);
    label.text = self.folderNames[indexPath.item];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self openFolderAtIndexPath:indexPath];
}

@end
