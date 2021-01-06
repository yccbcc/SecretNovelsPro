//
//  ReatTxtManager.m
//  SecretNovelsPro
//
//  Created by 赵宏彬 on 2020/12/11.
//  Copyright © 2020 zhaohongbin. All rights reserved.
//

#import "ReatTxtManager.h"

@implementation ReatTxtManager

+ (NSString *)readTxtWithPath:(NSString *)txtPath txtName:(NSString *)name{

    NSError *error = nil;
    //demo
    //    NSMutableString *path = [NSMutableString stringWithCapacity:42];
    //    NSString *home = [@"~" stringByExpandingTildeInPath];
    //    [path appendString:home];
    //    [path appendString:@"/work/temp.txt"];
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
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
    
    NSArray *arrEncoding = @[
        @(NSUTF8StringEncoding),
        @(enc)
    ];
    
    NSString *aString;
    for (int i = 0 ; i < [arrEncoding count]; i++) {
        unsigned long encodingCode = [arrEncoding[i] unsignedLongValue];
        NSError *error = nil;
        NSString *filePath = txtPath; // <---这里是要查看的文件路径
        aString = [NSString stringWithContentsOfFile:filePath encoding:encodingCode  error:&error];
        if (error != nil) {
            aString = [NSString stringWithFormat:@"获取txt错误:%@ *** %@",aString,[error localizedDescription]];
            NSLog(@"%@",aString);
        }else{
            [self writeToTXTFileWithString:aString fileName:name];
            
            NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);

            NSString *from = paths[0];
            NSFileManager *mgr = [NSFileManager defaultManager];
            NSError *error2;
            NSArray *subpaths=[mgr  contentsOfDirectoryAtPath:from error:&error2];
            NSLog(@"%@",subpaths);
            
            return aString;
        }
        //        NSData *data = [aString dataUsingEncoding:encodingCode];
        //        NSString *string = [[NSString alloc] initWithData:data encoding:encodingCode];
        
        /*
         // 如果有必要，还可以把文件创建出来再测试
         [string writeToFile:[NSString stringWithFormat:@"/Users/dlios1/Desktop/%@.xml", arrEncodingName[i]]
         atomically:YES
         encoding:encodingCode
         error:&error];
         */
        
    }
    return aString;
    
}

+ (void)writeToTXTFileWithString:(NSString *)string fileName:(NSString *)fileName {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            //获取沙盒路径
            NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
            //获取文件路径
            NSString *fullName = [NSString stringWithFormat:@"%@", fileName];
            NSString *theFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fullName];
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
    
@end
