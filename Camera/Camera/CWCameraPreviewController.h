//
//  ViewController.h
//  Camera
//
//  Created by wayne on 2017/6/5.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CWCameraPreviewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *switchCamButton;
@property (weak, nonatomic) IBOutlet UIButton *snapButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleTorchButton;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;

@end

