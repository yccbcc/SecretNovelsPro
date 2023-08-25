//
//  DCFileTool.m
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import "DCFileTool.h"

@implementation DCFileTool

#pragma mark - 获取这个字符串text中的所有findText的所在的NSRange
+ (NSMutableArray *)getRangeStr:(NSString *)text findText:(NSString *)findText
{
    NSMutableArray *arrayRanges = [NSMutableArray arrayWithCapacity:3];
    if (findText == nil && [findText isEqualToString:@""])
    {
        return nil;
    }
    NSRange rang = [text rangeOfString:findText options:NSRegularExpressionSearch];
    if (rang.location != NSNotFound && rang.length != 0)
    {
        [arrayRanges addObject:[NSValue valueWithRange:rang]];
        NSRange rang1 = {0,0};
        NSInteger location = 0;
        NSInteger length = 0;
        for (int i = 0;; i++)
        {
            if (0 == i)
            {
                //去掉这个abc字符串
                location = rang.location + rang.length;
                length = text.length - rang.location - rang.length;
                rang1 = NSMakeRange(location, length);
            }
            else
            {
                location = rang1.location + rang1.length;
                length = text.length - rang1.location - rang1.length;
                rang1 = NSMakeRange(location, length);
            }
            //在一个range范围内查找另一个字符串的range
            rang1 = [text rangeOfString:findText options:NSRegularExpressionSearch range:rang1];
            if (rang1.location == NSNotFound && rang1.length == 0)
            {
                break;
            }
            else//添加符合条件的location进数组
                [arrayRanges addObject:[NSValue valueWithRange:rang1]];
        }
        return arrayRanges;
    }
    return nil;
}

+(NSMutableArray *)getChapterArrWithString:(NSString *)text
{
    NSMutableArray *marr = [DCFileTool getRangeStr:text findText:@"\n第.{1,}章.*\r\n"];
    NSMutableArray *strMarr = [NSMutableArray array];
    NSRange lastRange = NSMakeRange(0, 0);
    for (int i = 0; i<marr.count; i++) {
        NSValue *value = marr[i];
        NSString *string = [text substringWithRange:NSMakeRange(lastRange.location, value.rangeValue.location - lastRange.location)];
        lastRange = value.rangeValue;
        if([string isEqualToString:@""])
        {
            string = @"\r\n";
        }
        [strMarr addObject:string];
    }
    //最后一章到结尾
    NSString *string = [text substringFromIndex:lastRange.location];
    if([string isEqualToString:@""])
    {
        string = @"\r\n";
    }
    [strMarr addObject:string];
    return strMarr;
}

@end
