//
//  WYCaptureSessionManger.h
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-19.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>




const CGFloat maxPinchScaleNum = 3.f;
const CGFloat minPinchScaleNum = 1.f;

typedef void(^didCapturePhotoBlock)(UIImage *image);
/**
 *  这个类是对相机类的封装，是个可以使用相机的工具类
 */
@interface WYCaptureSessionManger : NSObject

//暴露在外面的属性


/**
 *  连接输入和输出设备的session
 */
@property (nonatomic,strong) AVCaptureSession           *session;

/**
 *  输入设备
 */
@property (nonatomic,strong) AVCaptureDeviceInput       *inputDevice;

/**
 *  输出设备
 */
@property (nonatomic,strong) AVCaptureStillImageOutput  *stillImageOut;

/**
 *  执行队列
 */
@property (nonatomic       ) dispatch_queue_t           sessionQueue;
/**
 *  展示层
 */
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;


//pinch

@property (nonatomic,assign) CGFloat                    preScaleNum;

@property (nonatomic,assign) CGFloat                    scaleNum;



//提供的一些关于相机的方法

/**
 *  配置相机相关的一些属性
 *
 *  @param parent      父控件，扑捉的图片将要显示的view
 *  @param previewRect 照相机图片预览将要显示的尺寸
 */
- (void)configureWithPartentLayer:(UIView *)parent previewRect:(CGRect)previewRect;

/**
 *  拍照
 */
- (void)takePicture:(didCapturePhotoBlock) didCaptureBlock;

/**
 *  切换前后照相头
 *
 *  @param isFrontCamer 是否是前置摄像头
 */
- (void)swithCamer:(BOOL)isFrontCamer;

/**
 *  设置照相机的缩放尺寸
 *
 *  @param scale 缩放比例
 */
- (void)pinchCamerViewWithScaleNum:(CGFloat)scale;

/**
 *  缩放摄像头
 */
- (void)pinchcamerView:(UIGestureRecognizer *)gesture;


//- (void)switchFlashMode:(uibu)
/**
 *  设置聚焦点
 *
 */
- (void)focusInPoint:(CGPoint)devicePoint;

/**
 *  开启网格模式
 *
 */
- (void)swithGrid:(BOOL)toShow;


@end
