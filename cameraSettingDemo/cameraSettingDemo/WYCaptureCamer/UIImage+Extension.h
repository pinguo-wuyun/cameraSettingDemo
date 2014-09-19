//
//  UIImage+Extension.h
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-19.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)

- (instancetype)resizedImageWithContentMode:(UIViewContentMode)contenMode
                                     bounds:(CGSize)bounds
                       interpolationQuality:(CGInterpolationQuality)quality;

@end
