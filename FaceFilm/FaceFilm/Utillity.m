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



@end
