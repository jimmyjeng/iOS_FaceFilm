//
//  Utillity.m
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/11.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import "Utillity.h"
#
@implementation Utillity

// scale
+ (UIImage*)imageWithSize:(CGSize)newSize image:(UIImage*)image {
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();
    return newImage;
}

// alpha
+ (UIImage *)imageWithAlpha:(CGFloat)alpha image:(UIImage*)image  {
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // draw cgimage is upside down
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextSetAlpha(context, alpha);
    CGContextDrawImage(context, rect, image.CGImage);
    
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();

    return newImage;
}

// border
+ (UIImage *)imageWithBorder:(UIImage *)image {
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContext(image.size);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    [image drawInRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 10.0);
    CGContextStrokeRect(context, rect);
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();

    return newImage;
}

//  take UIImage from view
+ (UIImage *)imageFromView:(UIView *)view {
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (float)radians:(double) degrees {
    return degrees * M_PI/180;
}


+ (UIImage *)imageSize:(CGSize)sizeTarget srcOvalize:(UIImage *)imageSrc border:(BOOL)bBorder {
    // Create the bitmap graphics context
    UIGraphicsBeginImageContextWithOptions(sizeTarget, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Get the width and heights
    CGFloat fWidthSrc = imageSrc.size.width;
    CGFloat fHeightSrc = imageSrc.size.height;
    CGFloat fWidthDst = sizeTarget.width;
    CGFloat fHeightDst = sizeTarget.height;
    
    // Calculate the scale factor
    CGFloat fScaleX = fWidthDst / fWidthSrc;
    CGFloat fScaleY = fHeightDst / fHeightSrc;
    
    // Create and CLIP to a CIRCULAR Path
    CGFloat kInsetRatio = 0.01;
    CGRect rectEllipse = CGRectMake(0, 0, fWidthDst, fHeightDst);
    
    if (bBorder) {
        rectEllipse = CGRectInset(rectEllipse, fWidthDst * kInsetRatio, fHeightDst * kInsetRatio);
    }
    
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, rectEllipse);
    CGContextClosePath(context);
    CGContextClip(context);
    
    // Set the SCALE factor for the graphics context, All future draw calls will be scaled by this factor
    CGContextScaleCTM(context, fScaleX, fScaleY);
    
    // Draw the IMAGE
    CGRect rectSrc = CGRectMake(0, 0, fWidthSrc, fHeightSrc);
    if (bBorder) {
        rectSrc = CGRectInset(rectSrc, fWidthSrc * kInsetRatio, fHeightSrc * kInsetRatio);
    }
    
    [imageSrc drawInRect:rectSrc];
    
    // Restore
    CGContextRestoreGState(context);
    
    if (bBorder) {
        CGContextSetShouldAntialias(context, YES);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor);
        
        CGFloat fLineWidth = fWidthDst / 40.0;
        if (fLineWidth > 3.0) {
            fLineWidth = 3.0;
        }
        
        CGContextSetLineWidth(context, fLineWidth);
        CGContextStrokeEllipseInRect(context, CGRectMake(fLineWidth / 2.0, fLineWidth / 2.0, fWidthDst - fLineWidth, fHeightDst - fLineWidth));
    }
    
    UIImage *imageTarget = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageTarget;
}
@end
