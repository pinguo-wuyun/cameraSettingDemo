//
//  WYAVCameraPreviewView.h
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-18.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface WYAVCameraPreviewView : UIView

/**
 *  展示界面层的session
 */
@property (nonatomic,strong)AVCaptureSession *session;

@end
