//
//  DDKPageViewController.m
//
//  Created by 白云 on 2018/5/24.
//  Copyright © 2018年 DDKPageViewController. All rights reserved.
//

#import "DDKPageViewController.h"
#import <objc/runtime.h>

static NSString *const kChildShowNotification = @"kDDKPageViewControllerChildShowNotification";
static char *const kPrivatePageIndexKey = "kPrivatePageIndexKey";

@interface UIViewController (DDKPage)

@property (nonatomic, assign) NSInteger privatePageIndex;

- (void)swizzledViewDidAppear;

@end

@interface DDKPageViewController () <UIPageViewControllerDataSource>
/// 子控制器缓存
@property(nonatomic,strong)NSMutableDictionary *childCache;
/// 索引缓存
@property (nonatomic, strong) NSMutableArray<NSString *> *pageIndexArray;
/// 繁忙标识
@property (nonatomic, assign) BOOL isBusy;
/// 待切换页面索引值
@property (nonatomic, strong) NSNumber *waitSetIndex;
/// 操作间隔
@property (nonatomic, assign) NSTimeInterval operationDelay;

@end

@implementation DDKPageViewController

#pragma mark - Life
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary<NSString *,id> *)options {
    if (self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options]) {
        [self addNotification];
        [self initializeCurrentConfig];
    }
    return self;
}

/// 初始化配置
- (void)initializeCurrentConfig {
    _currentPageIndex = 0;
    _maxCacheCount = 10;
    _operationDelay = 0.3;
    _childCache = [[NSMutableDictionary alloc] init];
    _pageIndexArray = [NSMutableArray array];
    self.dataSource = self;
}

- (void)resetBusyFlag {
    self.isBusy = NO;
    // 如果存在等待切换的页面，并且不为当前的页面，自动切换到改页面并清除记录
    if (nil != _waitSetIndex) {
        [self setCurrentPageIndex:_waitSetIndex.integerValue];
        _waitSetIndex = nil;
    }
}

#pragma mark - Cache
- (void)addCacheWithViewController:(UIViewController *)viewController pageIndex:(NSInteger)index {
    NSString *pageIndex = [NSString stringWithFormat:@"%zd",index];
    // 缓存viewController
    [self.childCache setObject:viewController forKey:pageIndex];
    // 已存在
    if ([self.pageIndexArray containsObject:pageIndex]) {
        // 先移除再添加
        [self.pageIndexArray removeObject:pageIndex];
    }
    // 保存页索引
    [self.pageIndexArray addObject:pageIndex];
    
    // 检查并清理缓存
    [self checkChildCacheLimit];
}

/// 检查缓存数量
- (void)checkChildCacheLimit {
    // 循环移除
    while (self.pageIndexArray.count > _maxCacheCount) {
        // 按顺序移除，优先保留最近使用的页面
        NSString *pageIndex = self.pageIndexArray.firstObject;
        [self.childCache removeObjectForKey:pageIndex];
        [self.pageIndexArray removeObjectAtIndex:0];
    }
}

#pragma mark - Overwrite
- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    if (nil == viewControllers) {
        return;
    }
    for (NSInteger i = 1; i <= viewControllers.count; i ++) {
        UIViewController *viewController = viewControllers[i-1];
        [viewController swizzledViewDidAppear];
        if (NSNotFound == viewController.privatePageIndex) {
            NSInteger pageIndex = _currentPageIndex;
            // 已经初始化
            if (nil != _childCache) {
                if (UIPageViewControllerNavigationDirectionForward == direction) {
                    pageIndex += i;
                }
                else {
                    pageIndex -= i;
                }
            }
            viewController.privatePageIndex = pageIndex;
            [self addCacheWithViewController:viewController pageIndex:pageIndex];
        }
    }
    [super setViewControllers:viewControllers direction:direction animated:animated completion:completion];
}

#pragma mark - Notification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needUpdatePageIndexWithNotification:) name:kChildShowNotification object:nil];
}

- (void)needUpdatePageIndexWithNotification:(NSNotification *)sender {
    UIViewController *viewController = sender.object;
    if ([viewController isKindOfClass:[UIViewController class]] && viewController.parentViewController == self) {
        if (self.pageSource && [self.pageSource respondsToSelector:@selector(pageView:indexUpdate:)]) {
            __weak typeof(self) weakSelf = self;
            NSInteger index = viewController.privatePageIndex;
            _currentPageIndex = index;
            [self.pageSource pageView:weakSelf indexUpdate:index];
        }
    }
}

#pragma mark - DataSource
- (UIViewController *)viewControllerWithIndex:(NSInteger)index {
    UIViewController *viewController = nil;
    viewController = [self.childCache objectForKey:[NSString stringWithFormat:@"%zd",index]];
    if ([viewController isKindOfClass:[UIViewController class]]) {
        return viewController;
    }
    if (nil != self.pageSource && [self.pageSource respondsToSelector:@selector(pageView:loadIndex:)]) {
        viewController = [self.pageSource pageView:self loadIndex:index];
        if (nil != viewController) {
            [viewController swizzledViewDidAppear];
            viewController.privatePageIndex = index;
            [self addCacheWithViewController:viewController pageIndex:index];
        }
    }
    return viewController;
}

