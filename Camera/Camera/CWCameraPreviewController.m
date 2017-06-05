//
//  ViewController.m
//  Camera
//
//  Created by wayne on 2017/6/5.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import "CWCameraPreviewController.h"

@interface CWCameraPreviewController ()

@end

@implementation CWCameraPreviewController {
    AVCaptureDevice *_camera;
    AVCaptureDeviceInput *_videoInput;
    AVCapturePhotoOutput *_imageOutput;
    AVCaptureSession *_captureSession;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)switchCam:(id)sender {
    NSLog(@"switch Camera");
}

- (IBAction)snap:(id)sender {
    NSLog(@"snap!");
}

- (IBAction)toggleTorch:(id)sender {
    NSLog(@"torch");
}


@end
