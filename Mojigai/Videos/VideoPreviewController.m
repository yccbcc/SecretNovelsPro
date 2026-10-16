//
//  VideoPreviewController.m
//  MojiGai
//
//  Created by zhaohongbin on 2026/10/16.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "VideoPreviewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@implementation VideoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;

    if (self.videoPath.length == 0) {
        return;
    }

    // 最简方案:系统播放器
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.videoPath]];
    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    playerVC.player = player;
    [self addChildViewController:playerVC];
    playerVC.view.frame = self.view.bounds;
    [self.view addSubview:playerVC.view];
    [playerVC didMoveToParentViewController:self];

    [player play];
}

@end
