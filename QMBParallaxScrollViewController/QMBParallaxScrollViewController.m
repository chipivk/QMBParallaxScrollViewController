//
//  QMBParallaxScrollViewController.m
//  QMBParallaxScrollView-Sample
//
//  Created by Toni Möckel on 02.11.13.
//  Copyright (c) 2013 Toni Möckel. All rights reserved.
//

#import "QMBParallaxScrollViewController.h"


@interface QMBParallaxScrollViewController (){
    BOOL _isAnimating;
    CGFloat _startTopHeight;
    CGFloat _lastOffsetY;
}

@property (readwrite, nonatomic, strong) UIView *topView;
@property (readwrite, nonatomic, strong) UIView *bottomView;

@property (readwrite, nonatomic, strong) UIScrollView *bottomScrollView;

@property (readwrite, nonatomic, strong) UIScrollView *observedForegroundScrollView;

@property (readwrite, nonatomic, assign) CGFloat topHeight;
@property (readwrite, nonatomic, assign) CGFloat initialMaxHeightBorder;
@property (readwrite, nonatomic, assign) CGFloat initialMinHeightBorder;

@property (readwrite, nonatomic, assign) QMBParallaxState state;
@property (readwrite, nonatomic, strong) UITapGestureRecognizer *topViewGestureRecognizer;
@property (readwrite, nonatomic, assign) QMBParallaxGesture lastGesture;

@end

@implementation QMBParallaxScrollViewController

- (void)dealloc{
    if ([[_topView gestureRecognizers] containsObject:self.topViewGestureRecognizer]){
        [_topView removeGestureRecognizer:self.topViewGestureRecognizer];
    }

    // Remove Observer
    if ([_bottomView isKindOfClass:[UIScrollView class]]){
        UIScrollView *foregroundScrollView = (UIScrollView *) _bottomView;
        [foregroundScrollView removeObserver:self forKeyPath:@"contentSize"];
    }

    [self.view removeObserver:self forKeyPath:@"frame"];
}

#pragma mark - QMBParallaxScrollViewController Methods

- (void)setupWithTopViewController:(UIViewController *)topViewController topHeight:(CGFloat)height bottomViewController:(UIViewController *)bottomViewController {

    _topViewController = topViewController;
    _bottomViewController = bottomViewController;

    _topHeight = height;
    _startTopHeight = _topHeight;
    _maxHeight = self.view.frame.size.height-50.0f;

    [self setMaxHeightBorder:MAX(1.5f*_topHeight, 300.0f)];
    [self setMinHeightBorder:_maxHeight-20.0f];

    [self addChildViewController:self.topViewController];
    _topView = topViewController.view;
    [_topView setClipsToBounds:YES];

    [self addChildViewController:self.bottomViewController];
    _bottomView = bottomViewController.view;

    _bottomScrollView = [UIScrollView new];
    _bottomScrollView.backgroundColor = [UIColor clearColor];
    if ([self respondsToSelector:@selector(topLayoutGuide)]){
        [self.bottomScrollView setContentInset:UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)];
    }
    _bottomScrollView.delegate = self;
    [_bottomScrollView setAlwaysBounceVertical:YES];
    _bottomScrollView.frame = self.view.frame;
    [_bottomScrollView addSubview:_bottomView];

    [self.view addSubview:_bottomScrollView];
    [self.bottomViewController didMoveToParentViewController:self];

    [self.view addSubview:_topView];
    [self.topViewController didMoveToParentViewController:self];

    [self addGestureReconizer];

    [self updateForegroundFrame];
    [self updateContentOffset];


    // If forground subview is UIScrollView set KV-Observer for any Content Size Changes
    if ([_bottomView isKindOfClass:[UIScrollView class]]){
        [self observeScrollView:(id) _bottomView];
    }

    [self.view addObserver:self forKeyPath:@"frame" options:0 context:NULL];

}

- (void)observeScrollView:(UIScrollView *)scrollView
{
    if(self.observedForegroundScrollView){
        [self.observedForegroundScrollView removeObserver:self forKeyPath:@"contentSize"];
    }

    [scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];
    self.observedForegroundScrollView = scrollView;
}

