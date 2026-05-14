//
//  BaseChartRenderer.m
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import "BaseChartRenderer.h"
#import "ChartStyle.h"
#import <math.h>


@implementation BaseChartRenderer

- (instancetype)initWithMaxValue:(CGFloat)maxValue
                        minValue:(CGFloat)minValue
                       chartRect:(CGRect)chartRect
                     candleWidth:(CGFloat)candleWidth
                      topPadding:(CGFloat)topPadding
{
    self = [super init];
    if (self) {
        self.maxValue = maxValue;
        self.minValue = minValue;
        self.chartRect = chartRect;
        self.candleWidth = candleWidth;
        self.topPadding = topPadding;
        self.legendMarginLeft = ChartStyle_legendMarginLeft;
        CGFloat diff = maxValue - minValue;
        if (!isfinite(diff) || fabs(diff) < 0.000001) {
            CGFloat padding = fabs(maxValue) * 0.01;
            if (padding < 1.0) {
                padding = 1.0;
            }
            self.maxValue = maxValue + padding;
            self.minValue = minValue - padding;
            diff = self.maxValue - self.minValue;
        }
        CGFloat drawableHeight = chartRect.size.height - topPadding;
        _scaleY = drawableHeight > 0 ? drawableHeight / diff : 0;
    }
    return self;
}

-(void)drawGrid:(CGContextRef)context
       gridRows:(NSUInteger)gridRows
  gridLineColor:(UIColor *)gridLineColor
     gridColums:(NSUInteger)gridColums {
    
}

-(void)drawRightText:(CGContextRef)context
            gridRows:(NSUInteger)gridRows
          gridColums:(NSUInteger)gridColums {

    
}

-(void)drawTopText:(CGContextRef)context
          curPoint:(KLineModel *)curPoint {
    
}
-(void)drawBg:(CGContextRef)context backgroundFillTopColor:(UIColor *)backgroundFillTopColor backgroundFillBottomColor:(UIColor *) backgroundFillBottomColor {
    CGContextClipToRect(context, _chartRect);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0,1};
    NSArray *colors = @[(__bridge id)[backgroundFillTopColor CGColor], (__bridge id)[backgroundFillBottomColor CGColor]];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef) colors, locations);
    CGColorSpaceRelease(colorSpace);
    CGPoint startPoint = CGPointMake(_chartRect.size.width, CGRectGetMinY(_chartRect));
    CGPoint endPoint = CGPointMake(_chartRect.size.width, CGRectGetMaxY(_chartRect));
//    CGPoint start = CGPointMake(_chartRect.size.width / 2, CGRectGetMinY(_chartRect));
//    CGPoint end = CGPointMake(_chartRect.size.width / 2, CGRectGetMaxY(_chartRect));
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextResetClip(context);
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}

-(void)drawChart:(CGContextRef)context
        lastPoit:(KLineModel *)lastPoint
        curPoint:(KLineModel *)curPoint
            curX:(CGFloat)curX {
    
}
-(void)drawLine:(CGContextRef)context
      lastValue:(CGFloat)lastValue
       curValue:(CGFloat)curValue
           curX:(CGFloat)curX
          color:(UIColor *)color {
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1);
    CGFloat x1 = curX;
    CGFloat y1 = [self getY:curValue];
    CGFloat x2 = curX + _candleWidth + ChartStyle_canldeMargin;
    CGFloat y2 = [self getY:lastValue];
    CGContextMoveToPoint(context, x1, y1);
    CGContextAddLineToPoint(context, x2, y2);
    CGContextDrawPath(context, kCGPathFillStroke);
}

-(void)drawText:(NSString *)text atPoint:(CGPoint)point fontSize:(CGFloat)size textColor:(UIColor *)color {
    [text drawAtPoint:point withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:size],NSForegroundColorAttributeName: color}];
}

-(CGFloat)getY:(CGFloat)value {
    return _scaleY * (_maxValue - value) + CGRectGetMinY(_chartRect) + _topPadding;
}

-(NSString *)volFormat:(CGFloat)value
          volFormatter:(NSString *)volFormatter{
    if (value > 10000 && value < 999999) {
         CGFloat d = value / 1000;
         return  [NSString stringWithFormat:[volFormatter stringByAppendingString: @"K"],d];
       } else if (value > 1000000) {
         CGFloat d = value / 1000000;
         return [NSString stringWithFormat:[volFormatter stringByAppendingString: @"M"],d];
       }
       return [NSString stringWithFormat:volFormatter,value];
    
}


- (void)drawChart:(nonnull CGContextRef)context lastPoit:(nonnull KLineModel *)lastPoint curPoint:(nonnull KLineModel *)curPoint curX:(CGFloat)curX timeLineColor:(nonnull UIColor *)timeLineColor timeLineFillTopColor:(nonnull UIColor *)timeLineFillTopColor timeLineFillBottomColor:(nonnull UIColor *)timeLineFillBottomColor timeLineEndPointColor:(nonnull UIColor *)timeLineEndPointColor timeLineEndRadius:(CGFloat)timeLineEndRadius increaseColor:(nonnull UIColor *)increaseColor decreaseColor:(nonnull UIColor *)decreaseColor {
}

- (void)drawRightText:(nonnull CGContextRef)context gridRows:(NSUInteger)gridRows gridColums:(NSUInteger)gridColums valueFormatter:(nonnull NSString *)valueFormatter volFormatter:(nonnull NSString *)volFormatter {
}

- (void)drawTopText:(nonnull CGContextRef)context curPoint:(nonnull KLineModel *)curPoint mainValueFormatter:(nonnull NSString *)mainValueFormatter volFormatter:(nonnull NSString *)volFormatter {
}

@end
