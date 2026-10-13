//
//  TextReplaceManager.m
//  Mojigai
//
//  Created by zhaohongbin on 2026/10/13.
//  Copyright © 2026 zhaohongbin. All rights reserved.
//

#import "TextReplaceManager.h"

@implementation TextReplaceManager

+ (NSString *)replaceText:(NSString *)text leftText:(NSString *)leftText rightText:(NSString *)rightText {

    // 按组合字符拆分左右文本
    NSMutableArray<NSString *> *leftChars = [NSMutableArray array];
    NSMutableArray<NSString *> *rightChars = [NSMutableArray array];
    [leftText enumerateSubstringsInRange:NSMakeRange(0, leftText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        [leftChars addObject:substring];
    }];
    [rightText enumerateSubstringsInRange:NSMakeRange(0, rightText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        [rightChars addObject:substring];
    }];
    
    // ===== 替换规则(示例中 .. 表示任意空白: 空格/全角空格/换行/制表符,\s 已包含) =====
    // 一、两边字数相同时(如左栏"abc"→右栏"xyz"):逐字对应替换,空白原样保留
    //   1. 空白容错:"abc"→"xyz"   "a..bc"→"x..yz"   "ab..c"→"xy..z"   "a..b..c"→"x..y..z"
    //   2. 尾字可缺:"a..b"→"x..yz"   "ab"→"xyz"
    //   3. 后缀级联:整条替换完后,再从第2个字符起继续替换后缀
    //      "bc"→"yz"   "b..c"→"y..z"   "abcbc"→"xyzyz"
    //      (4字左栏依次为 bcd→xyz、cd→yz;后缀至少留2个字且字符齐全,单独的"b"不动;2字左栏不级联)
    // 二、左栏比右栏长时(如左栏"abc"→右栏"yz"):右栏对齐左栏末尾,多出的开头字去掉
    //   1. 整段替换:"abc"→"yz"("a..b..c"→"yz",空白只容错不保留)
    //   2. 后缀级联:继续去掉开头字替换,直到后缀与右栏等长(后缀至少留2个字):"bc"→"yz"   "b..c"→"y..z"(等长后缀按逐字对应保留空白)
    //      (4字左栏为整条"abcd"→"yz",再后缀"bcd"→"yz"、"cd"→"yz";后缀要求字符齐全)
    // 三、其他情况(左栏比右栏短):无法对应,整段替换(匹配内容连同内部空白整体替换为右栏文本)
    
    // alignByChar:两边字数相同,逐字对应(保留空白);leftLonger:左栏更长,右栏对齐左栏末尾
    BOOL alignByChar = leftChars.count == rightChars.count && leftChars.count > 1;
    BOOL leftLonger = leftChars.count > rightChars.count;
    NSString *result = text;
    // 替换轮数:第0轮匹配整条,后面每轮去掉开头一个字(后缀至少留2个字,避免单字满篇误替换);
    // 等长时换到只剩2个字,左长右短时换到后缀与右栏等长,如"abc"→"yz"依次替换"abc"、"bc"
    NSUInteger lastStart = 0;
    if (alignByChar) {
        lastStart = leftChars.count - 2;
    } else if (leftLonger) {
        NSUInteger minLen = MAX(rightChars.count, 2);
        lastStart = leftChars.count > minLen ? leftChars.count - minLen : 0;
    }
    for (NSUInteger k = 0; k <= lastStart; k++) {
        // 本轮匹配左栏从第k个字开始的后缀;先长后短,避免长串被短后缀提前拆坏
        // oneToOne:本轮是否逐字等长对应(等长时保留空白,不等长整段替换只能丢弃空白)
        BOOL oneToOne = alignByChar || (leftChars.count - k == rightChars.count);
        NSMutableString *pattern = [NSMutableString string];
        for (NSUInteger i = k; i < leftChars.count; i++) {
            if (i > k) {
                // 字与字之间允许夹杂任意空白;需要保留空白时用捕获组,替换时好按位置回填
                [pattern appendString:oneToOne ? @"(\\s*)" : @"\\s*"];
            }
            // 转义正则特殊字符,保证左栏内容按普通文字匹配
            NSString *escapedChar = [NSRegularExpression escapedPatternForString:leftChars[i]];
            if (k == 0 && alignByChar && i == leftChars.count - 1) {
                // 整条匹配时最后一个字符可有可无,非捕获组包住以免拆开 emoji 等代理对,也不影响 $1..$n 编号
                [pattern appendFormat:@"(?:%@)?", escapedChar];
            } else {
                [pattern appendString:escapedChar];
            }
        }
        
        // 替换模板:逐字对应时取右栏同位置字符,否则整段用完整右栏文本
        // tStart:左栏更长时每轮都替换成完整右栏(从右栏第1个字取起),其余情况从第k个字取起
        NSUInteger tStart = leftLonger ? 0 : k;
        NSMutableString *template = [NSMutableString string];
        for (NSUInteger i = tStart; i < rightChars.count; i++) {
            if (i > tStart && oneToOne) {
                // $n 对应本次匹配第 n-1 和第 n 个字符之间捕获到的空白
                [template appendFormat:@"$%lu", (unsigned long)(i - tStart)];
            }
            // 替换文本中的 \ 和 $ 需要转义,避免被当成模板占位符
            NSString *oneChar = [rightChars[i] stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
            oneChar = [oneChar stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
            [template appendString:oneChar];
        }
        
        // 执行本轮替换,结果作为下一轮的输入继续替换
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        if (regex) {
            result = [regex stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:template];
        }
    }
    return result;
}

@end
