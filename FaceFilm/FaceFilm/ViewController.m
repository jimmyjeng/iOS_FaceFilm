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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.times = 0;
    self.alpha = 0;
    self.imageArray = [[NSMutableArray alloc]init];

}

-(void)viewDidAppear:(BOOL)animated {
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
    
    if (self.times >= 50) {
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
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
}

// alpha
- (UIImage *)imageWithImage:(UIImage*)image alpha:(CGFloat) alpha {
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    
    CGContextSetAlpha(context, alpha);
    
    CGContextDrawImage(context, rect, image.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

// border
- (UIImage*)imageWithBorderFromImage:(UIImage*)image;
{
    UIGraphicsBeginImageContext(image.size);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    [image drawInRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 10.0);
    CGContextStrokeRect(context, rect);
    UIImage *newImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)imageFromView:(UIView *)view {
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}

- (UIImage *)imageWithBackgroundImage:(UIImage *)backgroundImage frontImage:(UIImage *)frontImage{
    UIImage *imageTarget = nil;
    
    UIGraphicsBeginImageContextWithOptions(backgroundImage.size, NO, 0.0);
    CGRect rect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
    [backgroundImage drawInRect:rect];

    CGRect rectDstDraw = CGRectMake(backgroundImage.size.width/2 - frontImage.size.width/2, backgroundImage.size.height/2 - frontImage.size.height/2, frontImage.size.width, frontImage.size.height);
    
    [frontImage drawInRect:rectDstDraw];
    imageTarget = UIGraphicsGetImageFromCurrentImageContext();

    if (imageTarget == nil) {
        NSLog(@"could not get imageTarget");
    }
    UIGraphicsEndImageContext();

    return imageTarget;
}

- (UIImage *)blackImage:(UIView *)view {
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [[UIColor blackColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, view.bounds.size.width, view.bounds.size.height));
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}
@end
