//
//  OpenCameraOrPhoto.h
//  BaishitongClient
//
//  Created by 高磊 on 15/10/28.
//  Copyright © 2015年 高磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(__CLASSNAME__)    \
\
    + (__CLASSNAME__*) sharedInstance;    \


#define SYNTHESIZE_SINGLETON_FOR_CLASS(__CLASSNAME__)    \
\
    static __CLASSNAME__ *instance = nil;   \
\
    + (__CLASSNAME__ *)sharedInstance{ \
        static dispatch_once_t onceToken;   \
        dispatch_once(&onceToken, ^{    \
            if (nil == instance){   \
                instance = [[__CLASSNAME__ alloc] init];    \
            }   \
    }); \
\
    return instance;   \
}   \

typedef void(^OpenCameraOrPhotoBlock)(UIImage *image);

@interface OpenCameraOrPhoto : NSObject

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OpenCameraOrPhoto);

+ (void)showOpenCameraOrPhotoWithView:(UIView *)view withBlock:(OpenCameraOrPhotoBlock)openCameraOrPhotoBlock;

@property (nonatomic,copy) OpenCameraOrPhotoBlock openCameraOrPhotoBlock;

@end
