//
//  ReadViewController.m
//  SecretNovelsPro
//
//  Created by zhaohongbin on 2023/8/25.
//  Copyright © 2023 zhaohongbin. All rights reserved.
//

#import "ReadViewController.h"
#import "DCFileTool.h"
#import "PageController.h"

#define statusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height
@interface ReadViewController ()

@property(retain, nonatomic) UISlider* readerSlider;
@property (nonatomic, strong) NSMutableArray *udData;
@property (nonatomic, strong) NSMutableDictionary *oriDict;
@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, assign) int readType;

@end

@implementation ReadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithRed:1.00f green:0.97f blue:0.85f alpha:1.00f];;
    
    //    NSString *str = @"0000\n第1章.*\r\n1111\n第2章.*\r\n2222\n第3章.*\r\n3333";
    //    NSArray *arr = [DCFileTool getChapterArrWithString:str];
    //    NSLog(@"%@",arr);
    
    self.dataSource = self;
    PageController *page = [[PageController alloc] init];
    page.content = self.dataArr.firstObject;
    [self setViewControllers:@[page] direction:UIPageViewControllerNavigationDirectionForward animated:true completion:nil];
    [self configNavigationBar];
}

- (UITextView *)getTextViewFromSubController:(UIViewController *)controller{
    for (UIView *subView in controller.view.subviews) {
        if([subView isKindOfClass:[UITextView class]]){
            return (UITextView *)subView;
        }
    }
    return nil;
}



#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    PageController *page = [[PageController alloc] init];
    page.content = _dataArr[0];
    return page;
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    return nil;
}

#pragma mark - scrollview代理
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    if(_readerSlider.isHighlighted){
//        return;
//    }
//    if(self.readType == 1){
//        if(scrollView == _readTXTView){
//            float value = (scrollView.contentOffset.y * 1.0) / (scrollView.contentSize.height - scrollView.frame.size.height);
//            value = MAX(0, MIN(1, value));
//            _readerSlider.value = value;
//        }
//    }
//
//}
//
//#pragma mark - slider代理
- (void) pressSlider:(UISlider*) slider {
    if(self.readType == 0){
        PageController *page = [self viewControllers][0];
        [page.readTXTView setContentOffset:CGPointMake(0, (page.readTXTView.contentSize.height - page.readTXTView.frame.size.height) * slider.value) animated:false];
    }
}

#pragma mark - Data

- (NSMutableArray *)udData{
    if(!_udData){
        _udData = [[[NSUserDefaults standardUserDefaults] valueForKey:@"names"] mutableCopy];
    }
    return _udData;
}

- (NSMutableDictionary *)oriDict{
    if(!_oriDict){
        _oriDict = [self.udData[self.row] mutableCopy];
    }
    return _oriDict;
}

- (NSString *)curOriginString{
    return self.oriDict[@"value"];
}

- (int)curReadType{
    return [self.oriDict[@"readType"] intValue];
}

- (CGFloat)curOffSet{
    return [self.oriDict[@"offsety"] floatValue];
}


- (NSArray *)dataArr{
    if(!_dataArr){
        NSString *value = [self curOriginString];
        if([self curReadType] == 0){
            _dataArr = @[value];
        }else if ([self curReadType] == 1){
            
        }else{
            
        }
    }
    return _dataArr;
}


- (void)refreshReadType:(int)type{
    self.oriDict[@"readType"] = [NSString stringWithFormat:@"%d",type];
    [self.udData removeObjectAtIndex:self.row];
    [self.udData insertObject:self.oriDict atIndex:self.row];
    [[NSUserDefaults standardUserDefaults] setObject:self.udData forKey:@"names"];
#warning 这里去更新type
}

- (void)refreshOffsety{
//    _oriDict[@"offsety"] = [NSString stringWithFormat:@"%d",(int)_readTXTView.contentOffset.y];
//    [_mArr removeObjectAtIndex:_bgBtn.tag - 1000];
//    [_mArr insertObject:dict atIndex:_bgBtn.tag - 1000];
//    [[NSUserDefaults standardUserDefaults] setObject:_mArr forKey:@"names"];
//    _readTXTView.hidden = YES;
}

#pragma mark - UI

- (void)configNavigationBar{
    UIView *navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, statusBarHeight + 44)];
    navBar.backgroundColor = UIColor.whiteColor;
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(0, statusBarHeight, 44, 44)];
    [btn2 addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [btn2 setTitleColor:UIColor.linkColor forState:UIControlStateNormal];
    [btn2 setTitle:@"Back" forState:UIControlStateNormal];
    [self.view addSubview:btn2];
    
    [self.view addSubview:self.readerSlider];
    
    UIButton *btn3 = [[UIButton alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width - 44, statusBarHeight, 44, 44)];
    [btn3 addTarget:self action:@selector(switchType) forControlEvents:UIControlEventTouchUpInside];
    [btn3 setTitle:@"Switch" forState:UIControlStateNormal];
    [btn3 setTitleColor:UIColor.linkColor forState:UIControlStateNormal];
    btn3.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:btn3];
}

- (void)back{
    [self dismissViewControllerAnimated:true completion:nil];
}
- (void)switchType{
    
}

- (UISlider *)readerSlider {
    if (_readerSlider == nil) {
        //滑动条
        _readerSlider = [[UISlider alloc] init];
        //设置位置，宽度可设置，但高度不可设置
        _readerSlider.frame = CGRectMake(50, statusBarHeight, UIScreen.mainScreen.bounds.size.width - 100, 44);
        _readerSlider.maximumValue = 1;
        _readerSlider.minimumValue = 0;
        _readerSlider.minimumTrackTintColor = [UIColor blueColor];
        _readerSlider.maximumTrackTintColor = [UIColor greenColor];
        [_readerSlider addTarget:self action:@selector(pressSlider:) forControlEvents:UIControlEventValueChanged];
        
    }
    return _readerSlider;
}


@end
