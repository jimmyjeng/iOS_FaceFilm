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

#define EYE_X_DISTANCE_PERCENT 0.1f
#define EYE_Y_DISTANCE_PERCENT 0.36f

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property int times;
@property float alpha;
@property NSMutableArray *imageArray;
@property NSMutableArray *faceArray;
@property int totalPic;
@property NSTimer *updateTimer;
@property (weak, nonatomic) IBOutlet UIView *line1;
@property (weak, nonatomic) IBOutlet UIView *line2;
@property (weak, nonatomic) IBOutlet UISwitch *debugSwitch;
@property BOOL ready;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.times = 0;
    self.alpha = 0;
    self.totalPic = 10;
    self.imageArray = [[NSMutableArray alloc]init];
    self.faceArray = [[NSMutableArray alloc]init];
    self.updateTimer = nil;
    self.ready = NO;
    [self.debugSwitch addTarget:self action:@selector(setDebugState:) forControlEvents:UIControlEventValueChanged];

}

-(void)viewDidAppear:(BOOL)animated {
    [self prepareImage];

    UIImage *bgImage = [UIImage imageNamed:@"bg.png"];
    bgImage = [self imageWithImage:bgImage scaledToSize:CGSizeMake(self.imageView.frame.size.width,self.imageView.frame.size.height)];
    [self.imageView setImage:bgImage];
}

- (IBAction)pressStart:(id)sender {
    if (self.ready == NO) {
        return;
    }
    self.times = 0;
    self.alpha = 0;
    UIImage *bgImage = [UIImage imageNamed:@"bg.png"];
    bgImage = [self imageWithImage:bgImage scaledToSize:CGSizeMake(self.imageView.frame.size.width,self.imageView.frame.size.height)];
    [self.imageView setImage:bgImage];
    if (self.updateTimer ) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(createImageAnimation:) userInfo:nil repeats:YES];

}

