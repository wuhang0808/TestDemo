//
//  PaintView.m
//  Paint2
//
//  Created by IOS－winner on 16/3/30.
//  Copyright © 2016年 IOS－winner. All rights reserved.
//

#import "PaintView.h"
#import "TouchView.h"
#import "LinesModel.h"
#import "DistanceModel.h"
#import "PointModel.h"
#import "PointAndAngle.h"
#import "MBProgressHUD.h"

#define offset 20
#define textViewHeight 50
#define pointOffset 30
#define kWidth self.frame.size.width
#define kHeight self.frame.size.height
@interface PaintView ()

@property (nonatomic,assign) CGPoint startPoint;

@property (nonatomic,strong) NSMutableArray *pointMutableArray;
@property (nonatomic,assign) BOOL result;
@property (nonatomic,strong) TouchView *tView;
@property (nonatomic,strong) UIBezierPath *path;
@property (nonatomic,strong) UIBezierPath *path2;
@property (nonatomic,strong) UITextView *textView;
@property (nonatomic,assign) NSInteger currentIndex;
@property (nonatomic,assign) CGPoint saveLastPoint;
@property (nonatomic,assign) BOOL tap;
@property (nonatomic,strong) NSDictionary *addPointDict;
@property (nonatomic,strong) NSMutableArray *addPointArr;
@property (nonatomic,assign) NSInteger addPointIndex;
@property (nonatomic,assign) CGFloat minPointToLine;
@end
@implementation PaintView

- (NSMutableArray *)allLines
{
    if (!_allLines) {
        _allLines = [NSMutableArray array];
    }
    return _allLines;
}

