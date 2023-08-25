//
//  HandleSystemFile.m
//  SecretNovelsPro
//
//  Created by cyou_zhb on 2021/4/6.
//  Copyright © 2021 zhaohongbin. All rights reserved.
//

#import "HandleSystemFile.h"


@implementation HandleSystemFile

+ (instancetype)shareInstance {
    static HandleSystemFile *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    
    return shareInstance;
}

- (void)saveToFile:(NSString *)filePath{
    
    if (self.controller == nil) {
        NSLog(@"需要设置controller");
    }

    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version < 11) {
        NSLog(@"下载文件要求手机系统版本在11.0以上");
    }
    
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initWithURL:[NSURL fileURLWithPath:filePath] inMode:UIDocumentPickerModeExportToService];
    // 设置代理
    documentPickerVC.delegate = self;
    // 设置模态弹出方式
    documentPickerVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.controller presentViewController:documentPickerVC animated:true completion:nil];
}


- (void)readFile{
    NSArray *types = @[@"public.content",@"public.text"];
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
    // 设置代理
    documentPickerVC.delegate = self;
    // 设置模态弹出方式
    documentPickerVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.controller presentViewController:documentPickerVC animated:YES completion:nil];
}


#pragma mark - UIDocumentPickerDelegate

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller{
    NSLog(@"cancel");
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (controller.documentPickerMode == UIDocumentPickerModeExportToService) {

        //do some stuff
        return;
        }
    // 获取授权
    BOOL fileUrlAuthozied = [urls.firstObject startAccessingSecurityScopedResource];
    if (fileUrlAuthozied) {
        // 通过文件协调工具来得到新的文件地址，以此得到文件保护功能
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSError *error;
        
        [fileCoordinator coordinateReadingItemAtURL:urls.firstObject options:0 error:&error byAccessor:^(NSURL *newURL) {
            // 读取文件
            NSString *fileName = [newURL lastPathComponent];
            NSError *error = nil;
            NSData *fileData = [NSData dataWithContentsOfURL:newURL options:NSDataReadingMappedIfSafe error:&error];
            if (error) {
                // 读取出错
            } else {
                // 上传
                NSLog(@"文件名称 : %@", fileName);
                [controller dismissViewControllerAnimated:true completion:nil];
            }
        }];
        [urls.firstObject stopAccessingSecurityScopedResource];
    } else {
        // 授权失败
    }
}


@end
