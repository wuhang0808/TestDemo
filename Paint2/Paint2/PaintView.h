//
//  PaintView.h
//  Paint2
//
//  Created by IOS－winner on 16/3/30.
//  Copyright © 2016年 IOS－winner. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PaintViewDelegate <NSObject>

- (void)addProgressHUDWithTitle:(NSString *)lableText;

-(void)textViewText:(NSString *)text;

@end
@interface PaintView : UIView

@property (nonatomic,strong) NSMutableArray *allLines;
@property (nonatomic,strong) NSMutableArray *allLines2;
@property (nonatomic,strong) NSMutableArray *lineMutableArray;
@property (nonatomic,strong) NSMutableArray *distanceArray;

@property (nonatomic,strong) NSMutableArray *lineMutableArray2;
@property (nonatomic,strong) NSMutableArray *distanceArray2;

@property (nonatomic,assign) id<PaintViewDelegate>delegate;

-(void)creatTouchView;

- (void)orignList;
@end