- (NSMutableArray *)allLines2
{
    if (!_allLines) {
        _allLines2 = [NSMutableArray new];
    }
    return _allLines2;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *aTouch = touches.anyObject;
    _startPoint = [aTouch locationInView:self.superview];
    
    self.pointMutableArray = [NSMutableArray array];
    
    [self saveLinesModel];
    
    NSDictionary *dict1 = [self minOfPointToPointWith:self.allLines];
    NSDictionary *dict2 = [self minOfPointToPointWith:self.allLines2];
    CGFloat minPoint1 = [dict1[@"min"] floatValue];
    CGFloat minPoint2 = [dict2[@"min"] floatValue];
    
    NSMutableArray *currentArray = minPoint1 < minPoint2 ? self.allLines : self.allLines2;
    [self tapIndexWithCurrentArray:currentArray];
    
    _addPointDict = [self addPointToArray];
    
    _addPointArr = _addPointDict[@"allLine"];
    
    _addPointIndex = [_addPointDict[@"index"] integerValue];
    
    _minPointToLine = [_addPointDict[@"min"] floatValue];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *aTouch = touches.anyObject;
    CGPoint movePoint = [aTouch locationInView:self.superview];
    CGFloat yUp = _startPoint.y-offset;
    CGFloat yDown = _startPoint.y+offset;
    CGFloat xLeft = _startPoint.x-offset;
    CGFloat xRight = _startPoint.x+offset;
    //NSLog(@"startPoint x:%.2f y:%.2f",_startPoint.x,_startPoint.y);
    
    NSDictionary *dict1 = [self minOfPointToPointWith:self.allLines];
    NSDictionary *dict2 = [self minOfPointToPointWith:self.allLines2];
    CGFloat minPoint1 = [dict1[@"min"] floatValue];
    CGFloat minPoint2 = [dict2[@"min"] floatValue];
    
    CGFloat minPoint = minPoint1 < minPoint2 ? minPoint1 : minPoint2;
    NSMutableArray *currentArray = minPoint1 < minPoint2 ? self.allLines : self.allLines2;
   // NSMutableArray *lineArray = minPoint1 < minPoint2 ? self.lineMutableArray : self.lineMutableArray2;
    NSMutableArray *otherPointArray = minPoint1 > minPoint2 ? self.allLines : self.allLines2;
    
    NSDictionary *dict = minPoint1 < minPoint2 ? dict1 : dict2;
    NSInteger index = [dict[@"index"] integerValue];
    
    NSLog(@"start(x:%.f,y:%.f)",_startPoint.x,_startPoint.y);
    NSLog(@"index:%ld",(long)index);
    
    
    if (minPoint1 < minPoint2) {
        _tap = YES;
    }else {
        _tap = NO;
    }
    if (movePoint.y > 40 && movePoint.y < kHeight - 60) {
        if (minPoint < offset && _minPointToLine < offset) {
            
            [self moveToPointWithXleft:xLeft xRight:xRight yUp:yUp yDown:yDown movePoint:movePoint currentArray:currentArray otherPointArray:otherPointArray];
            
        }else if (_minPointToLine < offset && minPoint > offset && _addPointArr.count<16){
            
            [self moveToPointAddLinesWithLineArray:_addPointArr index:_addPointIndex];
            [self moveToPointWithXleft:xLeft xRight:xRight yUp:yUp yDown:yDown movePoint:movePoint currentArray:currentArray otherPointArray:otherPointArray];
        }

    }
    
    [self saveLinesModel];
    
    [self setNeedsDisplay];
}
- (void)tapIndexWithCurrentArray:(NSMutableArray *)currentArray
{
    CGFloat yUp = _startPoint.y-offset;
    CGFloat yDown = _startPoint.y+offset;
    CGFloat xLeft = _startPoint.x-offset;
    CGFloat xRight = _startPoint.x+offset;
    
    for (int i = 0; i < currentArray.count; i++) {
        
        CGPoint currentPoint = CGPointFromString(currentArray[i]);
        
        if (xLeft < currentPoint.x && currentPoint.x < xRight && yUp < currentPoint.y && currentPoint.y < yDown) {
            
            _saveLastPoint = CGPointFromString(currentArray[i]);
        }
    }

}
- (NSArray *)calculateAngleFromPointWith:(NSMutableArray *)currentArray
{
    NSInteger count = currentArray.count;
    NSMutableArray *indexArray = [NSMutableArray array];
    NSMutableArray *saveAllLineArray = [NSMutableArray array];
    for (int i = 0; i<count; i++) {
        CGPoint firstPoint = CGPointFromString(currentArray[(i+count-1)%count]);
        CGPoint centerPoint = CGPointFromString(currentArray[i]);
        CGPoint lastPoint = CGPointFromString(currentArray[(i+1)%count]);
        
        CGFloat firstAngle = [self calculateAngleForStartEdgeWithCenterPoint:centerPoint startPoint:firstPoint];
        CGFloat lastAngle = [self calculateAngleForEndEdgeWithCenterPoint:centerPoint endPoint:lastPoint];
        CGFloat areaAngle = [self calculateAngleForAreasWithCenterPoint:centerPoint firstPoint:firstPoint lastPoint:lastPoint];
        CGFloat sumAngle = firstAngle+lastAngle+areaAngle;
        
        PointAndAngle *pointAngle = [[PointAndAngle alloc]init];
        pointAngle.XY = centerPoint;
        pointAngle.angle = sumAngle;
        [indexArray addObject:pointAngle];
        //NSLog(@"pointX:%.2f Y:%.2f angle:%.2f",pointAngle.XY.x,pointAngle.XY.y,pointAngle.angle);
        if (sumAngle < 170 || sumAngle > 190) {
            [saveAllLineArray addObject:currentArray[i]];
        }
    }
    return saveAllLineArray;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    
    
    NSDictionary *dict1 = [self minOfPointToPointWith:self.allLines];
    NSDictionary *dict2 = [self minOfPointToPointWith:self.allLines2];
    CGFloat minPoint1 = [dict1[@"min"] floatValue];
    CGFloat minPoint2 = [dict2[@"min"] floatValue];
    
    NSMutableArray *currentArray = minPoint1 < minPoint2 ? self.allLines : self.allLines2;
    NSMutableArray *lineArray = minPoint1 < minPoint2 ? self.lineMutableArray : self.lineMutableArray2;
    NSMutableArray *otherPointArray = minPoint1 > minPoint2 ? self.allLines : self.allLines2;
    NSMutableArray *otherLineArray = minPoint1 > minPoint2 ? self.lineMutableArray : self.lineMutableArray2;
    
    //判断一个多边形内是否有直线相交
    [self theSamePolygonCannotIntersectWithCurrent:currentArray lineArray:lineArray];
    
    NSMutableString *firstString = [NSMutableString string];
    for (int i = 0; i< _allLines.count; i++) {
        CGPoint point = CGPointFromString(_allLines[i]);
        NSString *string = [NSString stringWithFormat:@"(%.2f,%.2f) ",point.x,point.y];
        [firstString appendString:string];
    }
    
    NSMutableString *secondString = [NSMutableString string];
    for (int i = 0; i< _allLines2.count; i++) {
        CGPoint point = CGPointFromString(_allLines2[i]);
        NSString *string = [NSString stringWithFormat:@"(%.2f,%.2f) ",point.x,point.y];
        [secondString appendString:string];
    }
    NSString *sumString = [NSString stringWithFormat:@"%@\n%@",firstString,secondString];
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewText:)]) {
        [self.delegate textViewText:sumString];
    }
    
    
    //判断两个图形是否相交
    [self judgeTwoLinesInterscetWithCurrentArray:currentArray lineArray:lineArray otherPointArray:otherPointArray otherLineArray:otherLineArray];
    
    //判断是否包含
    [self judgeTwoLinesIncludeWithArray:currentArray bezierPath:_path pointArray:_allLines2];
    [self judgeTwoLinesIncludeWithArray:currentArray bezierPath:_path2 pointArray:_allLines];
    
    NSArray *angleArray = [self calculateAngleFromPointWith:currentArray];
    
    [currentArray removeAllObjects];
    
    [currentArray addObjectsFromArray:angleArray];
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self creatTouchView];
    
    [self setNeedsDisplay];
    
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"fesfhjowe;hfouwe;jw");
}
#pragma mark 同一个多边形不能相交
- (void)theSamePolygonCannotIntersectWithCurrent:(NSMutableArray *)currentArray lineArray:(NSMutableArray *)lineArray
{
    NSInteger count = currentArray.count;
    CGPoint firstPoint = CGPointFromString(currentArray[(_currentIndex+1)%count]);
    CGPoint centerPoint = CGPointFromString(currentArray[_currentIndex]);
    CGPoint lastPoint = CGPointFromString(currentArray[(_currentIndex+count-1)%count]);
    LinesModel *firstModel = [lineArray objectAtIndex:_currentIndex];
    
    for (int i = 0; i<count-3; i++) {
        LinesModel *testModel = [lineArray objectAtIndex:(_currentIndex+2+i)%count];
        CGPoint testPoint1 = CGPointFromString(currentArray[(_currentIndex+2+i)%count]);
        CGPoint testPoint2 = CGPointFromString(currentArray[(_currentIndex+3+i)%count]);
        
        BOOL lineResult = [self judgeTwoLinesIntersectWihtFirstLine:firstModel lastLine:testModel];
        if (lineResult) {
            CGPoint point = [self twoLinesIntersectPointWithFirstLine:firstModel lastLine:testModel];
            BOOL result = [self judgePointInLineWithFirstPoint:centerPoint lastPoint:firstPoint testPoint:point testPoint1:testPoint1 testPoint2:testPoint2];
            if (result) {
                [currentArray replaceObjectAtIndex:_currentIndex withObject:NSStringFromCGPoint(_saveLastPoint)];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(addProgressHUDWithTitle:)]) {
                    [self.delegate addProgressHUDWithTitle:@"不能相交"];
                    
                }
            }
        }
    }
    
    
    LinesModel *lastModel2 = [lineArray objectAtIndex:(_currentIndex+count-1)%count];
    
    for (int j = 0; j<count-3; j++) {
        LinesModel *testModel = [lineArray objectAtIndex:(_currentIndex+1+j)%count];
        CGPoint testPoint1 = CGPointFromString(currentArray[(_currentIndex+1+j)%count]);
        CGPoint testPoint2 = CGPointFromString(currentArray[(_currentIndex+2+j)%count]);
        
        BOOL lineResult = [self judgeTwoLinesIntersectWihtFirstLine:lastModel2 lastLine:testModel];
        if (lineResult) {
            CGPoint point = [self twoLinesIntersectPointWithFirstLine:lastModel2 lastLine:testModel];
            BOOL result = [self judgePointInLineWithFirstPoint:centerPoint lastPoint:lastPoint testPoint:point testPoint1:testPoint1 testPoint2:testPoint2];
            if (result) {
                [currentArray replaceObjectAtIndex:_currentIndex withObject:NSStringFromCGPoint(_saveLastPoint)];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(addProgressHUDWithTitle:)]) {
                    [self.delegate addProgressHUDWithTitle:@"不能相交"];
                    
                }
            }
        }
    }
   
}

