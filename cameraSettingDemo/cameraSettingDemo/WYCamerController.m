//
//  WYViewController.m
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-18.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "WYCamerController.h"

#import "WYCamerViewController.h"
#import "WYAVCameraPreviewView.h"

//???: 搞不懂这三行是做嘛的！！！！T
static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;



//TODO: 相机的预览和保存>>保存让用户手动保存

@interface WYCamerController ()

/**输入设备*/
@property (nonatomic,strong) AVCaptureDeviceInput      *videoDeviceInput;
/**输出设备*/
@property (nonatomic,strong) AVCaptureStillImageOutput *stillImageOut;
/**连接输入和输出设备session*/
@property (nonatomic,strong) AVCaptureSession          *session;
/**
 *  session队列
 */
@property (nonatomic,strong) dispatch_queue_t      sessionQueue;

@property (nonatomic,strong) AVCaptureConnection   *connection;

@property (weak, nonatomic ) IBOutlet  WYAVCameraPreviewView *preview;

@property (weak, nonatomic ) IBOutlet  UIButton              *stillButoon;

@property (weak, nonatomic ) IBOutlet  UIButton              *cameraButton;



//utility
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;

@property (nonatomic,assign)UIBackgroundTaskIdentifier backgroundRecordingID;

@property (nonatomic) id runtimeErrorHandlingObserver;

@property (nonatomic,readonly,getter = isSessionRunningAndDeviceAuthorizedContext)BOOL sessionRunningAndDeviceAuthorizedContext;

/**
 *  方法类
 */
- (IBAction)takePhoto:(UIButton *)sender;

- (IBAction)changeCamera:(UIButton *)sender;

@end

@implementation WYCamerController


#pragma mark --懒加载
/**
 *  lazy返回connneciton
 */
- (AVCaptureConnection *)connection
{
    if (_connection==nil)
    {
      AVCaptureVideoPreviewLayer *previewLayer =(AVCaptureVideoPreviewLayer *)self.preview.layer;
        _connection = previewLayer.connection;
    }
    return _connection;
}



#pragma mark ---初始化方法
- (void)viewDidLoad
{
    [super viewDidLoad];

    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.session = session;
    
    self.preview.session = session;

    // 检查设备授权状态
	[self checkDeviceAuthorizationStatus];
    
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(self.sessionQueue, ^{
#warning 这句的作用不知道是什么
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        NSError *error = nil;
        
        //设置是前置摄像头还是后置摄像头
        AVCaptureDevice *vedioDevice = [self deviveWithMediaType:AVMediaTypeVideo prefrringPosition:AVCaptureDevicePositionBack];
        
        AVCaptureDeviceInput *vedioDeviceInput =[AVCaptureDeviceInput deviceInputWithDevice:vedioDevice error:&error];
        if (error) {
            NSLog(@"error%@",error);
        }
        
        if ([session canAddInput:vedioDeviceInput])
        {
            [session addInput:vedioDeviceInput];
            self.videoDeviceInput = vedioDeviceInput;
            dispatch_async(dispatch_get_main_queue(), ^{
               //调回主线程设置vedio的方向

                AVCaptureVideoOrientation  cureentOrentination = (AVCaptureVideoOrientation)self.interfaceOrientation;
                [self.connection setVideoOrientation:cureentOrentination];
                
            });
        }

        //设置图像输出,并且添加
        AVCaptureStillImageOutput *stillImageOut = [[AVCaptureStillImageOutput alloc] init];

        if ([session canAddOutput:stillImageOut])
        {
            //设置输出的图片是jpg
            [stillImageOut setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [session addOutput:stillImageOut];
            self.stillImageOut = stillImageOut;
        }
    });

}


//创建AVCaptureDevice
- (AVCaptureDevice *)deviveWithMediaType:(NSString *)mediaType prefrringPosition:(AVCaptureDevicePosition)postion
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ( [device position] == postion)
        {
            
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}
#pragma mark -系统方法
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    dispatch_async(self.sessionQueue, ^{
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized"
                               options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                               context:SessionRunningAndDeviceAuthorizedContext];
        [self addObserver:self forKeyPath:@"stillImageOut.capturingStillImage"
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:CapturingStillImageContext];
        AVCaptureDevice *device = self.videoDeviceInput.device;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(subjectAreaDidChange:)
                                                 name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                  object:device];

        //!!!: 这一段应该是用来记录录像的
//        __weak typeof(self) weakSelf = self;
//        [self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:self.session queue:nil usingBlock:^(NSNotification *note) {
//            	WYCamerController *strongSelf = weakSelf;
//            dispatch_async(strongSelf.sessionQueue, ^{
//                [strongSelf.session startRunning];
//                [strongSelf ]
//            });
//        }]];
        
        [self.session startRunning];
 
    });
   }

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    dispatch_async(self.sessionQueue, ^{
        [self.session stopRunning];
        AVCaptureDevice *device = self.videoDeviceInput.device;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:device];
//        [[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];
        [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
         [self removeObserver:self forKeyPath:@"stillImageOut.capturingStillImage" context:CapturingStillImageContext];
    });
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context ==CapturingStillImageContext) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        if (isCapturingStillImage) {
            [self runStillImageCaptureAnimation];
        }
    }
}

