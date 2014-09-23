//
//  WYCamerViewController.m
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-22.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import "WYCamerViewController.h"
#import "WYCaptureSessionManger.h"
#import "SVProgressHUD.h"

#define kBottomContainerView_COLOR     [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.f]       //bottomContainerView的上半部分
#define kBottomContainerView_DOWN_COLOR   [UIColor colorWithRed:68/255.0f green:68/255.0f blue:68/255.0f alpha:1.f]       //bottomContainerView的下半部分
const CGFloat kCameraMenuH = 44;
const CGFloat kCameraBtnW = 90;
const CGFloat kButtonNum = 4;
const CGFloat kHighAlpha = 1.0;
const CGFloat kLowAlpha = 0.7;
NSString * const KAdjustFoucs = @"adjustingFocus";

@interface WYCamerViewController ()
{
    int m_alphaTimes;
    CGPoint m_currentPoint;
}
/**相机管理工具*/
@property (nonatomic,strong)WYCaptureSessionManger *captureManger;

//在这里自定义想要展示的相机界面
@property (nonatomic, strong) UIView *bottomContainerView;

/**照相机菜单*/
@property (nonatomic, strong) UIView *cameraMenuView;

@property (nonatomic, strong) NSMutableSet *cameraBtnSet;

/** 对焦图片*/
@property (nonatomic, strong) UIImageView *focusImageView;

/** 当拍照完成的时候添加一个上部的遮盖*/
@property (nonatomic,strong)UIView *finshTakingUpView;

/* * 当拍照完成的时候添加一个下部的遮盖*/
@property (nonatomic,strong)UIView  *finshTakingDownView;

@property (nonatomic,strong)NSMutableArray *cameraBtns;

@end

@implementation WYCamerViewController
#pragma mark --初始化方法--
- (void)viewDidLoad
{
    [super viewDidLoad];
    //创建相机工具类
    WYCaptureSessionManger *captureManger = [[WYCaptureSessionManger alloc] init];

    //如果外部没有设置预览的尺寸，那么则创建一个默认的尺寸
    if (CGRectEqualToRect(self.previewRect, CGRectZero)) {
        self.previewRect  =CGRectMake(0, 0, screenW, screenW+44);
    }
    [captureManger configureWithPartentLayer:self.view previewRect:self.previewRect];
    
    [captureManger.session startRunning];
    self.captureManger = captureManger;
  
    //添加底部容器
    [self setUpBottomContainerView];
    [self addCameraMenuView];
    [self addBottomMenu];
    //添加照相完成时的上下遮盖
    [self addCameraCover];
    [self addFoucView];
    
    //添加手势
//    [self addPinchGesture];
    
    
}

/**
 *  添加底部整体的容器
 */
- (void)setUpBottomContainerView
{
    
    CGFloat bottomY = CGRectGetMaxY(self.captureManger.previewLayer.frame);
    CGRect bottomF = CGRectMake(0, bottomY, screenW, screenH - bottomY);
    
    UIView *bottomView = [[UIView alloc] initWithFrame:bottomF];
    bottomView.backgroundColor = kBottomContainerView_COLOR;
    [self.view addSubview:bottomView];
    self.bottomContainerView = bottomView;

}
/**
 *  添加底部菜单
 */
- (void)addBottomMenu
{
    CGFloat bottomMenuY = screenH - kCameraMenuH;
    
    UIView *bottomMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, bottomMenuY, screenW, kCameraMenuH)];
    bottomMenuView.backgroundColor = kBottomContainerView_DOWN_COLOR;
    
    [self.view addSubview:bottomMenuView];
    self.cameraMenuView = bottomMenuView;
    
    [self addMenuButtons];
}

/**
 *  添加上部的拍照按钮
 */
- (void)addCameraMenuView
{
    //底部菜单的高度
    CGFloat downMenuH = kCameraMenuH;
    
    //按钮的宽度和高度一样
    CGFloat cameraBtnW = kCameraBtnW;
    CGFloat cameraBtnH = cameraBtnW;
    CGFloat cameraBtnX = (screenW - cameraBtnW) / 2;
    CGFloat cameraBtnY = (self.bottomContainerView.frame.size.height - downMenuH -cameraBtnH) / 2;
    CGRect cameraBtnF = CGRectMake(cameraBtnX, cameraBtnY, cameraBtnW, cameraBtnW);
    
    [self creatCamerBtn:cameraBtnF norImageStr:@"shot.png"
                                   highlightImgStr:@"shot_h.png" selImgStr:nil
                 action:@selector(takeBtnClick:) parentView:self.bottomContainerView];
    [self addMenuButtons];
}
/**
 *  创建按钮
 */
- (UIButton *)creatCamerBtn:(CGRect)btnFrame norImageStr:(NSString *)norImagStr highlightImgStr:(NSString *)higImgStr
                  selImgStr:(NSString*)selImgStr
                     action:(SEL)action parentView:(UIView *)parentView
{
    //创建button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.frame  = btnFrame;
    [button setImage:[UIImage imageNamed:norImagStr] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:higImgStr] forState:UIControlStateHighlighted];
    
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    [parentView addSubview:button];
    
    return button;
    
}

