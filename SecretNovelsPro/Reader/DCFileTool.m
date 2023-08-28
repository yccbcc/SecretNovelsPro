//
//  DCFileTool.m
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import "DCFileTool.h"
#import <UIKit/UIKit.h>
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



+(NSArray *)pagingWithContentString:(NSString *)contentString contentSize:(CGSize)contentSize textAttribute:(NSDictionary *)textAttribute
{
    
    NSMutableArray *pageArray = [NSMutableArray array];
    NSMutableAttributedString *orginAttributeString = [[NSMutableAttributedString alloc]initWithString:contentString attributes:textAttribute];
    NSTextStorage *textStorage = [[NSTextStorage alloc]initWithAttributedString:orginAttributeString];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc]init];
    [textStorage addLayoutManager:layoutManager];
    int I=0;
    while (YES) {
        I++;
        NSTextContainer *textContainer = [[NSTextContainer alloc]initWithSize:contentSize];
        [layoutManager addTextContainer:textContainer];
        NSRange rang = [layoutManager glyphRangeForTextContainer:textContainer];
        if(rang.length <= 0)
        {
            break;
        }
        NSString *str = [contentString substringWithRange:rang];
        //NSMutableAttributedString *attstr = [[NSMutableAttributedString alloc]initWithString:str attributes:textAttribute];
        [pageArray addObject:str];
    }
    return pageArray;
}


@end


/**
 @implementation ViewController
 {
     UITextView *_textView;
     NSArray *_dataArr;
 }
 - (void)viewDidLoad {
     [super viewDidLoad];
     // Do any additional setup after loading the view.
     
     
     NSString *txt = @"后续，广东盐业会持续密切关注国家及广东省环保部门公布的海水水质信息，对广东海水定期进行放射性元素送检，并严密监控盐产品是否受污染的情况，保障广东盐业食盐产品的质量安全及供应安全。\n广东盐业集团相关负责人介绍称，目前，省、市两级食盐政府储备量和企业社会责任储备共10.8万吨，能保障食盐充足供应。同时，广东盐业已对广东省主要海盐生产工区的海域海水及生态海盐进行了α、β放射性项目的第三方送样检测，结果显示目前的广东海盐是安全的。\n据广东盐业集团负责人介绍，广东盐业作为广东省内唯一的省属食盐生产运销和储备企业，长期以来肩负确保本省食盐质量安全、供应安全的社会责任。目前，省、市两级食盐政府储备量和企业社会责任储备共10.8万吨，百分百覆盖全省各市县行政区域，能迅速及时响应，保障食盐充足供应。市民不必恐慌，更不必效仿“囤盐”。\n暴雨来势汹汹，台风也在海上活跃！目前，西北太平洋上台风“苏拉”“达维”“双台共舞”。\n据中央气象台消息，今年第10号台风“达维”于25日05时在西北太平洋洋面上生成。预计，“达维”将以每小时25-30公里的速度向东北方向移动，强度变化不大。而今年第9号台风“苏拉”，于24日下午生成。“苏拉”附近海温接近30℃，有季风水汽的支持，利于其结构维持和继续整合，后续“苏拉”可能加强为下一个超强台风。\n今年第9号台风“苏拉”和第10号台风“达维”都已生成，据最新预报显示台风“达维”未来对我国无影响，公众需着重关注台风“苏拉”的未来动向。今日8时，台风“苏拉”位于菲律宾马尼拉北偏东方向约650公里，强度为强热带风暴（10级，25米/秒），中心最低气压为985百帕。预计，“苏拉”将先在菲律宾吕宋岛东北部洋面徘徊，29日开始向北偏西方向移动，逐渐向台湾东部沿海靠近，最强可达强台风级或超强台风级（45~52m/s，14~16级）。";
     
     _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, 500)];
     _textView.backgroundColor = UIColor.lightGrayColor;
     [self.view addSubview:_textView];
     
     _dataArr = [self pagingWithContentString:txt contentSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 500) textAttribute:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang TC" size:20]}];
     
     _textView.attributedText = _dataArr[0];
     
 }

 - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
     _textView.attributedText = _dataArr[1];
 }


 @end
 */
