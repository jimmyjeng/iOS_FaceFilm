//
//  MovieMaker.m
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/9.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "Utillity.h"
#import "FaceFilm.h"
#import "MovieMaker.h"

@interface MovieMaker ()
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *bufferAdapter;
@property (nonatomic, assign) CMTime frameTime;
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput* writerInput;
@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSString* videoPath;
@property (nonatomic, strong) MovieMakerCompletion completionBlock;

@end

@implementation MovieMaker

-(instancetype)initWithImages{
    self = [self init];
    if (self) {
        NSError *error = nil;
        self.completionBlock = nil;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *tempPath = [documentsDirectory stringByAppendingFormat:@"/export.mp4"];
        self.videoPath = [tempPath copy];
        
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoPath]) {
            NSLog(@"file exist");
            [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:&error];
            if (error) {
                NSLog(@"Error: %@", error.debugDescription);
            }
            else {
                NSLog(@"remove success");
            }
        }
        
        //    1.Wire the writer
        self.videoWriter = [[AVAssetWriter alloc] initWithURL:
                                      [NSURL fileURLWithPath:self.videoPath] fileType:AVFileTypeMPEG4
                                                                  error:&error];
        NSParameterAssert(self.videoWriter);
        
        NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:1024*1024], AVVideoAverageBitRateKey,
                                       nil];
        
        float width = 800;
        float height = 450;
        self.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSNumber numberWithInt:width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:height], AVVideoHeightKey,
                                       codecSettings,AVVideoCompressionPropertiesKey,
                                       nil];
        self.writerInput = [AVAssetWriterInput
                                           assetWriterInputWithMediaType:AVMediaTypeVideo
                                           outputSettings:self.videoSettings];
        
        NSParameterAssert(self.writerInput);
        NSParameterAssert([self.videoWriter canAddInput:self.writerInput]);
        [self.videoWriter addInput:self.writerInput];
        
        
        NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
        
        self.bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:bufferAttributes];
        
        int frame = 10;
        // value , scale
        self.frameTime = CMTimeMake(1, frame);
        
    }
    return self;

}



-(void)createMovieFromImages:(NSArray *)images withCompletion:(MovieMakerCompletion)completion{
    NSDate *start = [NSDate date];

    self.completionBlock = completion;

    FaceFilm *face = [[FaceFilm alloc]initWithImageArray:images];

    //      2.start session
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    //    3.Write some samples:
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    NSInteger frameNumber = [images count] * 10;
    __block int i = 0;
    [self.writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        while (YES){
            @autoreleasepool {
                if (i >= frameNumber) {
                    break;
                }
                if ([self.writerInput isReadyForMoreMediaData]) {
                    UIImage *image = [face getImageByFrameIndex:i];
                    CVPixelBufferRef sampleBuffer = [self newPixelBufferFromCGImage:[image CGImage]];
                    if (sampleBuffer) {
                        if (i == 0) {
                            [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                        } else {
                            CMTime lastTime = CMTimeMake(i - 1, self.frameTime.timescale);
                            CMTime presentTime = CMTimeAdd(lastTime, self.frameTime);
                            [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:presentTime];
                        }
                        CFRelease(sampleBuffer);
                        i++;
                    }
                }
            }
        }
        
        [self.writerInput markAsFinished];
        [self.videoWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL success = self.videoWriter.status == AVAssetWriterStatusCompleted;
                if (success) {
                    NSLog(@"record finish");
                    NSLog(@"video takes : %f" , [[NSDate date] timeIntervalSinceDate:start]);
                    [self CompileFilesToMakeMovie:[images count]];
                }
                else {
                    NSLog(@"record error : %@",self.videoWriter.error);
                }
                
            });
        }];
        
        CVPixelBufferPoolRelease(self.bufferAdapter.pixelBufferPool);
    }];
}

- (CVPixelBufferRef) newPixelBufferFromCGImage:(CGImageRef) image {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);

    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 4*frameWidth,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           CGImageGetWidth(image),
                                           CGImageGetHeight(image)),
                       image);

    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)writeToSavedPhotosAlbum:(NSURL *)url {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:url]) {
        [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"Error writing image with metadata to Photo Library: %@", error);
                if (self.completionBlock) {
                    self.completionBlock(NO);
                }
            }
            NSLog(@"save success");
            if (self.completionBlock) {
                self.completionBlock(YES);
            }
            self.completionBlock = nil;
            
        }];
    } else {
        NSLog(@"can't find video");
        if (self.completionBlock) {
            self.completionBlock(NO);
        }
        self.completionBlock = nil;

    }
    
}

-(void)CompileFilesToMakeMovie:(NSInteger)seconds {
    NSDate *start = [NSDate date];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    NSURL *audio_inputFileUrl = [[NSBundle mainBundle]
                      URLForResource:@"bgMusic" withExtension:@"mp4"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    NSString *video_inputFilePath = [documentsDirectory stringByAppendingFormat:@"/export.mp4"];
    NSURL* video_inputFileUrl = [NSURL fileURLWithPath:video_inputFilePath];
    
    NSString *outputFilePath = [documentsDirectory stringByAppendingFormat:@"/outputFile.mp4"];
    NSURL* outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    
    
    CMTime nextClipStartTime = kCMTimeZero;
    
    CMTime duration = CMTimeMake(seconds, 1);
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_inputFileUrl options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,duration);
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    //nextClipStartTime = CMTimeAdd(nextClipStartTime, a_timeRange.duration);
    
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    
    
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = AVFileTypeMPEG4;
    _assetExport.outputURL = outputFileUrl;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         [self writeToSavedPhotosAlbum:outputFileUrl];
         NSLog(@"audio takes : %f",[[NSDate date]timeIntervalSinceDate:start]);
     }
     ];
}
@end
