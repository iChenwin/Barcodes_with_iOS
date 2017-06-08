//
//  CWVideoPreviewView.m
//  Camera
//
//  Created by wayne on 2017/6/6.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import "CWVideoPreviewView.h"

@implementation CWVideoPreviewView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _commonSetup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self _commonSetup];
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (void)_commonSetup {
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor blackColor];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}
@end
