//
//  WYViewController.m
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-18.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "WYViewController.h"
#import "WYAVCameraPreviewView.h"


typedef void(^didCapturePictureBlock)(UIImage *stillImage);

@interface WYViewController ()

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

//显示层
@property (nonatomic,weak  ) UIView                *preView;

//utility
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;

@property (nonatomic,assign)UIBackgroundTaskIdentifier backgroundRecordingID;

/**
 *  方法类
 */
- (IBAction)takePhoto:(UIButton *)sender;

- (IBAction)changeCamera:(UIButton *)sender;







@end

@implementation WYViewController


#pragma mark --懒加载
/**
 *  lazy返回connneciton
 */
- (AVCaptureConnection *)connection
{
    if (_connection==nil) {
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
    
    
    // Check for device authorization
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
        
        if ([session canAddInput:vedioDeviceInput]) {
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

        if ([session canAddOutput:stillImageOut]) {
            //设置输出的图片是jpg
            [stillImageOut setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [session canAddOutput:stillImageOut];
            self.stillImageOut = stillImageOut;
        }
    });

}


//创建AVCaptureDevice
- (AVCaptureDevice *)deviveWithMediaType:(NSString *)mediaType prefrringPosition:(AVCaptureDevicePosition)postion
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices) {
        if ( [device position] == postion) {
            
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
    [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.session stopRunning];
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


/**
 *  设置闪光灯模式
 */
- (void)setFlashModel:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            [device unlockForConfiguration];
        }else{
            WYLog(@"setFlashModel-----%@",error);
        }
        
    }
}

#pragma mark ---按钮action

- (IBAction)takePhoto:(UIButton *)sender {
    
    dispatch_async(self.sessionQueue, ^{
        
        //得到输出设备的connection
        AVCaptureConnection *imageOutConnection = [self.stillImageOut connectionWithMediaType:AVMediaTypeVideo];
        
        //设置图片输出的方向
        [imageOutConnection setVideoOrientation:self.connection.videoOrientation];
        
        //设置闪光灯模式为自动
        [self setFlashModel:AVCaptureFlashModeAuto forDevice:self.videoDeviceInput.device];
        
        //扑捉照片
        [self.stillImageOut captureStillImageAsynchronouslyFromConnection:imageOutConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            if (imageDataSampleBuffer) {
                NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [UIImage imageWithData:data];
                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage]
                                                                 orientation:(ALAssetOrientation)image.imageOrientation
                                                                 completionBlock:nil];
                
//                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }
            
        }];
        
        
        
    });
}


- (IBAction)changeCamera:(UIButton *)sender {
}
@end
