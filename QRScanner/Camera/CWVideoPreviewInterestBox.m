//
//  CWVideoPreviewInterestBox.m
//  Camera
//
//  Created by wayne on 2017/6/9.
//  Copyright © 2017年 wayne. All rights reserved.
//

#import "CWVideoPreviewInterestBox.h"

#define EDGE_LENGTH 10.0

@implementation CWVideoPreviewInterestBox

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [[UIColor redColor] setStroke];
    
    CGFloat lineWidth = 3;
    CGRect  box = CGRectInset(self.bounds, lineWidth/2.0, lineWidth/2.0);
    
    CGContextSetLineWidth(ctx, lineWidth);
    
    CGFloat minX = CGRectGetMinX(box);
    CGFloat minY = CGRectGetMinY(box);
    
    CGFloat maxX = CGRectGetMaxX(box);
    CGFloat maxY = CGRectGetMaxY(box);
    
    //Top-left corner
    CGContextMoveToPoint(ctx, minX, minY + EDGE_LENGTH);
    CGContextAddLineToPoint(ctx, minX, minY);
    CGContextAddLineToPoint(ctx, minX + EDGE_LENGTH, minY);
    
    //Bottom-left corner
    CGContextMoveToPoint(ctx, minX, maxY - EDGE_LENGTH);
    CGContextAddLineToPoint(ctx, minX, maxY);
    CGContextAddLineToPoint(ctx, minX + EDGE_LENGTH, maxY);
    
    //Top-right corner
    CGContextMoveToPoint(ctx, maxX - EDGE_LENGTH, minY);
    CGContextAddLineToPoint(ctx, maxX, minY);
    CGContextAddLineToPoint(ctx, maxX, minY + EDGE_LENGTH);
    
    CGContextMoveToPoint(ctx, maxX - EDGE_LENGTH, maxY);
    CGContextAddLineToPoint(ctx, maxX, maxY);
    CGContextAddLineToPoint(ctx, maxX, maxY - EDGE_LENGTH);
    
    CGContextStrokePath(ctx);
}

@end
