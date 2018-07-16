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

@end

@implementation ViewController

- (void)dealloc {
    NSLog(@"dealloc-%@",self.class);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // DDKPageViewController
    _pageViewController = [[DDKPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.view.frame = self.view.bounds;
    _pageViewController.pageSource = self;
    [self addChildViewController:_pageViewController];
    [self.view insertSubview:_pageViewController.view atIndex:0];
    [_pageViewController didMoveToParentViewController:self];
    [_pageViewController setCurrentPageIndex:0];
}

#pragma mark - Action
- (IBAction)lastButtonClickAction:(id)sender {
    _pageViewController.currentPageIndex -= 1;
}

- (IBAction)nexButtonClickAction:(id)sender {
    _pageViewController.currentPageIndex += 1;
}

#pragma mark - DDKPageViewControllerPageSource
- (UIViewController *)pageView:(DDKPageViewController *)pageView loadIndex:(NSInteger)index {
    UIViewController *viewController = nil;
    if (0 == index%2) {
        FirstViewController *first = [FirstViewController new];
        viewController = first;
    }
    else {
        SecondViewController *second = [SecondViewController new];
        viewController = second;
    }
    return viewController;
}

- (void)pageView:(DDKPageViewController *)pageView indexUpdate:(NSInteger)index {
    self.title = [NSString stringWithFormat:@"%zd",index];
}

@end
