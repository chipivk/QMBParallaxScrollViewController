//
//  QMBParallaxScrollViewController.m
//  QMBParallaxScrollView-Sample
//
//  Created by Toni Möckel on 02.11.13.
//  Copyright (c) 2013 Toni Möckel. All rights reserved.
//

#import "QMBParallaxScrollViewController.h"


static void * QMBParallaxScrollViewControllerScrollViewContext = &QMBParallaxScrollViewControllerScrollViewContext;
static void * QMBParallaxScrollViewControllerFrameContext = &QMBParallaxScrollViewControllerFrameContext;

@interface QMBParallaxScrollViewController () {
    CGFloat _startTopHeight;
    CGFloat _lastOffsetY;
}

@property (readwrite, nonatomic, strong) UIViewController *topViewController;
@property (readwrite, nonatomic, strong) UIViewController *bottomViewController;

@property (readwrite, nonatomic, strong) UIView *topView;
@property (readwrite, nonatomic, strong) UIView *bottomView;

@property (readwrite, nonatomic, strong) UIScrollView *bottomScrollView;

@property (readwrite, nonatomic, assign) CGFloat topHeight;
@property (readwrite, nonatomic, assign) CGFloat initialMaxHeightBorder;
@property (readwrite, nonatomic, assign) CGFloat initialMinHeightBorder;

@property (readwrite, nonatomic, assign, getter = isAnimating) BOOL animating;

@property (readwrite, nonatomic, assign) QMBBottomViewControllerVisibility bottomViewControllerVisibility;

@property (readwrite, nonatomic, assign) QMBScrollDirection scrollDirection;

@end

@implementation QMBParallaxScrollViewController

- (void)dealloc{
    [_observedScrollView removeObserver:self forKeyPath:@"contentSize" context:QMBParallaxScrollViewControllerScrollViewContext];

    [self.view removeObserver:self forKeyPath:@"frame" context:QMBParallaxScrollViewControllerFrameContext];
}

#pragma mark - QMBParallaxScrollViewController Methods

- (void)setupWithTopViewController:(UIViewController *)topViewController topHeight:(CGFloat)height bottomViewController:(UIViewController *)bottomViewController {
    _topHeight = height;
    _startTopHeight = _topHeight;
    _maxHeight = self.view.frame.size.height-50.0f;

    [self setMaxHeightBorder:MAX(1.5f*_topHeight, 300.0f)];
    [self setMinHeightBorder:_maxHeight-20.0f];

    self.topViewController = topViewController;
    self.bottomViewController = bottomViewController;

    [self updateForegroundFrame];
    [self updateContentOffset];

    [self.view addObserver:self forKeyPath:@"frame" options:0 context:QMBParallaxScrollViewControllerFrameContext];
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

    [self.bottomScrollView addSubview:_bottomView];
}

- (void)setObservedScrollView:(UIScrollView *)observedScrollView;
{
    [_observedScrollView removeObserver:self forKeyPath:@"contentSize" context:QMBParallaxScrollViewControllerScrollViewContext];

    _observedScrollView = observedScrollView;

    [_observedScrollView addObserver:self forKeyPath:@"contentSize" options:0 context:QMBParallaxScrollViewControllerScrollViewContext];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.bottomScrollView = [[UIScrollView alloc] init];
    self.bottomScrollView.backgroundColor = [UIColor clearColor];
    self.bottomScrollView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0);
    self.bottomScrollView.delegate = self;
    self.bottomScrollView.alwaysBounceVertical = YES;
    self.bottomScrollView.frame = self.view.frame;

    [self.view addSubview:self.bottomScrollView];
}

#pragma mark - Obersver

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == QMBParallaxScrollViewControllerScrollViewContext || context == QMBParallaxScrollViewControllerFrameContext) {
        [self updateForegroundFrame];
        [self updateContentOffset];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - NSObject Overrides

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self.scrollViewDelegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:self.scrollViewDelegate];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return ([super respondsToSelector:aSelector] ||
            [self.scrollViewDelegate respondsToSelector:aSelector]);
}



