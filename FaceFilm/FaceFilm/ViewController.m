//
//  ViewController.m
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/4.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import "ViewController.h"
#import "MovieMaker.h"
#import "Utillity.h"
#import "FaceFilm.h"

#define MOVIE_WIDTH 800.0f / 2.0
#define MOVIE_HEIGHT 450.0f / 2.0

#define EYE_X_DISTANCE_PERCENT 0.1f
#define EYE_Y_DISTANCE_PERCENT 0.36f

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property NSMutableArray *imageArray;
@property NSArray *detectResult;
@property int totalPic;
@property (weak, nonatomic) IBOutlet UIView *line1;
@property (weak, nonatomic) IBOutlet UIView *line2;
@property CIFaceFeature* bigFaceFeature;
@property int testImageIndex;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // change picture number here
    self.totalPic = 10;
    self.imageArray = [[NSMutableArray alloc]init];
    self.detectResult = [[NSArray alloc]init];
    self.bigFaceFeature = nil;
    self.testImageIndex = 0;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self prepareImage];
}

- (IBAction)pressStart:(id)sender {
    self.bigFaceFeature = nil;
    UIImage *image = [UIImage imageNamed:@"bg.png"];
    image = [Utillity imageWithSize:CGSizeMake(self.imageView.frame.size.width,self.imageView.frame.size.height) image:image];
    [self.imageView setImage:image];
    
    self.testImageIndex ++;
    if (self.testImageIndex > 4) {
        self.testImageIndex = 1;
    }
    
    NSString *fileName = [NSString stringWithFormat:@"Test%02d.png",self.testImageIndex];
    image = [UIImage imageNamed:fileName];
    [self oneFaceDetection:image];

    image = [self imageWithBackgroundImage:self.imageView.image frontImage:image];
    [self.imageView setImage:image];
}

- (IBAction)pressSave:(id)sender {
    MovieMaker *movieMaker = [[MovieMaker alloc ]initWithImages];
    [movieMaker createMovieFromImages:self.imageArray withCompletion:^(BOOL succeed){
        if ([NSThread isMainThread]) {
            [self completeMessage:succeed];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self completeMessage:succeed];
            });
        }
        // get main thread
        
    }];
}

- (void)completeMessage:(BOOL) succeed {
    NSString *message = @"save done";
    if (!succeed) {
        message = @"save fail";
    }
    
    UIAlertView *alert =[ [UIAlertView alloc] initWithTitle:@"Video" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
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

}

- (void)oneFaceDetection:(UIImage *)image {
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    
    CIDetector* faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                  context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    
    self.detectResult = [faceDetector featuresInImage:ciImage];
    if ([self.detectResult count] > 0) {
        self.bigFaceFeature = [self.detectResult objectAtIndex:0];
        for(CIFaceFeature* faceFeature in self.detectResult) {
            if (faceFeature.bounds.size.height * faceFeature.bounds.size.width > self.bigFaceFeature.bounds.size.height * self.bigFaceFeature.bounds.size.width) {
                self.bigFaceFeature = faceFeature;
            }
        }
    }
}

// draw uiimage on uiimage by face position
- (UIImage *)imageWithBackgroundImage:(UIImage *)backgroundImage frontImage:(UIImage *)frontImage {
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(backgroundImage.size, NO, 0.0);
    CGRect rect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
    [backgroundImage drawInRect:rect];
    
    float offsetX = -1;
    float offsetY = -1;
    float eyeDistance = -1;
    float scaleFactor = 1;
    CGSize newFrontImageSize = frontImage.size;
    
    if(self.bigFaceFeature) {
        // calculate eye's distance for scale front image
        eyeDistance = fabs(self.bigFaceFeature.leftEyePosition.x - self.bigFaceFeature.rightEyePosition.x);
        scaleFactor = (eyeDistance == -1 )? 1 : MOVIE_WIDTH * EYE_X_DISTANCE_PERCENT / eyeDistance;
        newFrontImageSize = CGSizeMake(frontImage.size.width*scaleFactor, frontImage.size.height*scaleFactor);
        
        //  let eye's distance is MOVIE_WIDTH * EYE_X_DISTANCE_PERCENT and at X center
        offsetX = backgroundImage.size.width/2 -( (self.bigFaceFeature.leftEyePosition.x + self.bigFaceFeature.rightEyePosition.x) * scaleFactor /2 );
        // let eye is MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT from top at y axis
        offsetY = MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT + (self.bigFaceFeature.leftEyePosition.y + self.bigFaceFeature.rightEyePosition.y) *scaleFactor /2 - newFrontImageSize.height;
    }

 
    
    // if can't detect face , then put the image at middle
    float newX = (offsetX == -1 )? backgroundImage.size.width/2 - newFrontImageSize.width/2 :  offsetX;
    float newY = (offsetY == -1 )? backgroundImage.size.height/2 - newFrontImageSize.height/2 : offsetY;
    
    CGRect rectDstDraw = CGRectMake(newX, newY, newFrontImageSize.width, newFrontImageSize.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    float faceAngle = 0.0;
    float x = 0.0;
    float y = 0.0;
    
    if (self.bigFaceFeature) {
        x = newX + (self.bigFaceFeature.leftEyePosition.x + self.bigFaceFeature.rightEyePosition.x) * scaleFactor /2;
        y = MOVIE_HEIGHT * EYE_Y_DISTANCE_PERCENT ;
        faceAngle = self.bigFaceFeature.faceAngle;
        CGContextTranslateCTM(context, x, y);
        CGContextRotateCTM (context, [Utillity radians:-self.bigFaceFeature.faceAngle]);
        CGContextTranslateCTM(context, -x, -y);
    }
    
    [frontImage drawInRect:rectDstDraw];
    
    if (self.bigFaceFeature) {
        
        CGRect rectangle;
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        // face
        rectangle = CGRectMake(self.bigFaceFeature.bounds.origin.x * scaleFactor + newX, newFrontImageSize.height - self.bigFaceFeature.bounds.origin.y * scaleFactor + newY - self.bigFaceFeature.bounds.size.height * scaleFactor, self.bigFaceFeature.bounds.size.width * scaleFactor, self.bigFaceFeature.bounds.size.height * scaleFactor);
        CGContextStrokeRect(context, rectangle);
        
        // left eye
        rectangle = CGRectMake(self.bigFaceFeature.leftEyePosition.x * scaleFactor + newX, newFrontImageSize.height - self.bigFaceFeature.leftEyePosition.y * scaleFactor + newY ,5 , 5);
        CGContextStrokeRect(context, rectangle);
        
        // right eye
        rectangle = CGRectMake(self.bigFaceFeature.rightEyePosition.x * scaleFactor + newX, newFrontImageSize.height - self.bigFaceFeature.rightEyePosition.y * scaleFactor + newY ,5 , 5);
        CGContextStrokeRect(context, rectangle);
        
        // mouth
        rectangle = CGRectMake(self.bigFaceFeature.mouthPosition.x * scaleFactor + newX, newFrontImageSize.height - self.bigFaceFeature.mouthPosition.y * scaleFactor + newY ,10 , 5);
        CGContextStrokeRect(context, rectangle);
        
    }
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if (newImage == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