#pragma mark 两个多边形不能相互包含
- (void)judgeTwoLinesIncludeWithArray:(NSMutableArray *)currentArray bezierPath:(UIBezierPath *)path pointArray:(NSMutableArray *)pointArray
{
    BOOL include1;
    for (int i = 0; i < pointArray.count; i++) {
        CGPoint point = CGPointFromString(pointArray[i]);
        BOOL include1 = [path containsPoint:point];
        if (!include1) {
            
            return;
        }
    }
    if (include1) {
        [currentArray replaceObjectAtIndex:_currentIndex withObject:NSStringFromCGPoint(_saveLastPoint)];
        if (self.delegate && [self.delegate respondsToSelector:@selector(addProgressHUDWithTitle:)]) {
            [self.delegate addProgressHUDWithTitle:@"不能相互包含"];
        }
    }
}


- (void)judgeTwoLinesInterscetWithCurrentArray:(NSMutableArray *)currentArray lineArray:(NSMutableArray *)lineArray otherPointArray:(NSMutableArray *)otherPointArray otherLineArray:(NSMutableArray *)otherLineArray
{
    NSInteger count1 = currentArray.count;
    NSInteger count2 = otherPointArray.count;
    
    CGPoint firstPoint = CGPointFromString(currentArray[(_currentIndex+1)%count1]);
    CGPoint centerPoint = CGPointFromString(currentArray[_currentIndex]);
    CGPoint lastPoint = CGPointFromString(currentArray[(_currentIndex+count1-1)%count1]);
    
    LinesModel *firstModel = [lineArray objectAtIndex:_currentIndex];
    LinesModel *lastModel = [lineArray objectAtIndex:(_currentIndex+count1-1)%count1];
    
    for (int i = 0; i<count2; i++) {
        LinesModel *testModel = [otherLineArray objectAtIndex:i];
        CGPoint testPoint1 = CGPointFromString(otherPointArray[i]);
        CGPoint testPoint2 = CGPointFromString(otherPointArray[(i+1)%count2]);
        
        BOOL lineResult = [self judgeTwoLinesIntersectWihtFirstLine:firstModel lastLine:testModel];
        if (lineResult) {
            CGPoint point = [self twoLinesIntersectPointWithFirstLine:firstModel lastLine:testModel];
            BOOL result = [self judgePointInLineWithFirstPoint:centerPoint lastPoint:firstPoint testPoint:point testPoint1:testPoint1 testPoint2:testPoint2];
            if (result) {
                [currentArray replaceObjectAtIndex:_currentIndex withObject:NSStringFromCGPoint(_saveLastPoint)];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(addProgressHUDWithTitle:)]) {
                    [self.delegate addProgressHUDWithTitle:@"不能相交"];
                }
            }
        }
    }
    
    for (int j = 0; j<count2; j++) {
        LinesModel *testModel = [otherLineArray objectAtIndex:j];
        CGPoint testPoint1 = CGPointFromString(otherPointArray[j]);
        CGPoint testPoint2 = CGPointFromString(otherPointArray[(j+1)%count2]);
        
        BOOL lineResult = [self judgeTwoLinesIntersectWihtFirstLine:lastModel lastLine:testModel];
        if (lineResult) {
            CGPoint point = [self twoLinesIntersectPointWithFirstLine:lastModel lastLine:testModel];
            BOOL result = [self judgePointInLineWithFirstPoint:centerPoint lastPoint:lastPoint testPoint:point testPoint1:testPoint1 testPoint2:testPoint2];
            if (result) {
                [currentArray replaceObjectAtIndex:_currentIndex withObject:NSStringFromCGPoint(_saveLastPoint)];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(addProgressHUDWithTitle:)]) {
                    [self.delegate addProgressHUDWithTitle:@"不能相交"];
                }
            }
        }
    }
}


