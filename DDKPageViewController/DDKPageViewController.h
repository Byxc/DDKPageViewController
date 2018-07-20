//
//  DDKPageViewController.h
//
//  Created by 白云 on 2018/5/24.
//  Copyright © 2018年 DDKPageViewController. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DDKPageViewControllerPageSource;

@interface DDKPageViewController : UIPageViewController
/// 数据代理
@property (nonatomic, weak) id<DDKPageViewControllerPageSource> pageSource;
/// 当前索引
@property(nonatomic,assign)NSInteger currentPageIndex;
/// 最大缓存页数(默认为10)
@property (nonatomic, assign) NSUInteger maxCacheCount;

/**
 获取指定索引值的视图控制器

 @param index 索引值
 @return UIViewController
 */
- (UIViewController *)viewControllerWithIndex:(NSInteger)index;

@end

@protocol DDKPageViewControllerPageSource <NSObject>

@required
/**
 加载对应索引值的视图控制器

 @param index 索引值
 @return UIViewController
 */
- (UIViewController *)pageView:(DDKPageViewController *)pageView loadIndex:(NSInteger)index;

@optional
/**
 索引值更新

 @param index 索引值
 */
- (void)pageView:(DDKPageViewController *)pageView indexUpdate:(NSInteger)index;

@end
