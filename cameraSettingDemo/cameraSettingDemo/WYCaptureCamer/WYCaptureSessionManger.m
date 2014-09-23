//
//  WYCaptureSessionManger.m
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-19.
//  Copyright (c) 2014年 camera360. All rights reserved.
//
//TODO: 拍照后的预览功能，自动聚焦,（闪光灯没有）测光,分辨率的设置，帧率？（相机也有帧率）白平衡，曝光，iso(实时预览特效？)

#import "WYCaptureSessionManger.h"
const CGFloat kMaxPinchScaleNum = 3.f;
const CGFloat kMinPinchScaleNum = 1.f;

@interface WYCaptureSessionManger()

@property (nonatomic,strong)UIView *preview;

@end


@implementation WYCaptureSessionManger

- (id)init
{
    if (self = [super init]) {
        self.scaleNum = 1.f;
        self.preScaleNum = 1.f;
    }
    return self;
}

-(void)dealloc
{
    [self.session stopRunning];
    self.previewLayer = nil;
    self.inputDevice = nil;
    self.stillImageOut = nil;
    self.session = nil;
}

#pragma mark ---初始化方法
- (void)configureWithPartentLayer:(UIView *)parent previewRect:(CGRect)previewRect
{
    self.preview = parent;
    //1创建队列
    [self createQueue];
    //2添加session
    [self addSession];
    //3添加相机的预览界面
    [self addVideoPreviewLayerWithRect:previewRect];
    [parent.layer addSublayer:self.previewLayer];
    
    //4添加输入设备
    [self addVideoInputFrontCamera:NO];
    //5添加输出设备
    [self addStillImageOut];
    
}

- (void)createQueue
{
    self.sessionQueue = dispatch_queue_create("session Queue", DISPATCH_QUEUE_SERIAL);
}

- (void)addSession
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.session = session;
    //设置质量
    //  _session.sessionPreset = AVCaptureSessionPresetPhoto;
}

/**
 *  添加相机的实时预览界面
 */
- (void)addVideoPreviewLayerWithRect: (CGRect)previewRect
{
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame  = previewRect;
    self.previewLayer = previewLayer;
}

/**
 *  添加输入设备
 *
 *  @param isFront 是否是前置摄像头
 */
- (void)addVideoInputFrontCamera:(BOOL)isFront
{
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamer;
    AVCaptureDevice *backCamer;
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            if ([device position] == AVCaptureDevicePositionBack)
            {
                backCamer = device;
            }
            else
            {
                if ( [device position] ==AVCaptureDevicePositionFront)
                {
                    frontCamer = device;
                }
            }
        }
    }
    
    NSError *error = nil;
    if (isFront)
    {
        AVCaptureDeviceInput *frontFacingCamerDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamer error:&error];
        if (!error)
        {
            if ([self.session canAddInput:frontFacingCamerDeviceInput])
            {
                [self.session addInput:frontFacingCamerDeviceInput];
                self.inputDevice = frontFacingCamerDeviceInput;
            }else
            {
                WYLog(@"can't addinput device");
            }
            
        }
    }
    else
    {
        
        AVCaptureDeviceInput *backFacingCamerDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamer error:&error];
        if (!error)
        {
            if ([self.session canAddInput:backFacingCamerDeviceInput])
            {
                [self.session addInput:backFacingCamerDeviceInput];
                self.inputDevice = backFacingCamerDeviceInput;
            }else
            {
                WYLog(@"can't addinput device");
            }
            
        }

    }
}

/**
 *  添加输出设备
 */
- (void)addStillImageOut
{
    AVCaptureStillImageOutput *stillImageOut = [[AVCaptureStillImageOutput alloc]  init];
    stillImageOut.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    self.stillImageOut = stillImageOut;
    
    if ([self.session canAddOutput:stillImageOut]) {
        [self.session addOutput:stillImageOut];
    }
}

#pragma mark --一些公共的行为
- (void)takePicture:(didCapturePhotoBlock)didCaptureBlock
{
    AVCaptureConnection *captureConnection = [self.stillImageOut connectionWithMediaType:AVMediaTypeVideo];
     [self.stillImageOut captureStillImageAsynchronouslyFromConnection:captureConnection
                        completionHandler:^(CMSampleBufferRef imageDataSampleBuffer,
                                                                         NSError *error) {
        
                            if (!error)
                            {
                                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                UIImage *image = [UIImage imageWithData:imageData];
                                if (didCaptureBlock) {
                                    didCaptureBlock(image);
                                }
                            }else
                            {
                                WYLog(@"%@",error);
                            }
     }];

}



