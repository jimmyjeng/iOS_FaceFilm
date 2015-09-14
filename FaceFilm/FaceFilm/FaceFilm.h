//
//  FaceFilm.h
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/11.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FaceFilm : NSObject
- (instancetype) initWithImageArray:(NSArray *)images;
- (UIImage *)getImageByFrameIndex:(int)index;

@end