#pragma mark - UIScrollViewDelegate Protocol Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSParameterAssert(scrollView == self.bottomScrollView);

    [self updateContentOffset];

    if ([self.scrollViewDelegate respondsToSelector:_cmd]) {
        [self.scrollViewDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!self.animating && self.bottomScrollView.contentOffset.y-_startTopHeight > -_maxHeightBorder && self.bottomViewControllerVisibility == QMBBottomViewControllerVisibilityMaximized){
        [self.bottomScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
}


#pragma mark - Public Interface

- (UIScrollView *)parallaxScrollView {
    return self.bottomScrollView;
}

- (void)setBackgroundHeight:(CGFloat)backgroundHeight {
    _topHeight = backgroundHeight;

    [self updateForegroundFrame];
    [self updateContentOffset];
}

#pragma mark Parallax Effect

- (void)updateForegroundFrame {

    if ([self.bottomView isKindOfClass:[UIScrollView class]]){
        self.bottomView.frame = CGRectMake(0.0f, _topHeight, self.view.frame.size.width, MAX(((UIScrollView *) _bottomView).contentSize.height, _bottomView.frame.size.height));
        CGSize size = CGSizeMake(self.view.frame.size.width,MAX(((UIScrollView *) _bottomView).contentSize.height, _bottomView.frame.size.height) + _topHeight);

        self.bottomScrollView.contentSize = size;
    } else {
        self.bottomView.frame = CGRectMake(0.0f,
                                               _topHeight,
                                               self.bottomView.frame.size.width,
                                               self.bottomView.frame.size.height);
        self.bottomScrollView.contentSize =
        CGSizeMake(self.view.frame.size.width,
                   self.bottomView.frame.size.height + _topHeight);
    }

}

- (void)updateContentOffset {

    if (2 * self.bottomScrollView.contentOffset.y > _bottomView.frame.origin.y){
        [self.bottomScrollView setShowsVerticalScrollIndicator:YES];
    }else {
        [self.bottomScrollView setShowsVerticalScrollIndicator:NO];
    }

    self.scrollDirection = self.bottomScrollView.contentOffset.y > _lastOffsetY ? QMBScrollDirectionUp : QMBScrollDirectionDown;

    _lastOffsetY = self.bottomScrollView.contentOffset.y;

    self.topView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), _topHeight + (-1) * self.bottomScrollView.contentOffset.y );
    [self.topView layoutIfNeeded];


    if (self.animating) return;

    if (self.scrollDirection == QMBScrollDirectionDown && self.bottomViewControllerVisibility != QMBBottomViewControllerVisibilityMaximized && self.bottomScrollView.contentOffset.y - _startTopHeight < -_maxHeightBorder){
        [self presentFullTopViewController:YES];
        return;
    }

    if (self.scrollDirection == QMBScrollDirectionUp && self.bottomViewControllerVisibility == QMBBottomViewControllerVisibilityMaximized && -_bottomView.frame.origin.y + self.bottomScrollView.contentOffset.y > -_minHeightBorder){
        [self presentFullTopViewController:NO];
        return;
    }
}

- (void)presentFullTopViewController:(BOOL)show {
    self.animating = YES;
    [self.bottomScrollView setScrollEnabled:NO];

    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut|UIViewKeyframeAnimationOptionBeginFromCurrentState;

    [UIView animateWithDuration:.3 delay:0.0 options:options animations:^{
         [self changeTopHeight:show ?  _maxHeight : _startTopHeight];
     }
     completion:^(BOOL finished){
         self.animating = NO;
         [self.bottomScrollView setScrollEnabled:YES];

         if (self.bottomViewControllerVisibility == QMBBottomViewControllerVisibilityMaximized){
             self.bottomViewControllerVisibility = QMBBottomViewControllerVisibilityMinimized;
             self.maxHeightBorder = self.initialMaxHeightBorder;

         } else {
             self.bottomViewControllerVisibility = QMBBottomViewControllerVisibilityMaximized;
             self.minHeightBorder = self.initialMinHeightBorder;
         }
     }];
}


- (void) changeTopHeight:(CGFloat) height{

    _topHeight = height;

    [self updateContentOffset];
    [self updateForegroundFrame];
}

#pragma mark - Borders

- (void)setMaxHeightBorder:(CGFloat)maxHeightBorder{
    _maxHeightBorder = MAX(_topHeight,maxHeightBorder);
    self.initialMaxHeightBorder = maxHeightBorder;
}

- (void)setMinHeightBorder:(CGFloat)minHeightBorder{
    _minHeightBorder = MIN(_maxHeight,minHeightBorder);
    self.initialMinHeightBorder = minHeightBorder;
}

@end
