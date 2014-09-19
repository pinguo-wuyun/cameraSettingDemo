//
//  UIImage+Extension.m
//  cameraSettingDemo
//
//  Created by camera360 on 14-9-19.
//  Copyright (c) 2014年 camera360. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)
- (instancetype)resizedImageWithContentMode:(UIViewContentMode)contenMode
                                     bounds:(CGSize)bounds
                       interpolationQuality:(CGInterpolationQuality)quality
{
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    CGFloat ratio;
    
    switch (contenMode) {
        case UIViewContentModeScaleAspectFill:
            ratio = MAX(horizontalRatio, verticalRatio);
            break;
            
        case UIViewContentModeScaleAspectFit:
            ratio = MIN(horizontalRatio, verticalRatio);
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException format:@"unspoortedMode : %ld",contenMode];
    }
    CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
    return [self resizedImage:newSize interPolationQuality:quality];
}


- (instancetype)resizedImage:(CGSize)newSize interPolationQuality:(CGInterpolationQuality)quality
{
    BOOL drawTransposed;
    CGAffineTransform transform = CGAffineTransformIdentity;

    if ([[UIDevice currentDevice].systemVersion floatValue] > 5.0)
    {
        drawTransposed = YES;
    }else
    {
        switch (self.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                drawTransposed = YES;
                break;
                
            default:
                drawTransposed = NO;
                break;
        }
        
    }
    transform = [self transformForOrientation:newSize];
    return nil;
}

//TODO: 这里要做修改图片
- (CGAffineTransform)transformForOrientation:(CGSize)newSize
{
    CGAffineTransform tranform = CGAffineTransformIdentity;
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            break;
            
        default:
            break;
    }
    return tranform;
}

@end