- (void)saveLinesModel
{
    self.lineMutableArray = [NSMutableArray array];
    self.distanceArray = [NSMutableArray array];
    
    self.lineMutableArray2 = [NSMutableArray array];
    self.distanceArray2 = [NSMutableArray array];
    
    NSInteger count = self.allLines.count;
    for (int i = 0; i < count; i++) {
        CGPoint point1 = CGPointFromString(self.allLines[i]);
        CGPoint point2 = CGPointFromString(self.allLines[(i+1)%count]);
        
        LinesModel *model = [[LinesModel alloc]init];
        model.Avalue = [NSString stringWithFormat:@"%f",-(point2.y-point1.y)];
        model.Bvalue = [NSString stringWithFormat:@"%f",point2.x-point1.x];
        model.Cvalue = [NSString stringWithFormat:@"%f",point1.x*point2.y - point2.x*point1.y];
        [_lineMutableArray addObject:model];
    }
    
    //NSMutableArray *distanceArray = [NSMutableArray array];
    for (LinesModel *model in _lineMutableArray) {
        
        DistanceModel *disModel = [[DistanceModel alloc]init];
        CGFloat a = [model.Avalue floatValue];
        CGFloat b = [model.Bvalue floatValue];
        CGFloat c = [model.Cvalue floatValue];
        CGFloat distance = (_startPoint.x*a + _startPoint.y*b + c) / sqrt(pow(a, 2) + pow(b, 2));
        disModel.distance = [NSString stringWithFormat:@"%f",fabs(distance)];
        [_distanceArray addObject:disModel];
        
    }
    
    
    NSInteger count2 = self.allLines2.count;
    for (int j = 0; j < count2; j++) {
        
        CGPoint point1 = CGPointFromString(self.allLines2[j]);
        CGPoint point2 = CGPointFromString(self.allLines2[(j+1)%count2]);
            
        LinesModel *model = [[LinesModel alloc]init];
        model.Avalue = [NSString stringWithFormat:@"%f",-(point2.y-point1.y)];
        model.Bvalue = [NSString stringWithFormat:@"%f",point2.x-point1.x];
        model.Cvalue = [NSString stringWithFormat:@"%f",point1.x*point2.y - point2.x*point1.y];
        [_lineMutableArray2 addObject:model];
    
    }
    
    //NSMutableArray *distanceArray = [NSMutableArray array];
    for (LinesModel *model in _lineMutableArray2) {
        
        DistanceModel *disModel = [[DistanceModel alloc]init];
        CGFloat a = [model.Avalue floatValue];
        CGFloat b = [model.Bvalue floatValue];
        CGFloat c = [model.Cvalue floatValue];
        CGFloat distance = (_startPoint.x*a + _startPoint.y*b + c) / sqrt(pow(a, 2) + pow(b, 2));
        disModel.distance = [NSString stringWithFormat:@"%f",fabs(distance)];
        [_distanceArray2 addObject:disModel];
        
    }
}
#pragma mark 判断两直线是否相交
- (BOOL)judgeTwoLinesIntersectWihtFirstLine:(LinesModel *)firstLine lastLine:(LinesModel *)lastLine
{
    CGFloat a1 = [firstLine.Avalue floatValue];
    CGFloat b1 = [firstLine.Bvalue floatValue];
    
    CGFloat a2 = [lastLine.Avalue floatValue];
    CGFloat b2 = [lastLine.Bvalue floatValue];
    if (a1/a2 != b1/b2) {
        return YES;
    }else{
        return NO;
    }
    
}

