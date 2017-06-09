//
//  ViewController.m
//  Camera
//
//  Created by wayne on 2017/6/5.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import "CWCameraPreviewController.h"
#import "CWVideoPreviewView.h"
#import "CWAVFoundationFunctions.h"

@interface CWCameraPreviewController () <AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate>

@end

@implementation CWCameraPreviewController {
    AVCaptureDevice         *_camera;
    AVCaptureDeviceInput    *_videoInput;
    AVCapturePhotoOutput    *_imageOutput;
    AVCaptureSession        *_captureSession;
    CWVideoPreviewView      *_videoPreview;
    AVCaptureMetadataOutput *_metaDataOutput;
    dispatch_queue_t        _metaDataQueue;
    NSMutableSet            *_visibleCodes;
    NSMutableDictionary     *_visibleShapes;
    
    __weak IBOutlet UIImageView *_iBox;
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
    
    [self _setupCameraAfterCheckingAuthorization];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tap];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(subjectChanged:)
                   name:AVCaptureDeviceSubjectAreaDidChangeNotification
                 object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // need to update capture and preview connections
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    [self _updateConnectionsForInterfaceOrientation:orientation];
    
    [_captureSession startRunning];
    
    [self _setupCamSwitchButton];
    [self _setupTorchToggleButton];
    
    _visibleCodes = [NSMutableSet new];
    _visibleShapes = [NSMutableDictionary new];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_captureSession stopRunning];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self _updateMetadataRectOfInterest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - button action and setups
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

