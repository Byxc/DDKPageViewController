//
//  DDKBasePageViewController.m
//  DDKanQiu
//
//  Created by 白云 on 2018/5/24.
//  Copyright © 2018年 jebatapp. All rights reserved.
//

#import "DDKPageViewController.h"
#import <objc/runtime.h>

#define kChildShowNotification @"kDDKBasePageViewControllerChildShowNotification"
#define kPrivatePageIndexKey "kPrivatePageIndexKey"

@interface UIViewController (DDKPage)

@property (nonatomic, assign) NSInteger privatePageIndex;

- (void)swizzledViewDidAppear;

@end

@interface DDKPageViewController () <UIPageViewControllerDataSource>

@property(nonatomic,strong)NSCache *childCache;
@property (nonatomic, assign) BOOL isBusy;

@end

@implementation DDKPageViewController

#pragma mark - Life
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary<NSString *,id> *)options {
    if (self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options]) {
        [self addNotification];
        [self setOfView];
    }
    return self;
}

- (void)setOfView {
    _currentPageIndex = 0;
    _childCache = [[NSCache alloc] init];
    _childCache.countLimit = 10;
    self.dataSource = self;
}

#pragma mark - overwrite
- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    for (NSInteger i = 1; i <= viewControllers.count; i ++) {
        UIViewController *viewController = viewControllers[i-1];
        [viewController swizzledViewDidAppear];
        if (viewController.privatePageIndex == NSNotFound) {
            NSInteger pageIndex = _currentPageIndex;
            // 已经初始化
            if (_childCache != nil) {
                if (direction == UIPageViewControllerNavigationDirectionForward) {
                    pageIndex += i;
                }
                else {
                    pageIndex -= i;
                }
            }
            viewController.privatePageIndex = pageIndex;
            [self.childCache setObject:viewController forKey:[NSString stringWithFormat:@"%zd",pageIndex]];
        }
    }
    [super setViewControllers:viewControllers direction:direction animated:animated completion:completion];
}

#pragma mark - Notification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needUpdatePageIndexWithNotification:) name:kChildShowNotification object:nil];
}

- (void)needUpdatePageIndexWithNotification:(NSNotification *)sender {
    UIViewController *vc = sender.object;
    if ([vc isKindOfClass:[UIViewController class]]) {
        if (self.pageSource && [self.pageSource respondsToSelector:@selector(pageView:indexUpdate:)]) {
            __weak typeof(self) weakSelf = self;
            NSInteger index = vc.privatePageIndex;
            _currentPageIndex = index;
            [self.pageSource pageView:weakSelf indexUpdate:index];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isBusy = NO;
    });
}

#pragma mark - Data
- (UIViewController *)viewControllerWithIndex:(NSInteger)index {
    UIViewController *vc = nil;
    vc = [self.childCache objectForKey:[NSString stringWithFormat:@"%zd",index]];
    if ([vc isKindOfClass:[UIViewController class]]) {
        NSLog(@"缓存");
        return vc;
    }
    if (self.pageSource != nil && [self.pageSource respondsToSelector:@selector(pageView:loadIndex:)]) {
        vc = [self.pageSource pageView:self loadIndex:index];
        if (vc != nil) {
            [vc swizzledViewDidAppear];
            vc.privatePageIndex = index;
            [self.childCache setObject:vc forKey:[NSString stringWithFormat:@"%zd",index]];
        }
    }
    return vc;
}

- (NSInteger)indexOfViewController:(UIViewController *)viewController {
    NSInteger index = NSNotFound;
    index = viewController.privatePageIndex;
    return index;
}

- (void)preloadChildCacheWithIndex:(NSInteger)pageIndex {
    dispatch_queue_t gobalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(gobalQueue, ^{
        [self viewControllerWithIndex:pageIndex];
    });
}

#pragma mark - Setter
- (void)setCurrentPageIndex:(NSInteger)currentPageIndex {
    if (self.isBusy) {
        return;
    }
    self.isBusy = YES;
    UIViewController *vc = [self viewControllerWithIndex:currentPageIndex];
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    if (currentPageIndex < _currentPageIndex) {
        direction = UIPageViewControllerNavigationDirectionReverse;
    }
    [super setViewControllers:@[vc] direction:direction animated:YES completion:nil];
    
    _currentPageIndex = currentPageIndex;
}

#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger index = [self indexOfViewController:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    return [self viewControllerWithIndex:index+1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger index = [self indexOfViewController:viewController];
    if (index == 0 || index == NSNotFound) {
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

#pragma mark - private property
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