#pragma mark 求两直线的交点
- (CGPoint)twoLinesIntersectPointWithFirstLine:(LinesModel *)firstLine lastLine:(LinesModel *)lastLine
{
    CGFloat a1 = [firstLine.Avalue floatValue];
    CGFloat b1 = [firstLine.Bvalue floatValue];
    CGFloat c1 = [firstLine.Cvalue floatValue];
    
    CGFloat a2 = [lastLine.Avalue floatValue];
    CGFloat b2 = [lastLine.Bvalue floatValue];
    CGFloat c2 = [lastLine.Cvalue floatValue];
    CGFloat y = (a2*c1-a1*c2)/(a1*b2-a2*b1);
    CGFloat x = (b1*c2-b2*c1)/(a1*b2-a2*b1);
    
    CGPoint lineIntersectPoint = CGPointMake(x, y);
    
    return lineIntersectPoint;
}

- (BOOL)judgePointInLineWithFirstPoint:(CGPoint)firstPoint lastPoint:(CGPoint)lastPoint testPoint:(CGPoint)testPoint testPoint1:(CGPoint)testPoint1 testPoint2:(CGPoint)testPoint2
{
    CGFloat x1 = firstPoint.x;
    CGFloat y1 = firstPoint.y;
    
    CGFloat x2 = lastPoint.x;
    CGFloat y2 = lastPoint.y;
    
    CGFloat x3 = testPoint1.x;
    CGFloat y3 = testPoint1.y;
    
    CGFloat x4 = testPoint2.x;
    CGFloat y4 = testPoint2.y;
    
    CGFloat x = testPoint.x;
    CGFloat y = testPoint.y;
    
    CGFloat value = (y-y1)*(x2-x1) - (x-x1)*(y2-y1);
    
    CGFloat maxX1 = x1 > x2 ? x1 : x2;
    CGFloat minX1 = x1 < x2 ? x1 : x2;
    
    CGFloat maxY2 = y1 > y2 ? y1 : y2;
    CGFloat minY2 = y1 < y2 ? y1 : y2;
    
    CGFloat maxX3 = x3 > x4 ? x3 : x4;
    CGFloat minX3 = x3 < x4 ? x3 : x4;
    
    CGFloat maxY4 = y3 > y4 ? y3 : y4;
    CGFloat minY4 = y3 < y4 ? y3 : y4;
    
    if (x >= minX1 && x <=maxX1 && y >= minY2 && y<= maxY2 && round(value) == 0 && x >= minX3 && x <= maxX3 && y >= minY4 && y <= maxY4) {
        return YES;
    }else{
        return NO;
    }
    
    
}
- (void)drawRect:(CGRect)rect
{
    
    CGPoint A;
    A = CGPointFromString(self.allLines[0]);
    _path = [[UIBezierPath alloc] init];
    _path.lineWidth = 4;
    UIColor *strokeColor = [UIColor redColor];
    [strokeColor set];
    [_path setLineCapStyle:kCGLineCapRound];
    [_path setLineJoinStyle:kCGLineJoinRound];
    [_path moveToPoint:CGPointMake(A.x, A.y)];
    
    for (int i = 1; i<self.allLines.count; i++) {
        CGPoint point = CGPointFromString(self.allLines[i]);
        [_path addLineToPoint:CGPointMake(point.x, point.y)];
    }
    
    [_path closePath];
    [_path stroke];
    
    CGPoint onePoint = CGPointFromString(self.allLines2[0]);
    _path2 = [[UIBezierPath alloc]init];
    _path2.lineWidth = 4;
    UIColor *color = [UIColor purpleColor];
    [color set];
    [_path2 setLineCapStyle:kCGLineCapRound];
    [_path2 setLineJoinStyle:kCGLineJoinRound];
    [_path2 moveToPoint:CGPointMake(onePoint.x, onePoint.y)];
    for (int j = 1; j < self.allLines2.count; j++) {
        CGPoint point = CGPointFromString(_allLines2[j]);
        [_path2 addLineToPoint:CGPointMake(point.x, point.y)];
    }
    [_path2 closePath];
    [_path2 stroke];
}

#pragma mark 点到直线的最小距离和所在坐标
- (NSDictionary *)minDistancePointToLinesWithArray:(NSArray *)distanceArray
{
    CGFloat min = MAXFLOAT;
    NSInteger index = 0;
    for (int i = 0; i < distanceArray.count; i++) {
        DistanceModel *model = distanceArray[i];
        if (min > [model.distance floatValue]) {
            min = [model.distance floatValue];
        }
    }
    
    for (int i = 0; i < distanceArray.count;i++) {
        DistanceModel *model = distanceArray[i];
        if ([model.distance floatValue] == min) {
            index = i%distanceArray.count;
        }
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(min) forKey:@"min"];
    [dict setObject:@(index) forKey:@"index"];
    
    return dict;
}

