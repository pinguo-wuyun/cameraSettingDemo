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

@interface WYCamerViewController ()
{
    int m_alphaTimes;
    CGPoint m_currentPoint;
}

@property (nonatomic,strong)WYCaptureSessionManger *captureManger;
//在这里自定义想要展示的相机界面
@property (nonatomic, strong) UIView *bottomContainerView;//除了顶部标题、拍照区域剩下的所有区域

@property (nonatomic, strong) UIView *cameraMenuView;//网格、闪光灯、前后摄像头等按钮

@property (nonatomic, strong) NSMutableSet *cameraBtnSet;
//对焦
@property (nonatomic, strong) UIImageView *focusImageView;

@end

@implementation WYCamerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        m_alphaTimes = -1;
        m_currentPoint = CGPointZero;
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.3];
    
    
    //创建相机工具类
    WYCaptureSessionManger *captureManger = [[WYCaptureSessionManger alloc] init];
    //
    if (CGRectEqualToRect(self.previewRect, CGRectZero)) {
        self.previewRect  =CGRectMake(0, 0, screenW, screenW+44);
    }
    
//    [self.captureManger configureWithPartentLayer:self.view previewRect:self.previewRect];
    [captureManger configureWithPartentLayer:self.view previewRect:self.previewRect];
    
    [captureManger.session startRunning];
    self.captureManger = captureManger;
  
    [self setUpBottomMenu];
    
}

- (void)setUpBottomMenu
{
    UIButton *takePicBtn = [[UIButton alloc] init];
    CGFloat     takePicBtnX = screenW *0.5;
    CGFloat takePicBtnY = screenH -88;
    
    
    takePicBtn.frame = CGRectMake(takePicBtnX-150, takePicBtnY, 150, 44);
    
    [takePicBtn setTitle:@"测试按钮" forState:UIControlStateNormal];
    [self.view addSubview:takePicBtn];
    
    
    [takePicBtn addTarget:self action:@selector(takeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
}

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
    //拍照过程中禁止再次触摸
    __block UIActivityIndicatorView *activew = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activew.center = CGPointMake(self.view.center.x, self.view.center.y - 44);
    [activew startAnimating];
    [self.view addSubview:activew];
    
    
    [self.captureManger takePicture:^(UIImage *image)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        });
        button.userInteractionEnabled = YES;
        [activew stopAnimating];
        [activew removeFromSuperview];
        activew = nil;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
        });
        
    }];

    
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


@end
