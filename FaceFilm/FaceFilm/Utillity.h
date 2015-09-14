//
//  Utillity.h
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/11.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utillity : NSObject

+ (UIImage *)imageWithSize:(CGSize)newSize image:(UIImage*)image;
+ (UIImage *)imageWithAlpha:(CGFloat)alpha image:(UIImage*)image;
+ (UIImage *)imageWithBorder:(UIImage *)image;
+ (UIImage *)imageFromView:(UIView *)view;

+ (float)radians:(double) degrees;
+ (UIImage *)imageSize:(CGSize)sizeTarget srcOvalize:(UIImage *)imageSrc border:(BOOL)bBorder;
@end
