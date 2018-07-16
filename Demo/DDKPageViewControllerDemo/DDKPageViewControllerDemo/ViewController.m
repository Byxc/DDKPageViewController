//
//  ViewController.m
//  DDKPageViewController
//
//  Created by 白云 on 2018/7/12.
//  Copyright © 2018年 白云. All rights reserved.
//

#import "ViewController.h"
#import "DDKPageViewController.h"
#import "FirstViewController.h"
#import "SecondViewController.h"

@interface ViewController () <DDKPageViewControllerPageSource>

@property (nonatomic, strong) DDKPageViewController *pageViewController;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL isPositive;

@end

@implementation ViewController

- (void)dealloc {
    NSLog(@"dealloc-%@",self.class);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_timer invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isPositive = YES;
    
    // DDKPageViewController
    _pageViewController = [[DDKPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.view.frame = self.view.bounds;
    _pageViewController.pageSource = self;
    [self addChildViewController:_pageViewController];
    [self.view insertSubview:_pageViewController.view atIndex:0];
    [_pageViewController didMoveToParentViewController:self];
    [_pageViewController setCurrentPageIndex:0];
    // Timer
    _timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerCountAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

#pragma mark - Action
- (IBAction)lastButtonClickAction:(id)sender {
    _pageViewController.currentPageIndex -= 1;
}

- (IBAction)nexButtonClickAction:(id)sender {
    _pageViewController.currentPageIndex += 1;
}

- (void)timerCountAction {
    if (_isPositive) {
        _pageViewController.currentPageIndex += 1;
    }
    else {
        _pageViewController.currentPageIndex -= 1;
    }
    if (_pageViewController.currentPageIndex == 0) {
        _isPositive = YES;
    }
    if (_pageViewController.currentPageIndex == 100) {
        _isPositive = NO;
    }
}

#pragma mark - DDKBasePageViewControllerPageSource
- (UIViewController *)pageView:(DDKPageViewController *)pageView loadIndex:(NSInteger)index {
    UIViewController *viewController = nil;
    if (0 == index%2) {
        FirstViewController *first = [FirstViewController new];
        first.index = index;
        viewController = first;
    }
    else {
        SecondViewController *second = [SecondViewController new];
        second.index = index;
        viewController = second;
    }
    return viewController;
}

- (NSInteger)pageView:(DDKPageViewController *)pageView indexWithViewController:(UIViewController *)viewController {
    FirstViewController *customController = (FirstViewController *)viewController;
    return customController.index;
}

- (void)pageView:(DDKPageViewController *)pageView indexUpdate:(NSInteger)index {
    self.title = [NSString stringWithFormat:@"%zd",index];
}

@end