#pragma mark 点到点的最小距离
- (NSDictionary *)minOfPointToPointWith:(NSArray *)lineArray
{
    for (int i = 0; i<lineArray.count; i++) {
        PointModel *model = [[PointModel alloc]init];
        CGPoint point = CGPointFromString(lineArray[i]);
        
        model.distancePoint = [NSString stringWithFormat:@"%f",sqrt(pow(_startPoint.x-point.x, 2) + pow(_startPoint.y-point.y, 2))];
        [_pointMutableArray addObject:model];
    }
    
    CGFloat min = MAXFLOAT;
    for (int i = 0; i<_pointMutableArray.count; i++) {
        PointModel *model = _pointMutableArray[i];
        if (min > [model.distancePoint floatValue]) {
            min = [model.distancePoint floatValue];
        }
    }
    NSInteger index = 0;
    for (int i = 0; i < _pointMutableArray.count; i++) {
        PointModel *model = _pointMutableArray[i];
        if ([model.distancePoint floatValue] == min) {
            index = i;
        }
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@(min) forKey:@"min"];
    [dict setValue:@(index) forKey:@"index"];
    
    [_pointMutableArray removeAllObjects];
    return dict;
}

#pragma mark 判断起始点是否在点击范围内
- (BOOL)tapIsBoolInRangeWithIndex:(NSInteger)index currntArray:(NSMutableArray *)currentArray
{
    CGPoint frontPoint = CGPointFromString(currentArray[index]);
    CGPoint lastPoint = CGPointFromString(currentArray[(index+1)%currentArray.count]);
    CGPoint centerPoint = CGPointMake((frontPoint.x+lastPoint.x)/2, (frontPoint.y+lastPoint.y)/2);
    
    CGFloat currentLineLength = sqrt(pow(lastPoint.x-frontPoint.x, 2)+pow(lastPoint.y-frontPoint.y, 2));
    
    CGFloat pointDistance = sqrt(pow(_startPoint.x-centerPoint.x, 2)+pow(_startPoint.y-centerPoint.y, 2));
    
    if (pointDistance < currentLineLength/2) {
        
        //NSLog(@"pointDistance:%.2f  currentLineLength:%.2f",pointDistance,currentLineLength/2);
        return YES;
    }
   
    return NO;
    
}

#pragma mark 判断加点是在哪一个数组中
- (NSDictionary *)addPointToArray
{
    NSDictionary *dict1 = [self minDistancePointToLinesWithArray:self.distanceArray];
    
    NSDictionary *dict2 = [self minDistancePointToLinesWithArray:self.distanceArray2];
    
    CGFloat minDistance1 = [dict1[@"min"] floatValue];
    CGFloat minDistance2 = [dict2[@"min"] floatValue];
    
    CGPoint frontPoint1 = CGPointFromString(_allLines[[dict1[@"index"] integerValue]]);
    CGPoint lastPoint1 = CGPointFromString(_allLines[([dict1[@"index"]integerValue]+1)%self.allLines.count]);
    
    CGPoint frontPoint2 = CGPointFromString(_allLines2[[dict2[@"index"] integerValue]]);
    CGPoint lastPoint2 = CGPointFromString(_allLines2[([dict2[@"index"]integerValue]+1)%self.allLines2.count]);
    
    CGPoint centerPoint1 = CGPointMake((frontPoint1.x+lastPoint1.x)/2, (frontPoint1.y+lastPoint1.y)/2);
    CGPoint centerPoint2 = CGPointMake((frontPoint2.x+lastPoint2.x)/2, (frontPoint2.y+lastPoint2.y)/2);
    
    CGFloat currentLineLength1 = sqrt(pow(lastPoint1.x-frontPoint1.x, 2) + pow(lastPoint1.y-frontPoint1.y, 2));
    CGFloat currentLineLength2 = sqrt(pow(lastPoint2.x-frontPoint2.x, 2) + pow(lastPoint2.y-frontPoint2.y, 2));
    
    CGFloat pointDistance1 = sqrt(pow(_startPoint.x-centerPoint1.x, 2) + pow(_startPoint.y-centerPoint1.y, 2));
    CGFloat pointDistance2 = sqrt(pow(_startPoint.x-centerPoint2.x, 2) + pow(_startPoint.y-centerPoint2.y, 2));
    
    if (pointDistance1 < currentLineLength1/2 && minDistance1 < offset && minDistance1 < minDistance2) {
        
        [dict1 setValue:_allLines forKey:@"allLine"];
        return dict1;
    }else if (pointDistance2 < currentLineLength2/2 && minDistance2 < offset && minDistance2 < minDistance1){
        [dict2 setValue:_allLines2 forKey:@"allLine"];
        return dict2;
    }else if (pointDistance1 < currentLineLength1/2 && minDistance1 < offset) {
        
        [dict1 setValue:_allLines forKey:@"allLine"];
        return dict1;
    }else if (pointDistance2 < currentLineLength2/2 && minDistance2 < offset) {
        [dict2 setValue:_allLines2 forKey:@"allLine"];
        return dict2;
    }
    return nil;
}

