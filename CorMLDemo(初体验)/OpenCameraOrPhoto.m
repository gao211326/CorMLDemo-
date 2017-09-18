//
//  OpenCameraOrPhoto.m
//  BaishitongClient
//
//  Created by 高磊 on 15/10/28.
//  Copyright © 2015年 高磊. All rights reserved.
//

#import "OpenCameraOrPhoto.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>


@interface OpenCameraOrPhoto()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    UIView *    superView;
}

@property (nonatomic,strong) UIAlertController *actionSheet;

@end

@implementation OpenCameraOrPhoto


SYNTHESIZE_SINGLETON_FOR_CLASS(OpenCameraOrPhoto)

- (id)init
{
    self = [super init];
    if (self)
    {
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        
        __weak typeof(self)weakSelf = self;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear])
        {
            [self addActionTarget:actionSheet title:NSLocalizedString(@"拍照", nil) color:[UIColor redColor]  action:^(UIAlertAction *action) {
                [weakSelf takePhoto];
            }];
        }
        
        [self addActionTarget:actionSheet title:NSLocalizedString(@"选择本地照片", nil) color:[UIColor redColor]  action:^(UIAlertAction *action) {
            [weakSelf choosePhoto];
        }];
        
        [self addCancelActionTarget:actionSheet title:@"取消"];
        
        self.actionSheet = actionSheet;
    }
    return self;
}


+ (void)showOpenCameraOrPhotoWithView:(UIView *)view withBlock:(OpenCameraOrPhotoBlock)openCameraOrPhotoBlock
{
    [[OpenCameraOrPhoto sharedInstance] showOpenCameraOrPhotoWithView:view withBlock:openCameraOrPhotoBlock];
}



#pragma mark == private method
- (void)choosePhoto
{
    // 从相册中选取
    if ([self isPhotoLibraryAvailable]) {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
        [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
        controller.mediaTypes = mediaTypes;
        controller.delegate = self;
        [self.glViewController presentViewController:controller
                                            animated:YES
                                          completion:^(void){
                                              NSLog(@"Picker View Controller is presented");
                                          }];
    }
}

- (void)takePhoto
{
    if (self.isCamer)
    {
        // 拍照
        if ([self isCameraAvailable] && [self doesCameraSupportTakingPhotos]) {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            if ([self isRearCameraAvailable]) {
                controller.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            }
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = (id)self;
            [self.glViewController presentViewController:controller
                                                animated:YES
                                              completion:^(void){
                                                  NSLog(@"Picker View Controller is presented");
                                              }];
        }
    }
    else
    {
        NSLog(@" 打印信息:您尚未为智能消防管理需打开”相机服务“，开启方法为“手机设置-隐私-相机服务-智能消防管理”进行[开启]");
    }
}

- (void)showOpenCameraOrPhotoWithView:(UIView *)view withBlock:(OpenCameraOrPhotoBlock)openCameraOrPhotoBlock
{
    superView = view;
    self.openCameraOrPhotoBlock = openCameraOrPhotoBlock;
    [[self glViewController] presentViewController:self.actionSheet animated:YES completion:nil];
}

// 取消按钮
-(void)addCancelActionTarget:(UIAlertController*)alertController title:(NSString *)title
{
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.3))
    {
        [action setValue:[UIColor blackColor] forKey:@"_titleTextColor"];
    }
    else
    {
        alertController.view.tintColor = [UIColor grayColor];
    }
    
    [alertController addAction:action];
}

- (void)addActionTarget:(UIAlertController *)alertController title:(NSString *)title color:(UIColor *)color action:(void(^)(UIAlertAction *action))actionTarget
{
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        actionTarget(action);
    }];
    
    if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.3))
    {
        [action setValue:color forKey:@"_titleTextColor"];
    }
    else
    {
        alertController.view.tintColor = [UIColor redColor];
    }
    
    [alertController addAction:action];
}

- (UIViewController *)glViewController {
    UIResponder *nextResponder = superView;
    do
    {
        nextResponder = [nextResponder nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
            return (UIViewController*)nextResponder;
        
    } while (nextResponder != nil);
    
    return nil;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^() {
        
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

        if (weakSelf.openCameraOrPhotoBlock)
        {
            weakSelf.openCameraOrPhotoBlock(portraitImg);
        }
    }];
}

#pragma mark camera utility
- (BOOL)isCamer
{
    BOOL camer = NO;
    
    __block BOOL blockCamer = camer;
    
    if(([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0)){
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(authStatus == AVAuthorizationStatusAuthorized){
            camer=YES;
        }else if(authStatus==AVAuthorizationStatusNotDetermined){
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
             {
                 blockCamer = granted;
                 
             }];
        }else{
            camer = NO;
        }
    }
    else{
        camer = YES;
    }
    return camer;
}

- (BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL) isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL) doesCameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage
                          sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}
- (BOOL) canUserPickVideosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeMovie
            sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}
- (BOOL) canUserPickPhotosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeImage
            sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL) cameraSupportsMedia:(NSString *)paramMediaType
                  sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        return NO;
    }
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }
    }];
    return result;
}

#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
}
@end
