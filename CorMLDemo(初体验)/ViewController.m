//
//  ViewController.m
//  CoreMLDemo(初体验)
//
//  Created by 高磊 on 2017/9/14.
//  Copyright © 2017年 高磊. All rights reserved.
//

#import "ViewController.h"
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "Resnet50.h"
//#import "Inceptionv3.h"
//#import "GoogLeNetPlaces.h"
//#import "VGG16.h"
#import "OpenCameraOrPhoto.h"

@interface ViewController ()

@property (nonatomic,strong) UIImageView *imageView;

@property (nonatomic,strong) UILabel *descriptionLable;

@property (nonatomic,assign) NSInteger number;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.number = 0;
    
    UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, 400)];
    imageview.image = [UIImage imageNamed:@"jnt.png"];
    
    UILabel *lable = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imageview.frame), self.view.frame.size.width, 80)];
    lable.numberOfLines = 0;
    lable.textColor = [UIColor redColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(100, CGRectGetMaxY(lable.frame) + 20, 100, 60);
    [btn setTitle:@"选择照片" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(turn:) forControlEvents:UIControlEventTouchUpInside];
   
    [self.view addSubview:imageview];
    [self.view addSubview:lable];
    [self.view addSubview:btn];
    
    self.imageView = imageview;
    self.descriptionLable = lable;
    
    //此处屏蔽部分为识别第一张图片
//    UIImage *scaledImage = [self scaleToSize:CGSizeMake(224, 224) image:imageview.image];
//    CGImageRef cgImageRef = [scaledImage CGImage];
//    lable.text = [self predictionWithResnet50:[self pixelBufferFromCGImage:cgImageRef]];
    
    
    [self predictionWithResnet50WithImage:[[CIImage alloc]initWithImage:imageview.image]];
}

//图片缩放到固定尺寸
- (UIImage *)scaleToSize:(CGSize)size image:(UIImage *)image {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

//将图片转化为CVPixelBufferRef格式
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
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
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


#pragma mark == 切换不同的模型

- (void)predictionWithResnet50WithImage:(CIImage * )image
{
    //两种初始化方法均可
//    Resnet50* resnet50 = [[Resnet50 alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Resnet50" ofType:@"mlmodelc"]] error:nil];
    
    Resnet50* resnet50 = [[Resnet50 alloc] init];
    NSError *error = nil;
    //创建VNCoreMLModel
    VNCoreMLModel *vnCoreMMModel = [VNCoreMLModel modelForMLModel:resnet50.model error:&error];
    
    // 创建处理requestHandler
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:image options:@{}];
    
    NSLog(@" 打印信息:%@",handler);
    // 创建request
    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:vnCoreMMModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {

        CGFloat confidence = 0.0f;
        
        VNClassificationObservation *tempClassification = nil;
        
        for (VNClassificationObservation *classification in request.results) {
            if (classification.confidence > confidence) {
                confidence = classification.confidence;
                tempClassification = classification;
            }
        }
        self.descriptionLable.text = [NSString stringWithFormat:@"识别结果:%@,匹配率:%.2f",tempClassification.identifier,tempClassification.confidence];
    }];
    
    // 发送识别请求
    [handler performRequests:@[request] error:&error];
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}

//224
- (NSString*)predictionWithResnet50:(CVPixelBufferRef )buffer
{
    Resnet50* resnet50 = [[Resnet50 alloc] init];
    
    NSError *predictionError = nil;
    Resnet50Output *resnet50Output = [resnet50 predictionFromImage:buffer error:&predictionError];
    if (predictionError) {
        return predictionError.description;
    } else {
        return [NSString stringWithFormat:@"识别结果:%@,匹配率:%.2f",resnet50Output.classLabel, [[resnet50Output.classLabelProbs valueForKey:resnet50Output.classLabel]floatValue]];
    }
}

//屏蔽部分说明 由于GitHub上传文件太大限制 故删除了部分model 需要的可以直接去官网下载
//299
//- (NSString*)predictionWithInceptionv3:(CVPixelBufferRef )buffer
//{
//    Inceptionv3* inceptionv3 = [[Inceptionv3 alloc] init];
//
//    NSError *predictionError = nil;
//    Inceptionv3Output *inceptionv3Output = [inceptionv3 predictionFromImage:buffer error:&predictionError];
//    if (predictionError) {
//        return predictionError.description;
//    } else {
//        return [NSString stringWithFormat:@"识别结果:%@,匹配率:%.2f",inceptionv3Output.classLabel, [[inceptionv3Output.classLabelProbs valueForKey:inceptionv3Output.classLabel]floatValue]];
//    }
//}

//224
//- (NSString*)predictionWithGoogLeNetPlaces:(CVPixelBufferRef )buffer
//{
//    GoogLeNetPlaces* googleNetplaces = [[GoogLeNetPlaces alloc] init];
//
//    NSError *predictionError = nil;
//
//    GoogLeNetPlacesOutput *googleNetplacesOutput = [googleNetplaces predictionFromFeatures:[[GoogLeNetPlacesInput alloc] initWithSceneImage:buffer] error:&predictionError];
//    if (predictionError) {
//        return predictionError.description;
//    } else {
//        return [NSString stringWithFormat:@"识别结果:%@,匹配率:%.2f",googleNetplacesOutput.sceneLabel, [[googleNetplacesOutput.sceneLabelProbs valueForKey:googleNetplacesOutput.sceneLabel]floatValue]];
//    }
//}

//224
//- (NSString*)predictionWithVGG16:(CVPixelBufferRef )buffer
//{
//    VGG16* vcg16 = [[VGG16 alloc] init];
//
//    NSError *predictionError = nil;
//    VGG16Output *vgc16Output = [vcg16 predictionFromImage:buffer error:&predictionError];
//    if (predictionError) {
//        return predictionError.description;
//    } else {
//        return [NSString stringWithFormat:@"识别结果:%@,匹配率:%.2f",vgc16Output.classLabel, [[vgc16Output.classLabelProbs valueForKey:vgc16Output.classLabel]floatValue]];
//    }
//}


#pragma mark == event response
- (void)turn:(UIButton *)sender
{
    __weak typeof(self)weakSelf = self;
    [OpenCameraOrPhoto showOpenCameraOrPhotoWithView:self.view withBlock:^(UIImage *image) {
        weakSelf.imageView.image = image;
        [weakSelf predictionWithResnet50WithImage:[[CIImage alloc]initWithImage:self.imageView.image]];
    }];
    
    //下面屏蔽部分为本地图片的识别
    /*
    self.number ++;

    switch (self.number) {
        case 0:
        {
            self.imageView.image = [UIImage imageNamed:@"jnt.png"];
        }
            break;
        case 1:
        {
            self.imageView.image = [UIImage imageNamed:@"timg.jpeg"];
        }
            break;
        case 2:
        {
            self.imageView.image = [UIImage imageNamed:@"rose.jpeg"];
        }
            break;
        case 3:
        {
            self.imageView.image = [UIImage imageNamed:@"air.jpeg"];
        }
            break;
        case 4:
        {
            self.imageView.image = [UIImage imageNamed:@"百合.jpeg"];
        }
            break;
        default:
            break;
    }

    UIImage *scaledImage = [self scaleToSize:CGSizeMake(224, 224) image:self.imageView.image];
    CGImageRef cgImageRef = [scaledImage CGImage];
    self.descriptionLable.text = [self predictionWithResnet50:[self pixelBufferFromCGImage:cgImageRef]];

    if (self.number == 4) {
        self.number = -1;
    }
     */
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
