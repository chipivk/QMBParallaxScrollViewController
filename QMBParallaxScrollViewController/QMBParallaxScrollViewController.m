//
//  QMBParallaxScrollViewController.m
//  QMBParallaxScrollView-Sample
//
//  Created by Toni Möckel on 02.11.13.
//  Copyright (c) 2013 Toni Möckel. All rights reserved.
//

#import "QMBParallaxScrollViewController.h"


static void * QMBParallaxScrollViewControllerFrameContext = &QMBParallaxScrollViewControllerFrameContext;

@interface QMBParallaxScrollViewController () {
    CGFloat _startTopHeight;
    CGFloat _lastOffsetY;
}

@property (readwrite, nonatomic, strong) UIViewController *topViewController;
@property (readwrite, nonatomic, strong) UIViewController *bottomViewController;

@property (readwrite, nonatomic, strong) UIView *topView;
@property (readwrite, nonatomic, strong) UIView *bottomView;

@property (readwrite, nonatomic, assign, getter = isAnimating) BOOL animating;

@end

@implementation QMBParallaxScrollViewController

#pragma mark - Lifecycle

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    self.targetHeight = 180;
    self.maxHeight = 460;

    return self;
}

#pragma mark - QMBParallaxScrollViewController Methods

- (void)setupWithTopViewController:(UIViewController *)topViewController topHeight:(CGFloat)height bottomViewController:(UIViewController *)bottomViewController {
    _topHeight = height;
    _startTopHeight = _topHeight;

    self.topViewController = topViewController;
    self.bottomViewController = bottomViewController;

    self.topHeight = self.targetHeight;
}

#pragma mark - Properties

- (void)setTopViewController:(UIViewController *)topViewController {
    [_topViewController removeFromParentViewController];

    _topViewController = topViewController;

    [_topViewController willMoveToParentViewController:self];
    [self addChildViewController:_topViewController];

    self.topView = _topViewController.view;

    [_topViewController didMoveToParentViewController:self];
}

- (void)setBottomViewController:(UIViewController *)bottomViewController {
    [_bottomViewController removeFromParentViewController];

    _bottomViewController = bottomViewController;

    [_bottomViewController willMoveToParentViewController:self];
    [self addChildViewController:_bottomViewController];

    self.bottomView = _bottomViewController.view;

    [_bottomViewController didMoveToParentViewController:self];
}

- (void)setTopView:(UIView *)topView {
    [_topView removeFromSuperview];

    _topView = topView;

    [self.view addSubview:_topView];
}

- (void)setBottomView:(UIView *)bottomView {
    [_bottomView removeFromSuperview];

    _bottomView = bottomView;

    [self.view addSubview:_bottomView];
}

- (void)setObservedScrollView:(UIScrollView *)observedScrollView
{
    if (_observedScrollView.delegate == self) _observedScrollView.delegate = nil;
    _observedScrollView.contentOffset = CGPointZero;

    _observedScrollView = observedScrollView;

    _observedScrollView.delegate = self;
    _observedScrollView.alwaysBounceVertical = YES;
}

- (void)setTopHeight:(CGFloat)topHeight {
    _topHeight = round(MAX(0, MIN(self.maxHeight, topHeight)));

    CGRect top, bottom;

    CGRect bounds = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(20, 0, 0, 0));

    CGRectDivide(bounds, &top, &bottom, self.topHeight, CGRectMinYEdge);

    self.topView.frame = top;
    self.bottomView.frame = bottom;

}

- (void)setTopHeight:(CGFloat)topHeight animated:(BOOL)animated {
    [UIView
        animateKeyframesWithDuration:animated ? 0.2 : 0
        delay:0
        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            self.topHeight = topHeight;
        }
        completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSParameterAssert(self.observedScrollView == scrollView);

    self.topHeight -= scrollView.contentOffset.y;

    if (self.topHeight > 0) {
        scrollView.contentOffset = CGPointZero;
        scrollView.showsVerticalScrollIndicator = NO;
    } else {
        scrollView.showsVerticalScrollIndicator = YES;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSParameterAssert(self.observedScrollView == scrollView);

    // If the scroll view is at rest, snap to the nearest position
    if (velocity.y == 0) {
        if (self.topHeight < self.targetHeight * 0.75) {
            return [self setTopHeight:0 animated:YES];
        }

        if (self.topHeight < self.targetHeight + (self.maxHeight - self.targetHeight) / 2) {
            return [self setTopHeight:self.targetHeight animated:YES];
        }

        return [self setTopHeight:self.maxHeight animated:YES];
    }

    if (velocity.y < 0) {
        // XXX: manipulate the targetContentOffset to keep the momentum going
        targetContentOffset->y = -200;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.topHeight < self.targetHeight * 0.75) {
        return [self setTopHeight:0 animated:YES];
    }

    if (self.topHeight < self.targetHeight + (self.maxHeight - self.targetHeight) / 2) {
        return [self setTopHeight:self.targetHeight animated:YES];
    }

    [self setTopHeight:self.maxHeight animated:YES];
}

@end