- (IBAction)previewDone:(id)sender {
    self.preview.alpha = 0;
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
- (void)_setupTorchToggleButton {
    if ([_camera hasTorch]) {
        self.toggleTorchButton.hidden = NO;
    } else {
        self.toggleTorchButton.hidden = YES;
    }
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
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
    if (error) {
        NSLog(@"error : %@", error.localizedDescription);
    }
    
    if (photoSampleBuffer) {
        NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        UIImage *image = [UIImage imageWithData:data];
        self.previewImage.image = image;
        self.preview.alpha = 1.0;
//        UIViewController *previewVC = [[UIViewController alloc] init];
//        UIImageView *previewImage = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//        previewImage.image = image;
//        [previewVC.view addSubview:previewImage];
//        [self.navigationController pushViewController:previewVC animated:YES];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
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
    
    [self _setupMetadataOutput];
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

#pragma mark - autoFocus
- (void)subjectChanged:(NSNotification *)notification {
    if (_camera.focusMode == AVCaptureFocusModeLocked) {
        if ([_camera isFocusPointOfInterestSupported]) {
            _camera.focusPointOfInterest = CGPointMake(0.5, 0.5);
        }
        
        if ([_camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [_camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        NSLog(@"Focus Mode: Continuous");
    }
}
- (void)handleTap:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (![_camera isFocusPointOfInterestSupported] || ![_camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSLog(@"Focus Point Not Supported by current camera");
            return;
        }
    }
    
    CGPoint locationInPreview = [gesture locationInView:_videoPreview];
    CGPoint locationInCapture = [_videoPreview.previewLayer captureDevicePointOfInterestForPoint:locationInPreview];
    
    if ([_camera lockForConfiguration:nil]) {
        [_camera setFocusPointOfInterest:locationInCapture];
        [_camera setFocusMode:AVCaptureFocusModeAutoFocus];
        
        NSLog(@"Focus Mode: Locked to Focus Point");
        
        [_camera unlockForConfiguration];
    }
}

#pragma mark - metadata output
//create a barcode scanner and configure it to look for specific types of barcodes.
- (void)_setupMetadataOutput {
    _metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    _metaDataQueue = dispatch_get_main_queue();
    [_metaDataOutput setMetadataObjectsDelegate:self queue:_metaDataQueue];
    
    //Connect metadata output
    if (![_captureSession canAddOutput:_metaDataOutput]) {
        NSLog(@"Unable to add metadata output to capture session");
        return;
    }
    
    [_captureSession addOutput:_metaDataOutput];
    
    NSArray *barcodes2D = @[AVMetadataObjectTypePDF417Code,
                            AVMetadataObjectTypeQRCode,
                            AVMetadataObjectTypeAztecCode];
    NSArray *availableTypes = [_metaDataOutput availableMetadataObjectTypes];
    
    if (![availableTypes count]) {
        NSLog(@"Unable to get any available metadata types,"\
              @"did you forget the addOutput: on the capture session?");
        return;
    }
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    for (NSString *oneCodeType in barcodes2D) {
        if ([availableTypes containsObject:oneCodeType]) {
            [tmpArray addObject:oneCodeType];
        } else {
            NSLog(@"Weird: Code type '%@' is not reported as supported "\
                  @"on this device", oneCodeType);
        }
    }
    
    if ([tmpArray count]) {
        _metaDataOutput.metadataObjectTypes = tmpArray;
    }
    
    _metaDataOutput.rectOfInterest = CGRectMake(0, 0, 1, 1);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
//    for (AVMetadataObject *obj in metadataObjects) {
//        if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
//            AVMetadataMachineReadableCodeObject *barcode = (AVMetadataMachineReadableCodeObject *)obj;
//            
//            NSLog(@"Seeing type '%@' with contents '%@'", barcode.type, barcode.stringValue);
//        } else if ([obj isKindOfClass:[AVMetadataFaceObject class]]) {
//            NSLog(@"Face detection make not implemented");
//        }
//    }
    NSMutableSet *reportedCodes = [NSMutableSet set];
    NSMutableDictionary *repCount = [NSMutableDictionary dictionary];
    
    for (AVMetadataMachineReadableCodeObject *obj in metadataObjects) {
        if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]] && obj.stringValue) {
            NSString *code = [NSString stringWithFormat:@"%@:%@", obj.type, obj.stringValue];
            
            NSUInteger occurencesOfCode = [repCount[code] unsignedIntegerValue] + 1;
            repCount[code] = @(occurencesOfCode);
            NSString *numberedCode = [code stringByAppendingFormat:@"-%lu", (unsigned long)occurencesOfCode];
            
            if (![_visibleCodes containsObject:numberedCode]) {
                NSLog(@"code appeared: %@", numberedCode);
                
                if ([_delegate respondsToSelector:@selector(previewController:didScanCode:ofType:)]) {
                    [_delegate previewController:self didScanCode:obj.stringValue ofType:obj.type];
                }
            }
            
            [reportedCodes addObject:numberedCode];
            
            //Marking detected barcodes on preview
            CGPathRef path = CWAVMetadataMachineReadableCodeObjectCreatePathForCorners(_videoPreview.previewLayer, obj);
            
            CAShapeLayer *shapeLayer = _visibleShapes[numberedCode];
            
            if (!shapeLayer) {
                shapeLayer = [CAShapeLayer layer];
                shapeLayer.strokeColor = [UIColor greenColor].CGColor;
                shapeLayer.fillColor   = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.25].CGColor;
                
                shapeLayer.lineWidth = 2;
                
                [_videoPreview.layer addSublayer:shapeLayer];
                _visibleShapes[numberedCode] = shapeLayer;
            }
            
            shapeLayer.frame = _videoPreview.bounds;
            shapeLayer.path  = path;
            
            CGPathRelease(path);
        } else if ([obj isKindOfClass:[AVMetadataFaceObject class]]) {
            NSLog(@"Face detection marking not implemented");
        }
    }
    
    NSLog(@"visibleCodes:%@, reportedCodes:%@", _visibleCodes, reportedCodes);
    for (NSString *oneCode in _visibleCodes) {
        if (![reportedCodes containsObject:oneCode]) {
            NSLog(@"code disappeared: %@", oneCode);
            
            CAShapeLayer *shape = _visibleShapes[oneCode];
            [shape removeFromSuperlayer];
            [_visibleShapes removeObjectForKey:oneCode];
        }
    }
    
    _visibleCodes = reportedCodes;
}
- (void)_updateMetadataRectOfInterest {
    if (!_captureSession.isRunning) {
        NSLog(@"Capture Session is not running yet,"\
              @"so we wouldn't get a useful rect of interest");
        return;
    }
    
    CGRect rectOfInterest = [_videoPreview.previewLayer metadataOutputRectOfInterestForRect:_iBox.frame];
    _metaDataOutput.rectOfInterest = rectOfInterest;
}
#pragma mark - alert
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

- (void)_configureCurrentCamera {
    if ([_camera isFocusModeSupported:AVCaptureFocusModeLocked]) {
        if ([_camera lockForConfiguration:nil]) {
            _camera.subjectAreaChangeMonitoringEnabled = YES;
            
            [_camera unlockForConfiguration];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
