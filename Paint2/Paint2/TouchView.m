//
//  TouchView.m
//  Paint2
//
//  Created by IOS－winner on 16/3/30.
//  Copyright © 2016年 IOS－winner. All rights reserved.
//

#import "TouchView.h"
#import "PaintView.h"
@interface TouchView ()

@property (nonatomic,assign) CGPoint startPoint;
@property (nonatomic,strong) PaintView *paint;
@end
@implementation TouchView

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//    UITouch *aTouch = touches.anyObject;
//    self.startPoint = [aTouch locationInView:self.superview];
//}
//
//- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//    UITouch *aTouch = touches.anyObject;
//    CGPoint position = [aTouch locationInView:self.superview];
//    
//    CGFloat delta_x = position.x - _startPoint.x;
//    CGFloat delta_y = position.y - _startPoint.y;
//    
//    CGPoint currentCenter = self.center;
//    currentCenter.x += delta_x;
//    currentCenter.y += delta_y;
//    
//    self.center = currentCenter;
//    
//    self.startPoint = position;
//    
//    //[_paint setNeedsDisplay];
//}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor cyanColor];
        //_paint = [[PaintView alloc]init];
    }
    return self;
}

- (void)clean
{
    [self removeFromSuperview];
}
@end
