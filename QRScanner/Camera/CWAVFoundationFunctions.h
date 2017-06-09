//
//  CWAVFoundationFunctions.h
//  Camera
//
//  Created by wayne on 2017/6/9.
//  Copyright © 2017年 wayne. All rights reserved.
//

#ifndef CWAVFoundationFunctions_h
#define CWAVFoundationFunctions_h

AVCaptureVideoOrientation CWAVCaptureVideoOrientationForUIInterfaceOrientation(UIInterfaceOrientation interfaceOrientation);

CGPathRef CWAVMetadataMachineReadableCodeObjectCreatePathForCorners(
                                                                    AVCaptureVideoPreviewLayer *previewLayer,
                                                                    AVMetadataMachineReadableCodeObject *barcodeObject);

#endif /* CWAVFoundationFunctions_h */