/**
 *  支持哪些方向
 */
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.connection setVideoOrientation:(AVCaptureVideoOrientation )toInterfaceOrientation];
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark--私有方法

- (BOOL)isSessionRunningAndDeviceAuthorized
{
    return [self.session isRunning] && self.deviceAuthorized;
}

/**
 *  设置闪光灯模式
 */
- (void)setFlashModel:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device unlockForConfiguration];
        }else
        {
            WYLog(@"setFlashModel-----%@",error);
        }
        
    }
}

#pragma mark ---按钮action

/**
 *  拍照
 */
- (IBAction)takePhoto:(UIButton *)sender
{

    //异步函数不会立刻中断
    dispatch_async(self.sessionQueue, ^{
//        //得到输出设备的connection
        AVCaptureConnection *imageOutConnection = [self.stillImageOut connectionWithMediaType:AVMediaTypeVideo];
        //设置图片输出的方向
     [imageOutConnection setVideoOrientation:self.connection.videoOrientation];
//        	[[self.stillImageOut connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[self.preview layer] connection] videoOrientation]];
        
        //设置闪光灯模式为自动
        [self setFlashModel:AVCaptureFlashModeAuto forDevice:self.videoDeviceInput.device];
        
        //扑捉照片
        [self.stillImageOut captureStillImageAsynchronouslyFromConnection:[self.stillImageOut connectionWithMediaType:AVMediaTypeVideo]
                                                        completionHandler:^(CMSampleBufferRef imageDataSampleBuffer
                                                         , NSError *error)
         {
            
            if (imageDataSampleBuffer)
            {
                NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [UIImage imageWithData:data];
                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage]
                                                                 orientation:(ALAssetOrientation)image.imageOrientation
                                                                 completionBlock:nil];
            }
            
        }];
        
    });
}

/**
 *  切换前后摄像头
 */
- (IBAction)changeCamera:(UIButton *)sender
{
    //!!!: 在这里做一些测试
    WYCamerViewController *camerVc = [[WYCamerViewController alloc] init];
    [self presentViewController:camerVc animated:YES completion:nil];
    
}

#pragma mark---通知方法
/**
 *  相机位置变动，改变子区域聚焦区域，曝光模式
 */
- (void)subjectAreaDidChange:(NSNotification *)note
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self foucusWithMode:AVCaptureFocusModeContinuousAutoFocus
          exposeWithMode:AVCaptureExposureModeContinuousAutoExposure
           atDevicePoint:devicePoint mointorSubjectAreaChange:NO];
    [self foucusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint mointorSubjectAreaChange:NO];
}

-(void)foucusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposeMode
        atDevicePoint:(CGPoint)devicePoint mointorSubjectAreaChange:(BOOL)mointerSubjectChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusModeSupported:focusMode] && [device isFocusPointOfInterestSupported])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:devicePoint];
            }
            if ([device isExposureModeSupported:exposeMode] && [device isExposurePointOfInterestSupported])
            {
                [device setExposureMode:exposeMode];
                [device setExposurePointOfInterest:devicePoint];
            }
            [device setSubjectAreaChangeMonitoringEnabled:YES];
            [device unlockForConfiguration];
        }else
        {
            WYLog(@"foucusWithMode---%@",error);
        }
        
    });
}

#pragma mark --UI

/**
 *  当拍照的时候延缓处理
 */
- (void)runStillImageCaptureAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.preview.layer.opacity = 0.0;
        [UIView animateWithDuration:.25 animations:^{
            self.preview.layer.opacity = 1.0;
        }];
    });
}

/**
 *  检查设备是否授权
 */
- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted) {
            [self setDeviceAuthorized:YES];
        }else{
            //	//Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[[UIAlertView alloc] initWithTitle:@"AVM!"
                                            message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"cancel"
                                  otherButtonTitles:nil] show];
                [self setDeviceAuthorized:NO];
                
            });
            
        };
        
    }];
}


@end
