//
//  HMNavigationController.m
//  05-手势移除控制器
//
//  Created by apple on 14/12/4.
//  Copyright (c) 2014年 heima. All rights reserved.

//  思路:0.自定义导航控制器 1.添加手势 2.截图存入数组 3.把截图加到window上 4.添加遮盖view到截图上面 5.超过屏幕一半就...

#import "HMNavigationController.h"

@interface HMNavigationController ()
/** 存放每一个控制器的全屏截图 */
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) UIImageView *lastVcView;
@property (nonatomic, strong) UIView *cover;
@end

@implementation HMNavigationController

//1. 懒加载创建截图imageView
- (UIImageView *)lastVcView
{
    if (!_lastVcView) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIImageView *lastVcView = [[UIImageView alloc] init];
        lastVcView.frame = window.bounds;
        self.lastVcView = lastVcView;
    }
    return _lastVcView;
}


//2. 懒加载创建存放截图的数组
- (NSMutableArray *)images
{
    if (!_images) {
        self.images = [[NSMutableArray alloc] init];
    }
    return _images;
}


//3. 懒加载创建遮盖view
- (UIView *)cover
{
    if (!_cover) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIView *cover = [[UIView alloc] init];
        cover.backgroundColor = [UIColor blackColor];
        cover.frame = window.bounds;
        cover.alpha = 0.5;
        self.cover = cover;
    }
    return _cover;
}




#pragma makr (一)view已经出现
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //1.第一张图片有了就不截图了
    if (self.images.count > 0) return;
    
    //2.没的话就截图
    [self createScreenShot];
}


#pragma makr (二)把push进来的子控制器都截图
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    
    //截图
    [self createScreenShot];
}


//封装截图方法
- (void)createScreenShot
{
    //1.开启图形上下文 (第一个参数是截图范围,YES是不透明,0.0是原来比例)
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, YES, 0.0);
    
    //2.渲染当前上下文
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    //3.取出截图放入数组
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    [self.images addObject:image];
}



#pragma mark (三)view加载完毕
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 拖拽手势到导航控制器  (等于给所有导航控制器的子控制器都添加了手势)
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragging:)];
    [self.view addGestureRecognizer:recognizer];
}


#pragma mark (四)  拖拽
- (void)dragging:(UIPanGestureRecognizer *)recognizer
{
    //1.如果只有1个子控制器,停止拖拽
    if (self.viewControllers.count <= 1) return;
    
    //2.拿到在x方向上移动的距离
    CGFloat tx = [recognizer translationInView:self.view].x;
    if (tx < 0) return;  //禁掉往左边滑动效果!
    
    //3.如果现在是处于手松开了或取消了的状态
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        
        // 决定pop还是还原
        CGFloat x = self.view.frame.origin.x;
        if (x >= self.view.frame.size.width * 0.5) {
            [UIView animateWithDuration:0.25 animations:^{
                //3.1如果宽度超过屏幕一半宽度就让控制器先挪到最右边去
                self.view.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
            } completion:^(BOOL finished) {
                //3.2然后移除不需要的控件和图片
                [self popViewControllerAnimated:NO];   //销毁控制器
                [self.lastVcView removeFromSuperview]; //移除截图imageView
                [self.cover removeFromSuperview];      //移除遮盖view
                self.view.transform = CGAffineTransformIdentity; //让导航控制器从右边回到原来位置
                [self.images removeLastObject];        //删掉截图
            }];
            
        } else {  //3.3如果没超过屏幕一半就回到原来位置
            [UIView animateWithDuration:0.25 animations:^{
                self.view.transform = CGAffineTransformIdentity;
            }];
        }
        
        
    } else {    //4.如果是处于继续滑动的状态
        // 移动view
        self.view.transform = CGAffineTransformMakeTranslation(tx, 0);
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        // 添加截图到最后面
        self.lastVcView.image = self.images[self.images.count - 2]; //拿到上一个控制器的截图
        [window insertSubview:self.lastVcView atIndex:0];
        [window insertSubview:self.cover aboveSubview:self.lastVcView];
    }
}



@end
