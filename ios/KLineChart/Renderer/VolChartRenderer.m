//
//  VolChartRenderer.m
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import "VolChartRenderer.h"
#import "ChartStyle.h"
#import "NSString+Rect.h"

@implementation VolChartRenderer

- (void)drawGrid:(CGContextRef)context gridRows:(NSUInteger)gridRows  gridColums:(NSUInteger)gridColums {
    CGContextSetStrokeColorWithColor(context, ChartColors_gridColor.CGColor);
    CGContextSetLineWidth(context, 0.5);
    CGFloat columsSpace = self.chartRect.size.width / (CGFloat)(gridColums);
    for (int index = 0;  index < gridColums; index++) {
        CGContextMoveToPoint(context, index * columsSpace, 0);
        CGContextAddLineToPoint(context, index * columsSpace, CGRectGetMaxY(self.chartRect));
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    CGContextAddRect(context, self.chartRect);
    CGContextDrawPath(context, kCGPathStroke);
    
}
- (void)drawChart:(CGContextRef)context
         lastPoit:(KLineModel *)lastPoint
         curPoint:(KLineModel *)curPoint
             curX:(CGFloat)curX
    timeLineColor:(UIColor *)timeLineColor
timeLineFillTopColor:(UIColor *) timeLineFillTopColor
timeLineFillBottomColor:(UIColor *) timeLineFillBottomColor
timeLineEndPointColor:(UIColor *) timeLineEndPointColor
timeLineEndRadius:(CGFloat) timeLineEndRadius
    increaseColor:(UIColor *) increaseColor
    decreaseColor:(UIColor *) decreaseColor
{
    [self drawVolChat:context curPoint:curPoint curX:curX increaseColor:increaseColor decreaseColor:decreaseColor];
    if(lastPoint != nil){
        if(curPoint.MA5Volume != 0) {
            [self drawLine:context lastValue:lastPoint.MA5Volume curValue:curPoint.MA5Volume curX:curX color:self.volMa1Color ?: [UIColor colorWithCGColor:ChartColors_ma5Color.CGColor]];
        }
        if(curPoint.MA10Volume != 0) {
            [self drawLine:context lastValue:lastPoint.MA10Volume curValue:curPoint.MA10Volume curX:curX color:self.volMa2Color ?: [UIColor colorWithCGColor:ChartColors_ma10Color.CGColor]];
        }
    }
}

- (void)drawVolChat:(CGContextRef)context
           curPoint:(KLineModel *)curPoint
               curX:(CGFloat)curX
      increaseColor:(UIColor *) increaseColor
      decreaseColor:(UIColor *) decreaseColor
{
    // 成交量为 0 不画柱：可见区间全是 0 量 K 线时（新币上市前的接口占位区），
    // BaseChartRenderer 的 diff==0 兜底会把量程设为 [-1,+1]，getY(0) 落在面板中部，
    // 每根 0 量柱都会被画成半高红柱，看起来像一堵假成交量墙。0 量本就无柱可画，直接跳过。
    if (curPoint.vol == 0) {
        return;
    }
    CGFloat top = [self getY:curPoint.vol];
    CGContextSetLineWidth(context, self.candleWidth);
    // 对齐安卓 VolumeRenderer：close >= open 记涨色（平盘/十字星 close==open 也算涨，用涨色）。
    // iOS 原用 close > open（严格），导致 close==open 的平盘量柱落到跌色（红），与安卓相反——
    // 新币上市初期大量 open==close 的平盘 K 线，成交量柱在 iOS 上全被画红，安卓却是绿。
    if(curPoint.close >= curPoint.open) {
        CGContextSetStrokeColorWithColor(context, increaseColor.CGColor);
    } else {
        CGContextSetStrokeColorWithColor(context, decreaseColor.CGColor);
    }
    CGContextMoveToPoint(context, curX, CGRectGetMaxY(self.chartRect));
    CGContextAddLineToPoint(context, curX, top);
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawTopText:(CGContextRef)context curPoint:(KLineModel *)curPoint
 mainValueFormatter:(NSString *)mainValueFormatter
       volFormatter:(NSString *)volFormatter{
    NSMutableAttributedString *topAttributeText = [[NSMutableAttributedString alloc] init];
    {
        NSString *str = [NSString stringWithFormat:@"VOL:%@   ", [self volFormat:curPoint.vol volFormatter:volFormatter]];
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:ChartStyle_defaultTextSize],NSForegroundColorAttributeName: ChartColors_volColor}];
        [topAttributeText appendAttributedString:attr];
    }
    {
        NSString *str = [NSString stringWithFormat:@"MA5:%@    ", [self volFormat:curPoint.MA5Volume volFormatter:volFormatter]];
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:ChartStyle_defaultTextSize],NSForegroundColorAttributeName: self.volMa1Color ?: [UIColor colorWithCGColor:ChartColors_ma5Color.CGColor]}];
        [topAttributeText appendAttributedString:attr];
    }
   {
        NSString *str = [NSString stringWithFormat:@"MA10:%@   ",[self volFormat:curPoint.MA10Volume volFormatter:volFormatter]];
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:ChartStyle_defaultTextSize],NSForegroundColorAttributeName: self.volMa2Color ?: [UIColor colorWithCGColor:ChartColors_ma10Color.CGColor]}];
        [topAttributeText appendAttributedString:attr];
    }
    [topAttributeText drawAtPoint:CGPointMake(self.legendMarginLeft, CGRectGetMinY(self.chartRect))];
}

- (void)drawRightText:(CGContextRef)context gridRows:(NSUInteger)gridRows gridColums:(NSUInteger)gridColums
       valueFormatter:(NSString *)valueFormatter
       volFormatter:(NSString *)volFormatter{
       NSString *text = [self volFormat:self.maxValue volFormatter:volFormatter];
       CGRect rect = [text getRectWithFontSize:ChartStyle_reightTextSize];

       CGFloat rightPadding = 6.0; // 右侧间距，可按需调整
       CGFloat textX = CGRectGetMinX(self.chartRect) + CGRectGetWidth(self.chartRect) - rect.size.width - rightPadding;
       CGFloat textY = CGRectGetMinY(self.chartRect); // 保持原来的垂直位置

       [self drawText:text atPoint:CGPointMake(textX, textY) fontSize:ChartStyle_reightTextSize textColor:ChartColors_reightTextColor];
}

@end
