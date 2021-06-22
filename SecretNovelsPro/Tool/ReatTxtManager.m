//
//  ReatTxtManager.m
//  SecretNovelsPro
//
//  Created by 赵宏彬 on 2020/12/11.
//  Copyright © 2020 zhaohongbin. All rights reserved.
//

#import "ReatTxtManager.h"
#import <sys/utsname.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kFilePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0]

@implementation ReatTxtManager

+ (NSString *)readTxtWithPath:(NSString *)txtPath txtName:(NSString *)name{

    //-------------------------------------------------------------------------------------------
    //编码格式
    //    NSArray *arrEncoding = @[@(NSASCIIStringEncoding),
    //                             @(NSNEXTSTEPStringEncoding),
    //                             @(NSJapaneseEUCStringEncoding),
    //                             @(NSUTF8StringEncoding),
    //                             @(NSISOLatin1StringEncoding),
    //                             @(NSSymbolStringEncoding),
    //                             @(NSNonLossyASCIIStringEncoding),
    //                             @(NSShiftJISStringEncoding),
    //                             @(NSISOLatin2StringEncoding),
    //                             @(NSUnicodeStringEncoding),
    //                             @(NSWindowsCP1251StringEncoding),
    //                             @(NSWindowsCP1252StringEncoding),
    //                             @(NSWindowsCP1253StringEncoding),
    //                             @(NSWindowsCP1254StringEncoding),
    //                             @(NSWindowsCP1250StringEncoding),
    //                             @(NSISO2022JPStringEncoding),
    //                             @(NSMacOSRomanStringEncoding),
    //                             @(NSUTF16StringEncoding),
    //                             @(NSUTF16BigEndianStringEncoding),
    //                             @(NSUTF16LittleEndianStringEncoding),
    //                             @(NSUTF32StringEncoding),
    //                             @(NSUTF32BigEndianStringEncoding),
    //                             @(NSUTF32LittleEndianStringEncoding),
    //                             @(enc)
    //    ];

    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSArray *arrEncodingArr = @[
        @(NSUTF8StringEncoding),
        @(enc)
    ];
    
    NSLog(@"filePath : %@",txtPath);
    
    NSURL *url = [NSURL URLWithString:txtPath];
    
    NSLog(@"filePath : %@",url.path);
    
    BOOL isAccessing = [url startAccessingSecurityScopedResource];
    
    NSString *aString;
    for (int i = 0 ; i < [arrEncodingArr count]; i++) {
        unsigned long encodingCode = [arrEncodingArr[i] unsignedLongValue];
        NSError *error = nil;
        aString = [NSString stringWithContentsOfFile:txtPath encoding:encodingCode  error:&error];
        if (error != nil) {
            aString = [NSString stringWithFormat:@"获取txt错误: %@",error];
            NSLog(@"%@",aString);
        }else{
            [self writeToTXTFileWithString:aString fileName:name];
            return aString;
        }
    }
    if (isAccessing) {
        [url stopAccessingSecurityScopedResource];
    }
    return aString;
}

+ (void)writeToTXTFileWithString:(NSString *)string fileName:(NSString *)fileName {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {

            //获取文件路径
            NSString *fullName = [NSString stringWithFormat:@"%@", fileName];
            NSString *theFilePath = [kFilePath stringByAppendingPathComponent:fullName];
            NSLog(@"%@",theFilePath);
            //创建文件管理器
            NSFileManager *fileManager = [NSFileManager defaultManager];
            //如果文件不存在 创建文件
            if(![fileManager fileExistsAtPath:theFilePath]){
                [@"" writeToFile:theFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:theFilePath];
            [fileHandle seekToEndOfFile];  //将节点跳到文件的末尾
            NSData* stringData  = [[NSString stringWithFormat:@"%@\n",string] dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandle writeData:stringData]; //追加写入数据
            [fileHandle closeFile];
        }
    });
}

#pragma mark - 获取文件夹下的所有文件
- (NSArray *)fetchAllFilePaths{
    NSString *from = kFilePath;
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSError *error2;
    NSArray *subpaths=[mgr contentsOfDirectoryAtPath:from error:&error2];
    NSLog(@"subpaths = %@",subpaths);
    return subpaths;
}

#pragma mark - 读取文件
- (void)readString{
    //        NSData *data = [aString dataUsingEncoding:encodingCode];
    //        NSString *string = [[NSString alloc] initWithData:data encoding:encodingCode];
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSArray *arrEncodingArr = @[
        @(NSUTF8StringEncoding),
        @(enc)
    ];
    
    NSString *aString;
    
    NSArray *filepaths = [self fetchAllFilePaths];
    
    for (NSString *filepath in filepaths) {
        for (int i = 0 ; i < [arrEncodingArr count]; i++) {
            unsigned long encodingCode = [arrEncodingArr[i] unsignedLongValue];
            NSError *error = nil;
            NSString *filePath = filepath; // <---这里是要查看的文件路径
            aString = [NSString stringWithContentsOfFile:filePath encoding:encodingCode  error:&error];
            if (error != nil) {
                
            }else{
                // 如果有必要，还可以把文件创建出来再测试
                [aString writeToFile:[NSString stringWithFormat:@"/Users/dlios1/Desktop/%@.xml", arrEncodingArr[i]]
                         atomically:YES
                           encoding:encodingCode
                              error:&error];
                break;
            }
        }
    }
}


    
@end
