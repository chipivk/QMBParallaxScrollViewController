//
//  QMBParallaxScrollViewController.h
//  QMBParallaxScrollView-Sample
//
//  Created by Toni Möckel on 02.11.13.
//  Copyright (c) 2013 Toni Möckel. All rights reserved.
//

@class QMBParallaxScrollViewController;

typedef NS_ENUM(NSUInteger, QMBParallaxState) {
    QMBParallaxStateVisible,
    QMBParallaxStateFullSize,
    QMBParallaxStateContentPeakSize,
    QMBParallaxStateHidden,
};

typedef NS_ENUM(NSUInteger, QMBScrollDirection) {
    QMBScrollDirectionUp,
    QMBScrollDirectionDown,
};

@protocol QMBParallaxScrollViewHolder <NSObject>

- (UIScrollView *)scrollViewForParallaxController;

@end

@interface QMBParallaxScrollViewController : UIViewController<UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (readonly, nonatomic, strong) UIViewController *topViewController;
@property (readonly, nonatomic, strong) UIViewController *bottomViewController;

@property (readonly, nonatomic, assign) CGFloat topHeight;
@property (readwrite, nonatomic, assign) CGFloat maxHeight;

/**
 * Set the height of the border (margin from top) that has to be scrolled over to expand the background view.
 * Default: 1.3 * topHeight
 */
@property (readwrite, nonatomic, assign) CGFloat maxHeightBorder;

/**
 * Set the height of the border (margin from top) that has to be scrolled under to minimize the background view
 * Default: fullHeight - 5.0f
 */
@property (readwrite, nonatomic, assign) CGFloat minHeightBorder;

/**
 * To enable section support for UITableViews, default: true if UITableView is client scrollview
 * TODO: this option will disable decelerated scrolling (known bug)
 */
@property (readwrite, nonatomic, assign) BOOL enableSectionSupport;

@property (readonly, nonatomic, assign) QMBParallaxState state;

/**
 * The Parallax Scrollview that embeds the bottom (foreground) view
 */
@property (readonly, nonatomic, strong) UIScrollView *parallaxScrollView;

/**
 * Use the scrollview delegate for custom actions
 */
@property (readwrite, nonatomic, weak) id<UIScrollViewDelegate> scrollViewDelegate;

// inits
-(void)setupWithTopViewController:(UIViewController *)topViewController topHeight:(CGFloat)height bottomViewController:(UIViewController *)bottomViewController;

@property (readwrite, nonatomic, strong) UIScrollView *observedScrollView;


- (void)presentFullTopViewController:(BOOL)show;

@end
