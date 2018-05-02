//
//  ViewController.m
//  Paint2
//
//  Created by IOS－winner on 16/3/30.
//  Copyright © 2016年 IOS－winner. All rights reserved.
//

#import "ViewController.h"
#import "PaintView.h"
#import "MBProgressHUD.h"
#import "TouchView.h"

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height
@interface ViewController ()<PaintViewDelegate>
@property (nonatomic,strong) PaintView *paintView;
@property (nonatomic,strong) NSMutableArray *mutableArray;
@property (nonatomic,strong) UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mutableArray = [NSMutableArray array];
    [_mutableArray addObject:NSStringFromCGPoint(CGPointMake(100, 100))];
    [_mutableArray addObject:NSStringFromCGPoint(CGPointMake(200, 100))];
    [_mutableArray addObject:NSStringFromCGPoint(CGPointMake(200, 200))];
    [_mutableArray addObject:NSStringFromCGPoint(CGPointMake(100, 200))];
    
    NSMutableArray *pointArr = [NSMutableArray array];
    [pointArr addObject:NSStringFromCGPoint(CGPointMake(100, 400))];
    [pointArr addObject:NSStringFromCGPoint(CGPointMake(200, 400))];
    [pointArr addObject:NSStringFromCGPoint(CGPointMake(200, 500))];
    [pointArr addObject:NSStringFromCGPoint(CGPointMake(100, 500))];
    
    _paintView = [[PaintView alloc]initWithFrame:self.view.frame];
    _paintView.allLines = _mutableArray;
    _paintView.allLines2 = pointArr;
    _paintView.delegate = self;
    [_paintView creatTouchView];
    [self.view addSubview:_paintView];
    
    _textView = [[UITextView alloc]initWithFrame:CGRectMake(0, HEIGHT - 60, WIDTH, 60)];
    _textView.backgroundColor = [UIColor grayColor];
    _textView.textColor = [UIColor blackColor];
    _textView.editable = NO;
    [self.view addSubview:_textView];
    
    NSMutableString *firstString = [NSMutableString string];
    for (int i = 0; i< _mutableArray.count; i++) {
        CGPoint point = CGPointFromString(_mutableArray[i]);
        NSString *string = [NSString stringWithFormat:@"(%.2f,%.2f) ",point.x,point.y];
        [firstString appendString:string];
    }
    
    NSMutableString *secondString = [NSMutableString string];
    for (int i = 0; i< pointArr.count; i++) {
        CGPoint point = CGPointFromString(pointArr[i]);
        NSString *string = [NSString stringWithFormat:@"(%.2f,%.2f) ",point.x,point.y];
        [secondString appendString:string];
    }
    NSString *sumString = [NSString stringWithFormat:@"%@\n%@",firstString,secondString];
    _textView.text = sumString;
    
    
    NSLog(@"hello world");
}
- (void)addProgressHUDWithTitle:(NSString *)lableText
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = lableText;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:1];
}

- (void)textViewText:(NSString *)text
{
    _textView.text = text;
}

@end