#pragma mark - Obersver

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void*)context {
    [self updateForegroundFrame];
    [self updateContentOffset];
}

#pragma mark - Gestures

-(void) addGestureReconizer{
    self.topViewGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.topViewGestureRecognizer setNumberOfTouchesRequired:1];
    [self.topViewGestureRecognizer setNumberOfTapsRequired:1];
    [self.topViewController.view setUserInteractionEnabled:YES];

    [self enableTapGestureTopView:YES];
}

- (void)enableTapGestureTopView:(BOOL)enable{
    if (enable) {
        [_topView addGestureRecognizer:self.topViewGestureRecognizer];
    }else {
        [_topView removeGestureRecognizer:self.topViewGestureRecognizer];
    }
}

- (void) handleTap:(id)sender {

    self.lastGesture = QMBParallaxGestureTopViewTap;

    [self presentFullTopViewController:self.state != QMBParallaxStateFullSize];
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

    [self updateContentOffset];
    if ([self.scrollViewDelegate respondsToSelector:_cmd]) {
        [self.scrollViewDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!_isAnimating && self.bottomScrollView.contentOffset.y-_startTopHeight > -_maxHeightBorder && self.state == QMBParallaxStateFullSize){
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


#pragma mark - Internal Methods



- (CGRect)frameForObject:(id)frameObject {
    return frameObject == [NSNull null] ? CGRectNull : [frameObject CGRectValue];
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

    // Determine if user scrolls up or down
    if (self.bottomScrollView.contentOffset.y > _lastOffsetY){
        self.lastGesture = QMBParallaxGestureScrollsUp;
    }else {
        self.lastGesture = QMBParallaxGestureScrollsDown;
    }
    _lastOffsetY = self.bottomScrollView.contentOffset.y;

    self.topView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), _topHeight + (-1) * self.bottomScrollView.contentOffset.y );
    [self.topView layoutIfNeeded];


    if (_isAnimating){
        return;
    }

    if (!_isAnimating && self.lastGesture == QMBParallaxGestureScrollsDown && self.bottomScrollView.contentOffset.y - _startTopHeight < -_maxHeightBorder && self.state != QMBParallaxStateFullSize){
        [self presentFullTopViewController:YES];
        return;
    }

    if (!_isAnimating && self.lastGesture == QMBParallaxGestureScrollsUp && -_bottomView.frame.origin.y + self.bottomScrollView.contentOffset.y > -_minHeightBorder && self.state == QMBParallaxStateFullSize){
        [self presentFullTopViewController:NO];
        return;
    }
}

- (void)presentFullTopViewController:(BOOL)show {

    _isAnimating = YES;
    [self.bottomScrollView setScrollEnabled:NO];

    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut|UIViewKeyframeAnimationOptionBeginFromCurrentState;

    [UIView animateWithDuration:.3 delay:0.0 options:options animations:^{
         [self changeTopHeight:show ?  _maxHeight : _startTopHeight];
     }
     completion:^(BOOL finished){

         _isAnimating = NO;
         [self.bottomScrollView setScrollEnabled:YES];

         if (self.state == QMBParallaxStateFullSize){
             self.state = QMBParallaxStateVisible;
             self.maxHeightBorder = self.initialMaxHeightBorder;

         } else {
             self.state = QMBParallaxStateFullSize;
             self.minHeightBorder = self.initialMinHeightBorder;
         }

         if ([self.delegate respondsToSelector:@selector(parallaxScrollViewController:didChangeState:)]){
             [self.delegate parallaxScrollViewController:self didChangeState:self.state];
         }
     }];
}


- (void) changeTopHeight:(CGFloat) height{

    _topHeight = height;

    [self updateContentOffset];
    [self updateForegroundFrame];

    if ([self.delegate respondsToSelector:@selector(parallaxScrollViewController:didChangeTopHeight:)]){
        [self.delegate parallaxScrollViewController:self didChangeTopHeight:height];
    }
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