- (void)setDebugState:(id)sender {
    [self.line1 setHidden:!self.debugSwitch.on];
    [self.line2 setHidden:!self.debugSwitch.on];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareImage {
    //  load image
    for (int i = 1; i <= self.totalPic; i++) {
        NSString *fileName = [NSString stringWithFormat:@"%02d.png",i];
        UIImage *image = [UIImage imageNamed:fileName];
        [self.imageArray addObject:image];
    }
    
    //  add border
    for (int i = 0; i < self.totalPic; i++) {
        UIImage *image = [self.imageArray objectAtIndex:i];
        image = [self imageWithBorderImage:image];
        [self.imageArray replaceObjectAtIndex:i withObject:image];
    }

    // face detect
    NSDate *start = [NSDate date];
    [self faceDetection];
    NSLog(@"faceDetection take : %f second" ,[[NSDate date] timeIntervalSinceDate:start]);
}

- (void)createImageAnimation:(NSTimer *)theTimer {
    if (self.alpha > 1) {
        self.alpha = 0;
    }
    
    if (self.times >= self.totalPic * 10) {
        [self.updateTimer invalidate];
        return;
    }

    UIImage *image = [self.imageArray objectAtIndex:self.times /10];
    image = [self imageWithImage:image alpha:self.alpha];
    image = [self imageWithBackgroundImage:self.imageView.image frontImage:image];
    [self.imageView setImage:image];
    self.times += 1;
    self.alpha += 0.1;
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
- (UIImage *)imageWithBorderImage:(UIImage *)image {
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

// draw uiimage on uiimage
- (UIImage *)imageWithBackgroundImage:(UIImage *)backgroundImage frontImage:(UIImage *)frontImage{
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(backgroundImage.size, NO, 0.0);
    CGRect rect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
    [backgroundImage drawInRect:rect];
    
    int index = (self.times/10);
    NSArray* detectResult = [self.faceArray objectAtIndex:index];
    
    float offsetX = -1;
    float offsetY = -1;
    float eyeDistance = -1;
    float scaleFactor = 1;
    CGSize newFrontImageSize = frontImage.size;
    for(CIFaceFeature* faceFeature in detectResult) {
        // calculate eye's distance for scale front image
        eyeDistance = fabs(faceFeature.leftEyePosition.x - faceFeature.rightEyePosition.x);
        scaleFactor = (eyeDistance == -1 )? 1 : MOVIE_WIDTH * EYE_X_DISTANCE_PERCENT / eyeDistance;
        newFrontImageSize = CGSizeMake(frontImage.size.width*scaleFactor, frontImage.size.height*scaleFactor);
        
        //  let eye's distance is MOVIE_WIDTH * EYE_X_DISTANCE_PERCENT and at X center
        offsetX = backgroundImage.size.width/2 -( (faceFeature.leftEyePosition.x + faceFeature.rightEyePosition.x) * scaleFactor /2 );
        // let eye is MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT from top at y axis
        offsetY = MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT + (faceFeature.leftEyePosition.y + faceFeature.rightEyePosition.y) *scaleFactor /2 - newFrontImageSize.height;
    }
    
    // if can't detect face , then put the image at middle
    float newX = (offsetX == -1 )? backgroundImage.size.width/2 - newFrontImageSize.width/2 :  offsetX;
    float newY = (offsetY == -1 )? backgroundImage.size.height/2 - newFrontImageSize.height/2 : offsetY;
    
    CGRect rectDstDraw = CGRectMake(newX, newY, newFrontImageSize.width, newFrontImageSize.height);
    CGContextRef context = UIGraphicsGetCurrentContext();

    float a = 0.0;
    float x = 0.0;
    float y = 0.0;
    if (detectResult ) {
        for(CIFaceFeature* faceFeature in detectResult) {
             x = newX + (faceFeature.leftEyePosition.x + faceFeature.rightEyePosition.x) * scaleFactor /2;
             y = MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT ;
            a = faceFeature.faceAngle;
            CGContextTranslateCTM(context, x, y);
            CGContextRotateCTM (context, [self radians:-faceFeature.faceAngle]);
            CGContextTranslateCTM(context, -x, -y);
        }
    }

    [frontImage drawInRect:rectDstDraw];
    
    if (detectResult ) {
        for(CIFaceFeature* faceFeature in detectResult) {
            if (self.debugSwitch.on) {
                CGRect rectangle;
                CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
                // face
                rectangle = CGRectMake(faceFeature.bounds.origin.x * scaleFactor + newX, newFrontImageSize.height - faceFeature.bounds.origin.y * scaleFactor + newY - faceFeature.bounds.size.height * scaleFactor, faceFeature.bounds.size.width * scaleFactor, faceFeature.bounds.size.height * scaleFactor);
                CGContextStrokeRect(context, rectangle);
                
                // left eye
                rectangle = CGRectMake(faceFeature.leftEyePosition.x * scaleFactor + newX, newFrontImageSize.height - faceFeature.leftEyePosition.y * scaleFactor + newY ,5 , 5);
                CGContextStrokeRect(context, rectangle);
                
                // right eye
                rectangle = CGRectMake(faceFeature.rightEyePosition.x * scaleFactor + newX, newFrontImageSize.height - faceFeature.rightEyePosition.y * scaleFactor + newY ,5 , 5);
                CGContextStrokeRect(context, rectangle);
                
                // mouth
                rectangle = CGRectMake(faceFeature.mouthPosition.x * scaleFactor + newX, newFrontImageSize.height - faceFeature.mouthPosition.y * scaleFactor + newY ,10 , 5);
                CGContextStrokeRect(context, rectangle);
                
                if (self.times % 10 == 0) {
                    NSLog(@"Pic[%02d] , faceAngle[%.1f]  eye distance[%.1f]",self.times/10+1 , faceFeature.faceAngle , faceFeature.leftEyePosition.x - faceFeature.rightEyePosition.x);
                }
            }
        }
    }
    
    
    CGContextTranslateCTM(context, x, y);

    CGContextRotateCTM (context, [self radians:a]);

    CGContextTranslateCTM(context, -x, -y);
    
    UIFont *font = [UIFont boldSystemFontOfSize:20.0];
    NSString *waterMark = @"Made by Jimmy";
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

- (void)faceDetection {
    for (int i = 0; i < self.totalPic; i++) {
        UIImage *image = [self.imageArray objectAtIndex:i];
        CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
        
        CIDetector* faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                      context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
        
        NSArray *detectResult = [faceDetector featuresInImage:ciImage];
        if (detectResult) {
            [self.faceArray addObject:detectResult];

        }
    }
    
    self.ready = YES;
}

- (float)radians:(double) degrees {
    return degrees * M_PI/180;
}

@end
