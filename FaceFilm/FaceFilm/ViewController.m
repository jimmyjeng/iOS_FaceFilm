//
//  ViewController.m
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/4.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import "ViewController.h"

#define MOVIE_WIDTH 800.0f
#define MOVIE_HEIGHT 450.0f
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property int times;
@property float alpha;
@property NSMutableArray *imageArray;
@property NSMutableArray *faceArray;
@property int totalPic;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.times = 0;
    self.alpha = 0;
    self.totalPic = 12;
    self.imageArray = [[NSMutableArray alloc]init];
    self.faceArray = [[NSMutableArray alloc]init];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [self loadimage];

    UIImage *bgImage = [UIImage imageNamed:@"bg.png"];
    bgImage = [self imageWithImage:bgImage scaledToSize:CGSizeMake(self.imageView.frame.size.width,self.imageView.frame.size.height)];
    [self.imageView setImage:bgImage];

    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(createImageAnimation:) userInfo:nil repeats:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadimage {
    for (int i = 1; i <= self.totalPic; i++) {
        NSString *fileName = [NSString stringWithFormat:@"%02d.png",i];
        UIImage *image = [UIImage imageNamed:fileName];
        [self.imageArray addObject:image];
    }
    
    NSDate *start = [NSDate date];
    [self faceDetection];
    NSLog(@"faceDetection take : %f second" ,[[NSDate date] timeIntervalSinceDate:start]);
}

- (void)createImageAnimation:(NSTimer *)theTimer {
    if (self.alpha > 1) {
        self.alpha = 0;
    }
    
    if (self.times >= self.totalPic * 10) {
        [theTimer invalidate];
        return;
    }
//    NSString *fileName = [NSString stringWithFormat:@"%02d.png",(self.times/10)+1];
//    UIImage *image = [UIImage imageNamed:fileName];
    UIImage *image = [self.imageArray objectAtIndex:self.times /10];
    image = [self imageWithBorderFromImage:image];
    image = [self imageWithImage:image alpha:self.alpha];
    image = [self imageWithBackgroundImage:self.imageView.image frontImage:image];
//    [self.imageArray addObject:image];
    [self.imageView setImage:image];
    self.times += 1;
    self.alpha += 0.1;
    
//    UIImage *viewImage = [self imageFromView:self.view];
//    UIImageWriteToSavedPhotosAlbum(self.image.image,nil,nil,nil);
}

// scale
- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
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
- (UIImage *)imageWithImage:(UIImage*)image alpha:(CGFloat) alpha {
    UIImage *newImage = nil;

    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    
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
- (UIImage*)imageWithBorderFromImage:(UIImage*)image {
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
- (UIImage *)imageFromView:(UIView *)view {
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

- (UIImage *)imageWithBackgroundImage:(UIImage *)backgroundImage frontImage:(UIImage *)frontImage{
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(backgroundImage.size, NO, 0.0);
    CGRect rect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
    [backgroundImage drawInRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    int index = (self.times/10);
    NSArray* detectResult = [self.faceArray objectAtIndex:index];
    
    float eyeX = -1;
    float eyeY = -1;

    for(CIFaceFeature* faceFeature in detectResult) {
//        CGContextRotateCTM (context, [self radians:-faceFeature.faceAngle]);
        eyeX = backgroundImage.size.width/2 -( (faceFeature.leftEyePosition.x + faceFeature.rightEyePosition.x) /2 );
        eyeY = MOVIE_HEIGHT * 0.36 + (faceFeature.leftEyePosition.y + faceFeature.rightEyePosition.y) /2 - frontImage.size.height;
    }
    
    // if can't detect face , then put the image at middle
    float newX = (eyeX == -1 )? backgroundImage.size.width/2 - frontImage.size.width/2 :  eyeX;
    float newY = (eyeY == -1 )? backgroundImage.size.height/2 - frontImage.size.height/2 : eyeY;
    
    CGRect rectDstDraw = CGRectMake(newX, newY, frontImage.size.width, frontImage.size.height);
    [frontImage drawInRect:rectDstDraw];
    
    // add face detection
    if (detectResult) {
        for(CIFaceFeature* faceFeature in detectResult) {
            CGRect rectangle;
            CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
            
            // face
            rectangle = CGRectMake(faceFeature.bounds.origin.x + newX, frontImage.size.height - faceFeature.bounds.origin.y + newY - faceFeature.bounds.size.height, faceFeature.bounds.size.width, faceFeature.bounds.size.height);
            CGContextStrokeRect(context, rectangle);
            
            // left eye
            rectangle = CGRectMake(faceFeature.leftEyePosition.x + newX, frontImage.size.height - faceFeature.leftEyePosition.y + newY ,5 , 5);
            CGContextStrokeRect(context, rectangle);
            
            // right eye
            rectangle = CGRectMake(faceFeature.rightEyePosition.x + newX, frontImage.size.height - faceFeature.rightEyePosition.y + newY ,5 , 5);
            CGContextStrokeRect(context, rectangle);
            
            // mouth
            rectangle = CGRectMake(faceFeature.mouthPosition.x + newX, frontImage.size.height - faceFeature.mouthPosition.y + newY ,10 , 5);
            CGContextStrokeRect(context, rectangle);
            
            if (self.times % 10 == 0) {
                NSLog(@"Pic[%02d] , faceAngle[%.1f]  eye distance[%.1f]",self.times/10+1 , faceFeature.faceAngle , faceFeature.leftEyePosition.x - faceFeature.rightEyePosition.x);
            }
            
        }
    }


    newImage = UIGraphicsGetImageFromCurrentImageContext();

    if (newImage == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();

    return newImage;
}

- (void)faceDetection {
    for (int i = 0; i < self.totalPic; i++) {
        UIImage *image = [self.imageArray objectAtIndex:i];
        CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
        
        CIDetector* faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                      context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
        
        NSArray *detectResult = [faceDetector featuresInImage:ciImage];
        if (detectResult) {
            [self.faceArray addObject:detectResult];
            
            // resize image to fit size
//            CGFloat widthFactor = MOVIE_WIDTH / image.size.width;
//            CGFloat heightFactor = MOVIE_HEIGHT / image.size.height;
//            CGFloat factor = (widthFactor > heightFactor)? heightFactor:widthFactor;
//
//            UIImage *resizeImage = [self imageWithImage:image scaledToSize:CGSizeMake(image.size.width*factor, image.size.height*factor)];
//            [self.imageArray replaceObjectAtIndex:i withObject:resizeImage];
        }
    }
}

- (float)radians:(double) degrees {
    return degrees * M_PI/180;
}

@end
