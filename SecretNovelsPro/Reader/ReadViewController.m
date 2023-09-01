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
@property (nonatomic, strong) NSArray *pages;

@end

@implementation ReadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:1.00f green:0.97f blue:0.85f alpha:1.00f];;
    self.dataSource = self;
    self.delegate = self;
    [self handleViewControllers];
    [self configNavigationBar];
    [self refreshContent:0 controller:self.viewControllers[0]];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSLog(@"获取sliderValue:%f",[self oriSliderValue]);
    self.readerSlider.value = [self oriSliderValue];
    [self pressSlider:self.readerSlider];
}

- (void)handleViewControllers{
    PageController *page1 = [[PageController alloc] init];
    PageController *page2 = [[PageController alloc] init];
    PageController *page3 = [[PageController alloc] init];
    self.pages = @[page1,page2,page3];
    [self setViewControllers:@[page1] direction:UIPageViewControllerNavigationDirectionForward animated:true completion:nil];
}


#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    PageController *curVC = (PageController *)viewController;
    if(curVC.index <= 0){
        return nil;
    }
    NSUInteger curIndex = [self.pages indexOfObject:viewController];
    PageController *beforeVC = curIndex > 0 ? _pages[curIndex - 1] : _pages.lastObject;
    beforeVC.index = curVC.index - 1;
    NSLog(@"pageIndex:%d  当前控制器:%lu", curVC.index, (unsigned long)curIndex);
    NSLog(@"这里去设置了beforeVC");
    [self refreshContent:beforeVC.index controller:beforeVC];
    return beforeVC;
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    NSArray *dataArr = [self curReadType] == 0 ? @[[self curOriginString]] : [self curPageArray];
    PageController *curVC = (PageController *)viewController;
    if(curVC.index >= dataArr.count - 1){
        return nil;
    }
    NSUInteger curIndex = [self.pages indexOfObject:viewController];
    PageController *afterVC = curIndex < _pages.count - 1 ? _pages[curIndex + 1] : _pages.firstObject;
    afterVC.index = curVC.index + 1;
    NSLog(@"pageIndex:%d  当前控制器:%lu", curVC.index, (unsigned long)curIndex);
    NSLog(@"这里去设置了afterVC");
    [self refreshContent:afterVC.index controller:afterVC];
    return afterVC;
}

- (void)refreshContent:(int)pageIndex controller:(PageController *)controller{
    NSArray *dataArr = [self curReadType] == 0 ? @[[self curOriginString]] : [self curPageArray];
    PageController *curVC = (PageController *)controller;
    curVC.content = dataArr[pageIndex];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed{
    if(completed && [self curReadType] == 1){
        PageController *curVC = (PageController *)pageViewController.viewControllers.firstObject;
        self.readerSlider.value = MAX(curVC.index * 1.0 / ([self curPageArray].count - 1), 0);
    }
}

#pragma mark - scrollview代理
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if(_readerSlider.isHighlighted){
        return;
    }
    if([self curReadType] == 0){
        float value = (scrollView.contentOffset.y * 1.0) / (scrollView.contentSize.height - scrollView.frame.size.height);
        value = MAX(0, MIN(1, value));
        _readerSlider.value = value;
    }
}

#pragma mark - slider代理
- (void) pressSlider:(UISlider*) slider {
    if([self curReadType] == 0){
        PageController *page = [self viewControllers][0];
        [page.readTXTView setContentOffset:CGPointMake(0, (page.readTXTView.contentSize.height - page.readTXTView.frame.size.height) * slider.value) animated:false];
    }else if([self curReadType] == 1){
        PageController *page = [self viewControllers][0];
        int nIndex = MAX((int)(([self curPageArray].count - 1) * slider.value), 0);
        if(page.index == nIndex){
            return;
        }
        page.index = nIndex;
        //调用该api后,再次滑动时,会触发代理去寻找before和after控制器. 不调用会出现页码错乱
        [self setViewControllers:@[page] direction:UIPageViewControllerNavigationDirectionForward animated:false completion:nil];
        [self refreshContent:nIndex controller:page];
        NSLog(@"pageIndex:%d  当前控制器:%lu", nIndex, (unsigned long)[_pages indexOfObject:page]);
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

- (CGFloat)oriSliderValue{
    return [self.oriDict[@"sliderValue"] floatValue];
}

- (NSArray *)curPageArray{
    return self.oriDict[@"pageArray"] ?: @[];
}

- (void)refreshReadType:(int)type{
    if(type == 1){
        if([self curPageArray].count == 0){
            CGSize contentSize = ((PageController *)self.viewControllers.firstObject).readTXTView.frame.size;
            NSArray *pageDataArray = [DCFileTool pagingWithContentString:[self curOriginString] contentSize:contentSize textAttribute:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang TC" size:20]}];
            self.oriDict[@"pageArray"] = pageDataArray;
        }
    }
    //更新数据源
    self.oriDict[@"readType"] = [NSString stringWithFormat:@"%d",type];
    [self.udData removeObjectAtIndex:self.row];
    [self.udData insertObject:self.oriDict atIndex:self.row];
    [[NSUserDefaults standardUserDefaults] setObject:self.udData forKey:@"names"];
    //更新文本
    [self refreshContent:0 controller:self.viewControllers.firstObject];
}

- (void)refreshReaderSliderValue{
    self.oriDict[@"sliderValue"] = [NSString stringWithFormat:@"%f",_readerSlider.value];
    [self.udData removeObjectAtIndex:self.row];
    [self.udData insertObject:self.oriDict atIndex:self.row];
    [[NSUserDefaults standardUserDefaults] setObject:self.udData forKey:@"names"];
    NSLog(@"保存sliderValue:%f",_readerSlider.value);
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
    [self refreshReaderSliderValue];
    [self dismissViewControllerAnimated:true completion:nil];
}
- (void)switchType{
    if([self curReadType] == 0){
        [self refreshReadType:1];
    }else if ([self curReadType] == 1){
        [self refreshReadType:0];
    }
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
