//
//  ViewController.h
//  Camera
//
//  Created by wayne on 2017/6/5.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CWCameraPreviewController;

@protocol CWCameraPreviewControllerDelegate <NSObject>

@optional
- (void)previewController:(CWCameraPreviewController *)previewController
              didScanCode:(NSString *)code
                   ofType:(NSString *)type;
@end

@interface CWCameraPreviewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *switchCamButton;
@property (weak, nonatomic) IBOutlet UIButton *snapButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleTorchButton;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet id <CWCameraPreviewControllerDelegate> delegate;
@end

