//
//  QMBParallaxScrollViewController.h
//  QMBParallaxScrollView-Sample
//
//  Created by Toni Möckel on 02.11.13.
//  Copyright (c) 2013 Toni Möckel. All rights reserved.
//

@class QMBParallaxScrollViewController;

@interface QMBParallaxScrollViewController : UIViewController<UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (readonly, nonatomic, strong) UIViewController *topViewController;
@property (readonly, nonatomic, strong) UIViewController *bottomViewController;

@property (readonly, nonatomic, assign) CGFloat topHeight;

@property (readwrite, nonatomic, assign) CGFloat targetHeight;
@property (readwrite, nonatomic, assign) CGFloat maxHeight;

// inits
-(void)setupWithTopViewController:(UIViewController *)topViewController topHeight:(CGFloat)height bottomViewController:(UIViewController *)bottomViewController;

@property (readwrite, nonatomic, strong) UIScrollView *observedScrollView;

- (void)setTopHeight:(CGFloat)topHeight animated:(BOOL)animated;

@end