#pragma mark 移动点
- (void)moveToPointWithXleft:(CGFloat)xLeft xRight:(CGFloat)xRight yUp:(CGFloat)yUp yDown:(CGFloat)yDown movePoint:(CGPoint)movePoint currentArray:(NSMutableArray *)currentArray otherPointArray:(NSMutableArray *)othPointArray
{
    NSInteger count = currentArray.count;
    NSInteger count2 = othPointArray.count;
    
    NSInteger index = 1;
    CGFloat min = MAXFLOAT;
    CGFloat min2 = MAXFLOAT;
    
    for (int i = 0; i < count; i++) {
        
        CGPoint currentPoint = CGPointFromString(currentArray[i]);
        
        if (xLeft < currentPoint.x && currentPoint.x < xRight && yUp < currentPoint.y && currentPoint.y < yDown) {
        
            _currentIndex = i;
            
            //当前移动点到其他点的距离最小值
            for (int j = 0; j<count-1; j++) {
                CGPoint otherPoint = CGPointFromString(currentArray[(i+index)%count]);
                CGFloat value = sqrt(pow(movePoint.x-otherPoint.x, 2)+pow(movePoint.y-otherPoint.y, 2));
                index++;
                if (min > value) {
                    min = value;
                }
                
            }
            
            for (int j = 0; j<count2; j++) {
                CGPoint point = CGPointFromString(othPointArray[j]);
                CGFloat value = sqrtf(pow(movePoint.x-point.x, 2) + pow(movePoint.y-point.y, 2));
                if (min2 > value) {
                    min2 = value;
                }
            }
            
            if (min > pointOffset && min2 > pointOffset) {
                currentArray[i] = NSStringFromCGPoint(movePoint);
                
                _startPoint = movePoint;
            }
            
            if (_tap) {
                TouchView *view = (TouchView *)[self viewWithTag:i+100];
                view.center = CGPointFromString(currentArray[i]);
            }else {
                TouchView *view2 = (TouchView *)[self viewWithTag:i+200];
                view2.center = CGPointFromString(currentArray[i]);
            }
            
        }
        
    }

}

#pragma mark 增加点并且移动
- (void)moveToPointAddLinesWithLineArray:(NSMutableArray *)lineArray index:(NSInteger)index
{
    
        [lineArray insertObject:NSStringFromCGPoint(_startPoint) atIndex:index+1];
        
        _saveLastPoint = _startPoint;
        
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self creatTouchView];
    

}

- (void)creatTouchView
{
    for (int i = 0; i < self.allLines.count; i++) {
        TouchView *tView = [[TouchView alloc]initWithFrame:CGRectMake(0, 0, 12, 12)];
        tView.center = CGPointFromString(self.allLines[i]);
        tView.backgroundColor = [UIColor redColor];
        tView.layer.cornerRadius = 6;
        tView.layer.masksToBounds = YES;
        tView.tag = i+100;
        [self addSubview:tView];
    }
    
    for (int j = 0; j < self.allLines2.count; j++) {
        TouchView *tView2 = [[TouchView alloc]initWithFrame:CGRectMake(0, 0, 12, 12)];
        tView2.center = CGPointFromString(self.allLines2[j]);
        tView2.backgroundColor = [UIColor purpleColor];
        tView2.layer.cornerRadius = 6;
        tView2.layer.masksToBounds = YES;
        tView2.tag = j + 200;
        [self addSubview:tView2];
    }
}

- (void)layoutSubviews
{
    
   
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)orignList
{
    NSMutableString *text = [NSMutableString string];
    for (int i = 0; i<self.allLines.count; i++) {
        CGPoint point = CGPointFromString(self.allLines[i]);
        NSString *string = [NSString stringWithFormat:@"%ld.(%.2f,%.2f) ",(long)i+1,point.x,point.y];
        [text appendString:string];
    }
    _textView.text = text;
    
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc]initWithFrame:CGRectMake(0, kHeight-textViewHeight, kWidth, textViewHeight)];
        _textView.scrollEnabled = YES;
        _textView.tag = 1100;
        _textView.textColor = [UIColor blackColor];
        _textView.backgroundColor = [UIColor cyanColor];
        //_textView.editable = NO;
        [self addSubview:_textView];
        
    }
    return _textView;
}
#pragma mark 计算坐标差
- (CGPoint)keyAndXYWithCenterPoint:(CGPoint)centterPoint otherPoint:(CGPoint)otherPoint
{
    CGPoint newPoint;
    newPoint.x = centterPoint.x-otherPoint.x;
    newPoint.y = centterPoint.y-otherPoint.y;
    return newPoint;
}

#pragma maek 判断点所在象限
- (NSInteger)getOtherPointOfPositionCenterPoint:(CGPoint)centterPoint otherPoint:(CGPoint)otherPoint
{
    NSInteger flag;
    CGPoint point = [self keyAndXYWithCenterPoint:centterPoint otherPoint:otherPoint];
    
    if (point.x<0 && point.y>0) {
        flag = 1;
    }else if (point.x>0 && point.y>0){
        flag = 2;
    }else if (point.x>0 && point.y<0){
        flag = 3;
    }else if (point.x<0 && point.y<0){
        flag = 4;
    }else if (point.x<0 && point.y==0){
        flag = 4;
    }else if (point.x>0 && point.y==0){
        flag = 2;
    }else if (point.x==0 && point.y>0){
        flag = 1;
    }else if (point.x==0 && point.y<0){
        flag = 3;
    }else{
        flag = 0;
    }
    return flag;
}

