//
//  MovieMaker.h
//  FaceFilm
//
//  Created by JimmyJeng on 2015/9/9.
//  Copyright (c) 2015年 JimmyJeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MovieMaker : NSObject
typedef void(^MovieMakerCompletion)(BOOL succeed);

-(instancetype)initWithImages;
-(void)createMovieFromImages:(NSArray *)images withCompletion:(MovieMakerCompletion)completion;
//- (void)createMovie:(int)photoNum withCompletion:(MovieMakerCompletion)completion;

@end
