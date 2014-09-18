//
//  WYAVCameraPreviewView.m
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-18.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import "WYAVCameraPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation WYAVCameraPreviewView

+(Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

/**
返回层的session
 */
-(AVCaptureSession *)session
{
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

//设置session
-(void)setSession:(AVCaptureSession *)session
{
    [(AVCaptureVideoPreviewLayer *)[self layer]setSession:session];
}




@end