-(void)swithCamer:(BOOL)isFrontCamer
{
    if (!self.inputDevice)  return;
    [self.session beginConfiguration];
    [self.session removeInput:self.inputDevice];
    [self addVideoInputFrontCamera:isFrontCamer];
    [self.session commitConfiguration];
}

/**
 *  捏合手指
 */
- (void)pinchCamerViewWithScaleNum:(CGFloat)scale
{
    self.scaleNum = scale;
    if (scale < kMinPinchScaleNum)
    {
        scale = kMinPinchScaleNum;
    }
    else if(scale > kMaxPinchScaleNum)
    {
        scale = kMaxPinchScaleNum;
    }
    [self doPinch];
    self.scaleNum = scale;
}

/**
 *  拉近远镜头
 *
 *  @param gesture 手势
 */
- (void)pinchcamerView:(UIPinchGestureRecognizer *)gesture
{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numOfTouches = [gesture numberOfTouches];
    for (NSUInteger i = 0; i < numOfTouches; i++)
    {
        CGPoint location = [gesture locationOfTouch:i inView:self.preview];
        CGPoint convertdLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if (![self.previewLayer containsPoint:convertdLocation])
        {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    if (allTouchesAreOnThePreviewLayer)
    {
        self.scaleNum = _preScaleNum * gesture.scale;
        if (self.scaleNum < kMinPinchScaleNum)
        {
            self.scaleNum = kMinPinchScaleNum;
        }
        else if( self.scaleNum > kMaxPinchScaleNum)
        {
            self.scaleNum = kMaxPinchScaleNum;
        }
        [self doPinch];
    }
    
    if ([gesture state] == UIGestureRecognizerStateCancelled
        ||[gesture state] == UIGestureRecognizerStateFailed
        ||[gesture state] ==UIGestureRecognizerStateEnded
        )
    {
        self.preScaleNum = self.scaleNum;
    }
}

- (void)doPinch
{
    AVCaptureConnection *videoConnection =  [self.stillImageOut connectionWithMediaType:AVMediaTypeVideo];
    
    //如果大于最大的缩放因数那么就等于最大的缩放因数
    CGFloat maxScale = videoConnection.videoMaxScaleAndCropFactor;
    if (self.scaleNum > maxScale) {
        self.scaleNum = maxScale;
    }
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.scaleNum, self.scaleNum)];
    [CATransaction commit];
}

- (void)swithGrid:(BOOL)toShow
{
    
}

- (void)focusInPoint:(CGPoint)devicePoint
{
    //从view坐标系转换为相机的坐标系
    devicePoint = [self converToPointOfInterestsFromViewCoordinates:devicePoint];
    
    [self foucsWithMode:AVCaptureFocusModeAutoFocus exposedWithMode:AVCaptureExposureModeAutoExpose
                atPoint:devicePoint mointorSubjectAreaChange:YES];
}

- (void)foucsWithMode:(AVCaptureFocusMode)foucsMode exposedWithMode:(AVCaptureExposureMode)ExposeMode
                                                    atPoint:(CGPoint)devicePoint
                                                    mointorSubjectAreaChange:(BOOL)isChange
{
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *device = [self.inputDevice device];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:foucsMode])
            {
                [device setFocusMode:foucsMode];
                [device setFocusPointOfInterest:devicePoint];
            }
            if ([device isExposureModeSupported:ExposeMode] && [device isExposurePointOfInterestSupported])
            {
                [device setExposureMode:ExposeMode];
                [device setExposurePointOfInterest:devicePoint];
            }
        }else
        {
            WYLog(@"%@",error);
        }
        
    });
}
/**
 *  外部的点转convert 为camera 的point
 *
 *  @param devicePoint 外部view的点
 *
 *  @return 相对位置的point
 */
- (CGPoint)converToPointOfInterestsFromViewCoordinates:(CGPoint)devicePoint
{
//    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
//    CGSize  size = self.previewLayer.bounds.size;
    
    
    return CGPointZero;
}



@end
