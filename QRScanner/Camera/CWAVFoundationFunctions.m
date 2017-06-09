//
//  CWAVFoundationFunctions.m
//  Camera
//
//  Created by wayne on 2017/6/9.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import "CWAVFoundationFunctions.h"

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

CGPathRef CWAVMetadataMachineReadableCodeObjectCreatePathForCorners(
                                                                    AVCaptureVideoPreviewLayer *previewLayer,
                                                                    AVMetadataMachineReadableCodeObject *barcodeObject) {
    AVMetadataMachineReadableCodeObject *transformedObject = (AVMetadataMachineReadableCodeObject *)[previewLayer transformedMetadataObjectForMetadataObject:barcodeObject];
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPoint point;
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)transformedObject.corners[0], &point);
    CGPathMoveToPoint(path, NULL, point.x, point.y);
    
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)transformedObject.corners[1], &point);
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)transformedObject.corners[2], &point);
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)transformedObject.corners[3], &point);
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    
    CGPathCloseSubpath(path);
    
    return path;
}
