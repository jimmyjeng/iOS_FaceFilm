//
//  FaceFilm.m
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/11.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import "FaceFilm.h"
#import "Utillity.h"

#define MOVIE_WIDTH 800.0f
#define MOVIE_HEIGHT 450.0f

#define EYE_X_DISTANCE_PERCENT 0.1f
#define EYE_Y_DISTANCE_PERCENT 0.36f

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@interface FaceFilm()
@property NSMutableArray *imageArray;
@property NSMutableDictionary *detectResultDict;
@property UIImage *bgImage;

@end

@implementation FaceFilm
- (instancetype) initWithImageArray:(NSArray *)images {
    self = [self init];
    if (self) {
        
        self.imageArray = [[NSMutableArray alloc]init];
        self.detectResultDict = [[NSMutableDictionary alloc]init];
        self.bgImage = [Utillity imageWithSize:CGSizeMake(800,450) image:[UIImage imageNamed:@"bg.png"]];

        for (int i = 0; i < [images count]; i++) {
            UIImage *image = [images objectAtIndex:i];
            image = [Utillity imageWithBorder:image];
            [self.imageArray addObject:image];
        }
        
        [self faceDetection];
    }
    return self;
}

- (void)faceDetection {
    // key 0 ~ n-1
    for (int i = 0; i < [self.imageArray count]; i++) {
        UIImage *image = [self.imageArray objectAtIndex:i];
        CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
        
        CIDetector* faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                      context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
        
        NSArray *detectResult = [faceDetector featuresInImage:ciImage];
        NSString *key = [NSString stringWithFormat:@"%02d",i];
        [self.detectResultDict setObject:detectResult forKey:key];
    }
}

// frameIndex 0 ~ 99
- (UIImage *)getImageByFrameIndex:(int)index {
    UIImage *image = [self.imageArray objectAtIndex:index /10];
    float alpha = (index % 10)/10.0 + 0.1;
    UIImage *alphaImage = [Utillity imageWithAlpha:alpha image:image];
    UIImage *finalImage = [self imageWithBackgroundImage:self.bgImage frontImage:alphaImage frameIndex:index];
    self.bgImage = finalImage;
    return finalImage;
}

// draw uiimage on uiimage by face position
- (UIImage *)imageWithBackgroundImage:(UIImage *)backgroundImage frontImage:(UIImage *)frontImage frameIndex:(int)frameIndex{
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(backgroundImage.size, NO, 0.0);
    CGRect rect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
    [backgroundImage drawInRect:rect];
    
    int index = (frameIndex/10);
    NSString *key = [NSString stringWithFormat:@"%02d",index];
    NSArray* detectResult = [self.detectResultDict objectForKey:key];
    CIFaceFeature *bigFaceFeature = nil;
    if ([detectResult count] > 0) {
        bigFaceFeature = [detectResult objectAtIndex:0];
        for(CIFaceFeature* faceFeature in detectResult) {
            if (faceFeature.bounds.size.height * faceFeature.bounds.size.width > bigFaceFeature.bounds.size.height * bigFaceFeature.bounds.size.width) {
                bigFaceFeature = faceFeature;
            }
        }
    }
    float offsetX = -1;
    float offsetY = -1;
    float eyeDistance = -1;
    float scaleFactor = 1 ;
    CGSize newFrontImageSize = frontImage.size;
    if(bigFaceFeature) {
        // calculate eye's distance for scale front image
        eyeDistance = fabs(bigFaceFeature.leftEyePosition.x - bigFaceFeature.rightEyePosition.x);
        scaleFactor = (eyeDistance == -1 )? scaleFactor : MOVIE_WIDTH * EYE_X_DISTANCE_PERCENT / eyeDistance;
        newFrontImageSize = CGSizeMake(frontImage.size.width*scaleFactor, frontImage.size.height*scaleFactor);
        
        //  let eye's distance is MOVIE_WIDTH * EYE_X_DISTANCE_PERCENT and at X center
        offsetX = backgroundImage.size.width/2 -( (bigFaceFeature.leftEyePosition.x + bigFaceFeature.rightEyePosition.x) * scaleFactor /2 );
        // let eye is MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT from top at y axis
        offsetY = MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT + (bigFaceFeature.leftEyePosition.y + bigFaceFeature.rightEyePosition.y) *scaleFactor /2 - newFrontImageSize.height;
    }
    
    // if can't detect face , then put the image at middle
    float newX = (offsetX == -1 )? backgroundImage.size.width/2 - newFrontImageSize.width/2 :  offsetX;
    float newY = (offsetY == -1 )? backgroundImage.size.height/2 - newFrontImageSize.height/2 : offsetY;
    
    CGRect rectDstDraw = CGRectMake(newX, newY, newFrontImageSize.width, newFrontImageSize.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    float faceAngle = 0.0;
    float x = 0.0;
    float y = 0.0;
    if (bigFaceFeature ) {
            x = newX + (bigFaceFeature.leftEyePosition.x + bigFaceFeature.rightEyePosition.x) * scaleFactor /2;
            y = MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT ;
            faceAngle = bigFaceFeature.faceAngle;
            CGContextTranslateCTM(context, x, y);
            CGContextRotateCTM (context, [Utillity radians:-bigFaceFeature.faceAngle]);
            CGContextTranslateCTM(context, -x, -y);
        
    }
    
    [frontImage drawInRect:rectDstDraw];
    
    // rotate back to write
    CGContextTranslateCTM(context, x, y);
    CGContextRotateCTM (context, [Utillity radians:faceAngle]);
    CGContextTranslateCTM(context, -x, -y);
    
    UIFont *font = [UIFont boldSystemFontOfSize:20.0];
    NSString *waterMark = @"Made With Lollipop";
    UIColor* textColor = [UIColor redColor];
    
    NSDictionary *attributes = @{NSFontAttributeName: font , NSForegroundColorAttributeName:textColor};
    CGSize fontSize = [waterMark sizeWithAttributes:attributes];
    
    CGRect fontRect = CGRectMake(0.0, backgroundImage.size.height - fontSize.height, fontSize.width, fontSize.height);
    
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:waterMark attributes:attributes];
    [attributedString drawInRect:fontRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}
@end
