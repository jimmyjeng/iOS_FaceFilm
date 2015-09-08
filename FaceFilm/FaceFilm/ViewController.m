//
//  ViewController.m
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/4.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import "ViewController.h"

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
    self.totalPic = 8;
    self.imageArray = [[NSMutableArray alloc]init];
    self.faceArray = [[NSMutableArray alloc]init];
    
}

-(void)viewDidAppear:(BOOL)animated {
    NSDate *start = [NSDate date];
    [self faceDetection];
    NSLog(@"faceDetection take : %f second" ,[[NSDate date] timeIntervalSinceDate:start]);
    
    UIImage *bgImage = [UIImage imageNamed:@"bg.png"];
    bgImage = [self imageWithImage:bgImage scaledToSize:CGSizeMake(self.imageView.frame.size.width,self.imageView.frame.size.height)];
    [self.imageView setImage:bgImage];

    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(createImage:) userInfo:nil repeats:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createImage:(NSTimer *)theTimer {
    if (self.alpha > 1) {
        self.alpha = 0;
    }
    
    if (self.times >= self.totalPic * 10) {
        [theTimer invalidate];
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%02d.png",(self.times/10)+1];

    UIImage *image = [UIImage imageNamed:fileName];
    image = [self imageWithBorderFromImage:image];
    image = [self imageWithImage:image alpha:self.alpha];
    image = [self imageWithBackgroundImage:self.imageView.image frontImage:image];
    [self.imageArray addObject:image];
    [self.imageView setImage:image];
    self.times += 1;
    self.alpha+=0.1;
    
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
    
    float newX = backgroundImage.size.width/2 - frontImage.size.width/2;
    float newY =  backgroundImage.size.height/2 - frontImage.size.height/2;
    
    CGRect rectDstDraw = CGRectMake(newX, newY, frontImage.size.width, frontImage.size.height);
    [frontImage drawInRect:rectDstDraw];
    
    // add face detection
    CGContextRef context = UIGraphicsGetCurrentContext();

    int index = (self.times/10);
    NSArray* detectResult = [self.faceArray objectAtIndex:index];

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
            NSLog(@"Pic[%d] , faceAngle[%f]",self.times/10+1 , faceFeature.faceAngle);
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
    for (int i = 1; i <= self.totalPic; i++) {
        NSString *fileName = [NSString stringWithFormat:@"%02d.png",i];
        UIImage *imageSource = [UIImage imageNamed:fileName];
        CIImage *image = [CIImage imageWithCGImage:imageSource.CGImage];
        
        CIDetector* faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                      context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
        
        NSArray *detectResult = [faceDetector featuresInImage:image];
        if (detectResult) {
            [self.faceArray addObject:detectResult];
        }
    }
}

@end