#pragma maek 顺时针计算象限个数 返回角度值
- (CGFloat)calculateAngleForAreasWithCenterPoint:(CGPoint)centerPoint firstPoint:(CGPoint)firstPoint lastPoint:(CGPoint)lastPoint
{
    NSInteger startArea = [self getOtherPointOfPositionCenterPoint:centerPoint otherPoint:firstPoint];
    NSInteger endArea = [self getOtherPointOfPositionCenterPoint:centerPoint otherPoint:lastPoint];
    CGFloat angle;
    if (startArea == endArea) {
        return  270;
        
    }else if (startArea == 1){
        
        if (endArea == 2) {
            
            return  180;
        }else if (endArea == 3){
            
            return  90;
        }else{
            return  0;
        }
        
    }else if (startArea == 2){
        
        if (endArea == 1) {
            
            return  0;
        }else if (endArea == 3){
            angle = 180;
            
        }else{
            return  90;
        }
        
    }else if (startArea == 3){
        
        if (endArea ==1) {
            
            return  90;
        }else if (endArea == 2){
            
            return  0;
        }else{
            return  180;
        }
        
    }else if (startArea == 4){
        
        if (endArea == 1) {
            
            return  180;
        }else if (endArea == 2){
            
            return  90;
        }else{
            
            return  0;
        }
        
    }
    return 0;
}

#pragma mark 根据象限获取起始辅助点
- (CGPoint)getNeedPointForStarEdgeWithCenterPoint:(CGPoint)centerPoint otherPoint:(CGPoint)otherPoint
{
    NSInteger area = [self getOtherPointOfPositionCenterPoint:centerPoint otherPoint:otherPoint];
    NSInteger X;
    NSInteger Y;
    
    if (area == 1) {
        
        X = 1;
        Y = 0;
    }else if (area == 2){
        
        X = 0;
        Y = 1;
    }else if (area == 3){
        
        X = -1;
        Y = 0;
    }else{
        X = 0;
        Y = -1;
    }
    centerPoint.x = centerPoint.x + X;
    centerPoint.y = centerPoint.y + Y;
    return centerPoint;
}

#pragma mark 获取终止辅助点
- (CGPoint)getNeedPointForEndEdgeWithCenterPoint:(CGPoint)centerPoint otherPoint:(CGPoint)otherPoint
{
    NSInteger area = [self getOtherPointOfPositionCenterPoint:centerPoint otherPoint:otherPoint];
    NSInteger X;
    NSInteger Y;
    if (area == 1) {
        
        X = 0;
        Y = 1;
    }else if (area == 2){
        
        X = -1;
        Y = 0;
    }else if (area == 3){
        
        X = 0;
        Y = -1;
    }else{
        X = 1;
        Y = 0;
    }
    centerPoint.x = centerPoint.x + X;
    centerPoint.y = centerPoint.y + Y;
    return centerPoint;
}

- (CGFloat)calculateAngleForStartEdgeWithCenterPoint:(CGPoint)centerPoint startPoint:(CGPoint)startPoint
{
    NSInteger area = [self getOtherPointOfPositionCenterPoint:centerPoint otherPoint:startPoint];
    if (area == 0) {
        return 0;
    }
    CGPoint assisPoint = [self getNeedPointForStarEdgeWithCenterPoint:centerPoint otherPoint:startPoint];
    
    CGFloat angle = [self calcuateAngleWithCenterPoint:centerPoint assisPoint:assisPoint otherPoint:startPoint];
    
    if (angle == 180) {
        return 0;
    }
    if (angle > 90 && angle < 180) {
        return 180-angle;
    }
    return angle;
}

- (CGFloat)calculateAngleForEndEdgeWithCenterPoint:(CGPoint)centerPoint endPoint:(CGPoint)endPoint
{
    NSInteger area = [self getOtherPointOfPositionCenterPoint:centerPoint otherPoint:endPoint];
    if (area == 0) {
        return 90;
    }
    
    CGPoint assPoint = [self getNeedPointForEndEdgeWithCenterPoint:centerPoint otherPoint:endPoint];
    
    CGFloat angle = [self calcuateAngleWithCenterPoint:centerPoint assisPoint:assPoint otherPoint:endPoint];
    
    if (angle == 180) {
        return 0;
    }
    if (angle > 90 && angle < 180) {
        return 180-angle;
    }
    return angle;
}

- (CGFloat)calcuateAngleWithCenterPoint:(CGPoint)centerPoint assisPoint:(CGPoint)assisPoint otherPoint:(CGPoint)otherPoint
{
    CGFloat p01 = sqrt(pow(centerPoint.x-assisPoint.x, 2) + pow(centerPoint.y-assisPoint.y, 2));
    
    CGFloat p02 = sqrt(pow(centerPoint.x-otherPoint.x, 2) + pow(centerPoint.y-otherPoint.y, 2));
    
    CGFloat p12 = sqrt(pow(assisPoint.x-otherPoint.x, 2) + pow(assisPoint.y-otherPoint.y, 2));
    
    CGFloat angle = acos((pow(p01, 2) + pow(p02, 2) - pow(p12, 2)) / (2*p01*p02));
    
    return (angle * 180/M_PI);
}
@end