- (void)addMenuButtons
{
    //普通状态下四个按钮的属性
    NSMutableArray *norAttr = [NSMutableArray arrayWithArray:@[@"close_cha.png", @"camera_line.png", @"switch_camera.png", @"flashing_off.png"]];
    
    //高亮状态下四个按钮的属性
    NSMutableArray *highAttr = [NSMutableArray arrayWithArray:@[@"close_cha_h.png", @"", @"", @""]];
    
    //选择状态下的四个按钮的属性
    NSMutableArray *selectedAttr = [NSMutableArray arrayWithArray:@[@"", @"camera_line_h.png", @"switch_camera_h.png", @""]];
    NSMutableArray *actionAttr = [NSMutableArray arrayWithArray:@[@"dismissBtnPressed:", @"gridBtnPressed:", @"switchCameraBtnPressed:", @"flashBtnPressed:"]];
    
    //按钮的宽度
    CGFloat btnW = screenW / actionAttr.count;
    
    for (int i = 0; i < actionAttr.count; i++) {
        CGFloat btnH = kCameraMenuH;
        
        CGRect btnFrame = CGRectMake(btnW * i, 0, btnW, btnH);
        UIButton *btn = [self creatCamerBtn:btnFrame norImageStr:[norAttr objectAtIndex:i]
                            highlightImgStr:[highAttr objectAtIndex:i]
                                  selImgStr:[selectedAttr objectAtIndex:i] action:NSSelectorFromString([actionAttr objectAtIndex:i]) parentView:self.cameraMenuView];
        btn.showsTouchWhenHighlighted = YES;
        [self.cameraBtns addObject:btn];
    }
}

- (void)addFoucView
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"touch_focus_x.png"]];
    imageView.alpha = 0.0;
    [self.view addSubview:imageView];
    self.focusImageView = imageView;
    
    //当聚焦直到聚焦结束
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device && [device isFocusPointOfInterestSupported]) {
        [device addObserver:self forKeyPath:KAdjustFoucs options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
}

/**
 *  点击对应拍照按钮
 */
- (void)takeBtnClick:(UIButton *)button
{
    WYLog(@"takeBtnClick");
    //首先判断用户是否支持拍照，相机是否已经损坏
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [SVProgressHUD showErrorWithStatus:@"该设备不支持拍照功能"];
        return;
    }
    
    button.userInteractionEnabled = NO;
    
    [self showCameraCover:YES];
    
    //拍照过程中禁止再次触摸
    __block UIActivityIndicatorView *activew = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activew.center = CGPointMake(self.view.center.x, self.view.center.y - 44);
    [activew startAnimating];
    [self.view addSubview:activew];
    
    __weak typeof (self) weakself = self;
    [self.captureManger takePicture:^(UIImage *image)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        });
        [activew stopAnimating];
        [activew removeFromSuperview];
        activew = nil;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            button.userInteractionEnabled = YES;
            [weakself showCameraCover:NO];
        });
    }];
}
/**
 *  拍照工程中添加遮盖
 */
- (void)addCameraCover
{
    //上部遮盖
    UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenW, 0)];
    upView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:upView];
    self.finshTakingUpView = upView;
    
    //下部遮盖
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0, screenH - self.bottomContainerView.frame.size.height, screenW, 0)];
    downView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:downView];
    self.finshTakingDownView = downView;
    

}

/**添加捏合手势*/
- (void)addPinchGesture
{
    UIGestureRecognizer *pinch = [[UIGestureRecognizer alloc] initWithTarget:self action:@selector(hanlePinch:)];
    [self.view addGestureRecognizer:pinch];
    
    
}
/**
 *  调整是否显示遮盖
 *
 *  @param isSHow 是否显示遮盖
 */
- (void)showCameraCover:(BOOL)isSHow
{
    [UIView animateWithDuration:0.38 animations:^{
        
        CGRect upFrame = self.finshTakingUpView.frame;
        upFrame.size.height  =(isSHow ? screenW / 2 +44 : 0);
        self.finshTakingUpView.frame  =upFrame;
        
        
        CGRect downFrame = self.finshTakingDownView.frame;
        downFrame.origin.y  = (isSHow ? screenW / 2 + 44 : screenH - 44);
        downFrame.size.height = (isSHow ? screenW / 2 : 0);
        self.finshTakingDownView.frame  =downFrame;
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:KAdjustFoucs]) {
        BOOL isAdjustFoucs = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:@(1)];
        if (!isAdjustFoucs) {
            m_alphaTimes = -1;
        }
    }
}

#pragma  mark ---按钮方法---

- (void)dismissBtnPressed:(UIButton *)button
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)gridBtnPressed:(UIButton *)button
{
       WYLog(@"gridBtnPressed");
}
/**
 *  切换摄像头
 */
- (void)switchCameraBtnPressed:(UIButton *)button
{
    button.selected = !button.selected;
    [self.captureManger swithCamer:button.selected];
}

- (void)flashBtnPressed:(UIButton *)button
{
    WYLog(@"flashBtnPressed");
}

#pragma  mark --调整镜头--

- (void)hanlePinch:(UIPinchGestureRecognizer *)gesture
{
    [self.captureManger pinchcamerView:gesture];
}

#pragma  mark   ---手势处理方法---
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    m_alphaTimes = -1;
    UITouch *touch = [touches anyObject];
    m_currentPoint = [touch locationInView:self.view];
    
    if (CGRectContainsPoint(self.captureManger.previewLayer.frame, m_currentPoint) == NO) return;
    
    [self.captureManger focusInPoint:m_currentPoint];
    
    //对焦框
    self.focusImageView.center = m_currentPoint;
    self.focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);
    
    //开启对焦框一直闪烁直到聚焦完成
    [UIView animateWithDuration:0.1f animations:^{
        self.focusImageView.alpha = 1.0f;
        self.focusImageView.transform  = CGAffineTransformMakeScale(1.0, 1.0);
    }];
    
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}




@end