- (NSInteger)indexOfViewController:(UIViewController *)viewController {
    NSInteger index = NSNotFound;
    index = viewController.privatePageIndex;
    return index;
}

#pragma mark - Setter
- (void)setCurrentPageIndex:(NSInteger)currentPageIndex {
    if (self.isBusy) {
        // 记录最后一次需要切换的页面位置
        _waitSetIndex = [NSNumber numberWithInteger:currentPageIndex];
        // 取消重置操作
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetBusyFlag) object:nil];
        // 重新设置延时重置
        [self performSelector:@selector(resetBusyFlag) withObject:nil afterDelay:_operationDelay inModes:@[NSDefaultRunLoopMode]];
        return;
    }
    self.isBusy = YES;
    // 设置延时重置
    [self performSelector:@selector(resetBusyFlag) withObject:nil afterDelay:_operationDelay inModes:@[NSDefaultRunLoopMode]];
    UIViewController *viewController = [self viewControllerWithIndex:currentPageIndex];
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    if (currentPageIndex < _currentPageIndex) {
        direction = UIPageViewControllerNavigationDirectionReverse;
    }
    if (nil != viewController) {
        [super setViewControllers:@[viewController] direction:direction animated:YES completion:nil];
    }
    
    _currentPageIndex = currentPageIndex;
}

- (void)setMaxCacheCount:(NSUInteger)maxCacheCount {
    _maxCacheCount = maxCacheCount;
    [self checkChildCacheLimit];
}

- (void)setPageSource:(id<DDKPageViewControllerPageSource>)pageSource {
    _pageSource = pageSource;
    [self.pageIndexArray removeAllObjects];
    [self.childCache removeAllObjects];
    [self setCurrentPageIndex:_currentPageIndex];
}

#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = [self indexOfViewController:viewController];
    if (NSNotFound == index) {
        return nil;
    }
    return [self viewControllerWithIndex:index+1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = [self indexOfViewController:viewController];
    if (0 == index || NSNotFound == index) {
        return nil;
    }
    return [self viewControllerWithIndex:index-1];
}

@end

@implementation UIViewController (DDKPage)

- (void)swizzled_viewDidAppear:(BOOL)animated {
    [self swizzled_viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;
    // 通知视图已呈现
    [[NSNotificationCenter defaultCenter] postNotificationName:kChildShowNotification object:weakSelf];
}

- (void)swizzledViewDidAppear {
    // 必须确保只交换一次
    if (![self.class classHasSwizzledMethod:@selector(swizzled_viewDidAppear:)]) {
        [self.class ddk_swizzleMethod:@selector(viewDidAppear:) newMethod:@selector(swizzled_viewDidAppear:)];
    }
}

#pragma mark - swizzle
+ (void)ddk_swizzleMethod:(SEL)origSel newMethod:(SEL)newSel {
    Class cls = self;
    Method origMethod = class_getInstanceMethod(cls, origSel);
    Method newMethod = class_getInstanceMethod(cls, newSel);
    
    if (!origMethod || !newMethod) {
        return;
    }
    if (class_addMethod(cls, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(cls, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else if (class_addMethod(cls, newSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        newMethod = class_getInstanceMethod(cls, newSel);
        method_exchangeImplementations(origMethod, newMethod);
    }
}

+ (BOOL)classHasSwizzledMethod:(SEL)sel {
    BOOL hasContain = NO;
    NSString *key = [NSString stringWithUTF8String:sel_getName(sel)];
    
    unsigned int num;
    Method *method = class_copyMethodList(self.class, &num);
    // 遍历查找是否存在方法
    for (NSInteger i = 0; i < num; i ++) {
        Method meth = method[i];
        SEL sel = method_getName(meth);
        const char *name = sel_getName(sel);
        NSString *selName = [NSString stringWithUTF8String:name];
        if ([selName isEqualToString:key]) {
            hasContain = YES;
            break;
        }
    }
    // 释放
    free(method);
    return hasContain;
}

#pragma mark - Private Property
- (void)setPrivatePageIndex:(NSInteger)privatePageIndex {
    objc_setAssociatedObject(self, kPrivatePageIndexKey, [NSNumber numberWithInteger:privatePageIndex], OBJC_ASSOCIATION_ASSIGN);
}

- (NSInteger)privatePageIndex {
    NSNumber *privatePageIndex = objc_getAssociatedObject(self, kPrivatePageIndexKey);
    if (privatePageIndex) {
        return privatePageIndex.integerValue;
    }
    return NSNotFound;
}

@end
