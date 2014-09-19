//
//  WYCaptureSessionManger.m
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-19.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import "WYCaptureSessionManger.h"

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

- (void)configureWithPartentLayer:(UIView *)parent previewRect:(CGRect)previewRect
{
    self.preview = parent;
    
    //1创建队列
    [self createQueue];
    //2添加session
    [self addSession];
    //3添加相机的预览界面
    [self addVideoPreviewLayerWithRect:previewRect];
    
    //4添加输入设备
    [self addVideoInputFromCamera:NO];
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
-(void)addVideoPreviewLayerWithRect: (CGRect)previewRect
{
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    previewLayer.videoGravity = AVLayerVideoGravityResize;
    previewLayer.frame  = previewRect;
    self.previewLayer = previewLayer;
}

/**
 *  添加输入设备
 *
 *  @param isFront 是否是前置摄像头
 */
- (void)addVideoInputFromCamera:(BOOL)isFront
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
    if ([self.session canAddOutput:stillImageOut]) {
        [self.session addOutput:stillImageOut];
    }
}
- (void)takePicture:(didCapturePhotoBlock)didCaptureBlock
{
    AVCaptureConnection *captureConnection = [self.stillImageOut connectionWithMediaType:AVMediaTypeVideo];
     [self.stillImageOut captureStillImageAsynchronouslyFromConnection:captureConnection
                        completionHandler:^(CMSampleBufferRef imageDataSampleBuffer,
                                                                         NSError *error){
                            if (!error)
                            {
                                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                UIImage *image = [UIImage imageWithData:imageData];
                              //在这里计算得到新的图片的frame和新的图片
                                CGFloat squareLength =  screenW;
                                CGFloat headHeight = self.previewLayer.bounds.size.height - squareLength;
                                CGSize size = CGSizeMake(squareLength *2, squareLength *2);
//                                UIImage *scaledImage = [image ]
                                
                                
                                
                                
                                
                                
                                

                            }else
                            {
                                WYLog(@"%@",error);
                            }
                            
                            
         
     }];
}




@end
