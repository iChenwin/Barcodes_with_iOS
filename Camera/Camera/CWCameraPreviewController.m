//
//  ViewController.m
//  Camera
//
//  Created by wayne on 2017/6/5.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import "CWCameraPreviewController.h"
#import "CWVideoPreviewView.h"

@interface CWCameraPreviewController () <AVCapturePhotoCaptureDelegate>

@end

@implementation CWCameraPreviewController {
    AVCaptureDevice *_camera;
    AVCaptureDeviceInput *_videoInput;
    AVCapturePhotoOutput *_imageOutput;
    AVCaptureSession *_captureSession;
    CWVideoPreviewView *_videoPreview;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSAssert([self.view isKindOfClass:[CWVideoPreviewView class]],
             @"Wrong root view class %@ in %@",
             NSStringFromClass([self.view class]),
             NSStringFromClass([self class]));
    
    _videoPreview = (CWVideoPreviewView *)self.view;
    [self _setupCamera];
    _videoPreview.previewLayer.session = _captureSession;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_captureSession stopRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)switchCam:(id)sender {
    [_captureSession beginConfiguration];
    
    _camera = [self _alternativeCamToCurrent];
    
//    [self _configureCurrentCamera];
    
    for (AVCaptureDeviceInput *input in _captureSession.inputs) {
        [_captureSession removeInput:input];
    }
    
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_camera error:nil];
    
    [_captureSession addInput:_videoInput];
    
    [self _updateConnectionsForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
    
    [_captureSession commitConfiguration];
    
    [self _setupCamSwitchButton];
    [self _setupTorchToggleButton];
}

- (IBAction)snap:(id)sender {
    if (!_camera) {
        return;
    }
    
//    AVCaptureConnection *videoConnection = [self _captureConnection];
//    
//    if (!videoConnection) {
//        NSLog(@"Error:No Video connection found on still image output");
//    }
    
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
    NSDictionary *previewDict = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:[photoSettings.availablePreviewPhotoPixelFormatTypes firstObject], (NSString *)kCVPixelBufferWidthKey:@"90", (NSString *)kCVPixelBufferHeightKey:@"160"};
    photoSettings.previewPhotoFormat = previewDict;
    [_imageOutput capturePhotoWithSettings:photoSettings delegate:self];
    
}

- (void)_setupCamSwitchButton {
    AVCaptureDevice *alternativeCam = [self _alternativeCamToCurrent];
    
    if (alternativeCam) {
        self.switchCamButton.hidden = NO;
        
        NSString *title;
        
        switch (alternativeCam.position) {
            case AVCaptureDevicePositionBack:
                title = @"Back";
                break;
            case AVCaptureDevicePositionFront:
                title = @"Front";
                break;
            case AVCaptureDevicePositionUnspecified:
                title = @"Other";
                break;
        }
        
        [self.switchCamButton setTitle:title forState:UIControlStateNormal];
    } else {
        self.switchCamButton.hidden = YES;
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
    if (error) {
        NSLog(@"error : %@", error.localizedDescription);
    }
    
    if (photoSampleBuffer) {
        NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        UIImage *image = [UIImage imageWithData:data];
        self.previewImage.image = image;
        self.previewImage.hidden = NO;
//        UIViewController *previewVC = [[UIViewController alloc] init];
//        UIImageView *previewImage = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//        previewImage.image = image;
//        [previewVC.view addSubview:previewImage];
//        [self.navigationController pushViewController:previewVC animated:YES];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}

- (IBAction)toggleTorch:(id)sender {
    if ([_camera hasTorch]) {
        BOOL torchActive = [_camera isTorchActive];
        
        if ([_camera lockForConfiguration:nil]) {
            if (torchActive) {
                if ([_camera isTorchModeSupported:AVCaptureTorchModeOff]) {
                    [_camera setTorchMode:AVCaptureTorchModeOff];
                }
            } else {
                if ([_camera isTorchModeSupported:AVCaptureTorchModeOn]) {
                    [_camera setTorchMode:AVCaptureTorchModeOn];
                }
            }
            
            [_camera unlockForConfiguration];
        }
    }
}

- (void)_setupTorchToggleButton {
    if ([_camera hasTorch]) {
        self.toggleTorchButton.hidden = NO;
    } else {
        self.toggleTorchButton.hidden = YES;
    }
}

- (void)_setupCamera {
    _camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (!_camera) {
        [self.snapButton setTitle:@"No Camera Found" forState:UIControlStateNormal];
        self.snapButton.enabled = NO;
        [self _informUserAboutNoCam];
        return;
    }
    
    NSError *error;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:&error];
    
    if(!_videoInput) {
        NSLog(@"error connectiong video input: %@", [error localizedDescription]);
        return;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    if (![_captureSession canAddInput:_videoInput]) {
        NSLog(@"Unable to add video input to capture session");
        return;
    }
    [_captureSession addInput:_videoInput];
    
//    [self _configureCurrentCamera];
    _imageOutput = [AVCapturePhotoOutput new];
    
    if (![_captureSession canAddOutput:_imageOutput]) {
        NSLog(@"Unable to add still image output to capture session");
        return;
    }
    
    [_captureSession addOutput:_imageOutput];
    
    _videoPreview.previewLayer.session = _captureSession;
}

- (AVCaptureDevice *)_alternativeCamToCurrent {
    if (!_camera) {
        return nil;
    }
    
    NSArray *allCams = [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInTelephotoCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified] devices];//[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *oneCam in allCams) {
        if (oneCam != _camera) {
            return oneCam;
        }
    }
    
    return nil;
}

- (AVCaptureConnection *)_captureConnection {
    for (AVCaptureConnection *connection in _imageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([port.mediaType isEqualToString:AVMediaTypeVideo]) {
                return connection;
            }
        }
    }
    return nil;
}

- (void)_setupCameraAfterCheckingAuthorization {
    //For iOS6, assume authorization
    if (![[AVCaptureDevice class] respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
        [self _setupCamera];
        
        return;
    }
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (authStatus) {
        case AVAuthorizationStatusAuthorized: {
            [self _setupCamera];
            break;
        }
            
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [self _setupCamera];
                        
                        [_captureSession startRunning];
                    } else {
                        [self _informUserAboutCanNotAuthorized];
                    }
                });
            }];
            break;
        }
            
        default:
            break;
    }
}

- (void)_informUserAboutCanNotAuthorized {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"未获取相机权限" message:@"请允许相继访问" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)_informUserAboutNoCam {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"未发现相机" message:@"无相机" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)_updateConnectionsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    AVCaptureVideoOrientation captureOrientation = CWAVCaptureVideoOrientationForUIInterfaceOrientation(interfaceOrientation);
    
    for (AVCaptureConnection *connection in _imageOutput.connections) {
        if ([connection isVideoOrientationSupported]) {
            connection.videoOrientation = captureOrientation;
        }
    }
    
    if ([_videoPreview.previewLayer.connection isVideoOrientationSupported]) {
        _videoPreview.previewLayer.connection.videoOrientation = captureOrientation;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self _updateConnectionsForInterfaceOrientation:toInterfaceOrientation];
    
}

AVCaptureVideoOrientation CWAVCaptureVideoOrientationForUIInterfaceOrientation(UIInterfaceOrientation interfaceOrientation) {
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            
        default:
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;

        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
    }
}
@end
