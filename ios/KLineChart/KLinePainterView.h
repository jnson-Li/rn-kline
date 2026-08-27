//
//  KLinePainterView.h
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KLineModel.h"
#import "KLineState.h"

NS_ASSUME_NONNULL_BEGIN

@interface KLinePainterView : UIView

@property(nonatomic,strong) NSArray<KLineModel *> *datas;

@property(nonatomic,assign) CGFloat scrollX;

@property(nonatomic,assign) CGFloat startX;

@property(nonatomic,assign) BOOL isLine;

@property(nonatomic,assign) CGFloat scaleX;

@property(nonatomic,assign) CGFloat baseCandleWidth;

@property(nonatomic,assign) BOOL isLongPress;

@property(nonatomic,assign) CGFloat longPressX;
@property(nonatomic,assign) CGFloat longPressY;

@property(nonatomic,assign) MainState mainState;

@property(nonatomic,assign) VolState volState;

@property(nonatomic,assign) SecondaryState secondaryState;

@property(nonatomic,assign) KLineDirection direction;

@property(nonatomic,assign) NSInteger gridColumns;

@property(nonatomic,assign) NSInteger gridRows;

@property(nonatomic,strong) UIColor* backgroundFillTopColor;

@property(nonatomic,strong) UIColor* backgroundFillBottomColor;

@property(nonatomic,strong) UIColor* timeLineColor;

@property(nonatomic,strong) UIColor* timeLineFillTopColor;

@property(nonatomic,strong) UIColor* timeLineFillBottomColor;

@property(nonatomic,strong) UIColor* timeLineEndPointColor;

@property(nonatomic,assign) CGFloat timeLineEndRadius;

@property(nonatomic,strong) UIColor* increaseColor;

@property(nonatomic,strong) UIColor* decreaseColor;

@property(nonatomic, strong) UIColor* priceLabelRightTextColor;
@property(nonatomic, strong) UIColor* priceLabelRightBackgroundColor;
@property(nonatomic, strong) UIColor* gridLineColor;
@property(nonatomic, strong) UIColor* ma1Color;
@property(nonatomic, strong) UIColor* ma2Color;
@property(nonatomic, strong) UIColor* ma3Color;
@property(nonatomic, strong) UIColor* volMa1Color;
@property(nonatomic, strong) UIColor* volMa2Color;


@property(nonatomic,strong) NSString* valueFormatter;

@property(nonatomic,strong) NSString* volFormatter;

@property(nonatomic,strong) NSString* dateTimeFormatter;

@property(nonatomic,strong) NSString* mainValueFormatter;

@property(nonatomic,assign) CGFloat legendMarginLeft;

/** 长按信息框标签，需 8 项：时间/开/高/低/收/涨跌额/涨跌幅/成交量 */
@property(nonatomic, copy) NSArray<NSString *> *selectedInfoLabels;

/** 是否隐藏长按信息框，默认 NO */
@property(nonatomic, assign) BOOL hideMarketInfoBox;

/** 该横坐标能否选中：越界或 isPad 占位 K 线不可选中 */
- (BOOL)canSelectAtX:(CGFloat)selectX;

@property(nonatomic,copy) void(^showInfoBlock)(KLineModel *model, BOOL isLeft);

- (instancetype)initWithFrame:(CGRect)frame
                        datas:(NSArray<KLineModel *> *)datas
                      scrollX:(CGFloat)scrollX
                       isLine:(BOOL)isLine
                       scaleX:(CGFloat)scaleX
                  isLongPress:(BOOL)isLongPress
                    mainState:(MainState)mainState
               secondaryState:(SecondaryState)secondaryState;

@end

NS_ASSUME_NONNULL_END
