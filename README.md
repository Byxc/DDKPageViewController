# DDKPageViewController

一个使用UIPageViewController封装实现的分页控件，在UIPageViewController的基础上做了一些改善以满足日常简单的分页需求

[demo](https://github.com/Byxc/DDKPageViewController/tree/master/Demo)

### 导入

#### cocoapods方式

```
pod 'DDKPageViewController'

// 在使用的类中导入头文件
#import <DDKPageViewController.h>
```

#### 手动导入

请将相关[文件下载](https://github.com/Byxc/DDKPageViewController/tree/master/DDKPageViewController)并导入到项目中

```
// 在使用的类中导入头文件
#import "DDKPageViewController.h"
```

### 使用方法

使用方法基本和UIPageViewController一致，但需要使用``pageSource``中的代理方法来代替``UIPageViewController``中原有的``pageViewController: viewControllerBeforeViewController: ``和 ``pageViewController: viewControllerAfterViewController : ``方法，使用方法如下：

1. 初始化

```
// 使用UIPageViewController相同的创建方法
DDKPageViewController *pageViewController = [[DDKPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
// 设置控件大小
pageViewController.view.frame = pageViewFrame;
// 设置数据代理(替代dataSource中的部分方法)
pageViewController.pageSource = self;
[self.view addSubView:pageViewController.view];
[pageViewController didMoveToParentViewController:self];


```

2. 代理方法

```
#pragma mark - DDKPageViewControllerPageSource
// 必选方法，需要在此方法中返回指定索引值的UIViewController，返回nil代表当前页索引无效
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
// 可选方法，用于通知页索引值的更新
- (void)pageView:(DDKPageViewController *)pageView indexUpdate:(NSInteger)index {
    self.title = [NSString stringWithFormat:@"%zd",index];
}

```

3. 翻页

使用属性``currentPageIndex``或者``setCurrentPageIndex方法``设置当前需要呈现的UIViewController的页索引值，DDKPageViewController将会通过调用代理方法``pageView: loadIndex: ``获取并设置给定索引值的UIViewController

```
#pragma mark - Action
- (IBAction)lastButtonClickAction:(id)sender {
    _pageViewController.currentPageIndex -= 1;
}

- (IBAction)nexButtonClickAction:(id)sender {
    _pageViewController.currentPageIndex += 1;
}
```

### 说明

该控件是本人在项目中使用UIPageViewController时对UIPageViewController的封装和处理，可以满足常见的分页功能，使用过程中如遇问题，欢迎和我[联系](mailto:924698172@qq.com)，如果有好的建议，欢迎告知😊。


