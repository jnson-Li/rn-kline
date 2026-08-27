//
//  KLinePainterView.m
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import "KLinePainterView.h"
#import "MainChartRenderer.h"
#import "VolChartRenderer.h"
#import "SecondaryChartRenderer.h"
#import "ChartStyle.h"
#import "NSString+Rect.h"
#import <math.h> // isnan：MA 未计算态用 NAN 占位

/// 见 ChartStyle.h：图表配色本来只有深色一套写死的 #define，这里存运行期主题标记。
BOOL gKLineChartLightTheme = NO;

/// 用背景色的感知亮度判断浅色主题（0.5 为界，和 W3C 的相对亮度近似公式一致）。
static BOOL KLineColorIsLight(UIColor *color) {
    if (color == nil) { return NO; }
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) { return NO; }
    return (0.299 * r + 0.587 * g + 0.114 * b) > 0.5;
}

@interface KLinePainterView()
@property(nonatomic,assign) CGFloat displayHeight;
@property(nonatomic,strong) MainChartRenderer *mainRenderer;
@property(nonatomic,strong) VolChartRenderer *volRenderer;
@property(nonatomic,strong) SecondaryChartRenderer *seconderyRender;

@property(nonatomic,assign) CGRect mainRect;
@property(nonatomic,assign) CGRect volRect;
@property(nonatomic,assign) CGRect secondaryRect;
@property(nonatomic,assign) CGRect dateRect;

@property(nonatomic,assign) NSUInteger startIndex;
@property(nonatomic,assign) NSUInteger stopIndex;

@property(nonatomic,assign) NSUInteger mMainMaxIndex;
@property(nonatomic,assign) NSUInteger mMainMinIndex;

@property(nonatomic,assign) CGFloat mMainMaxValue;
@property(nonatomic,assign) CGFloat mMainMinValue;

@property(nonatomic,assign) CGFloat mVolMaxValue;
@property(nonatomic,assign) CGFloat mVolMinValue;

@property(nonatomic,assign) CGFloat mSecondaryMaxValue;
@property(nonatomic,assign) CGFloat mSecondaryMinValue;

@property(nonatomic,assign) CGFloat mMainHighMaxValue;
@property(nonatomic,assign) CGFloat mMainLowMinValue;

@property(nonatomic,assign) CGFloat candleWidth;

@end

@implementation KLinePainterView

- (void)setDatas:(NSArray<KLineModel *> *)datas {
    _datas = datas;
    [self setNeedsDisplay];
}

-(void)setScrollX:(CGFloat)scrollX {
    _scrollX = scrollX;
    [self setNeedsDisplay];
}

-(void)setIsLine:(BOOL)isLine {
    _isLine = isLine;
     [self setNeedsDisplay];
}
-(void)setScaleX:(CGFloat)scaleX {
    _scaleX = scaleX;
    CGFloat baseCandleWidth = self.baseCandleWidth > 0 ? self.baseCandleWidth : ChartStyle_candleWidth;
    self.candleWidth = scaleX * baseCandleWidth;
    [self setNeedsDisplay];
}

- (void)setBaseCandleWidth:(CGFloat)baseCandleWidth {
    if (baseCandleWidth <= 0) {
        return;
    }
    _baseCandleWidth = baseCandleWidth;
    self.candleWidth = self.scaleX * baseCandleWidth;
    [self setNeedsDisplay];
}
- (void)setIsLongPress:(BOOL)isLongPress {
    _isLongPress = isLongPress;
    [self setNeedsDisplay];
}

-(void)setMainState:(MainState)mainState {
    _mainState = mainState;
    [self setNeedsDisplay];
}

- (void)setSecondaryState:(SecondaryState)secondaryState {
    _secondaryState = secondaryState;
    [self setNeedsDisplay];
}

-(void)setGridColumns:(NSInteger)gridColumns {
  _gridColumns = gridColumns;
  [self setNeedsDisplay];
}

-(void)setGridRows:(NSInteger)gridRows {
  _gridRows = gridRows;
  [self setNeedsDisplay];
}

-(void)setBackgroundFillTopColor:(UIColor *)backgroundFillTopColor{
  _backgroundFillTopColor = backgroundFillTopColor;
  // 背景色是 RN 侧唯一一个「一定会下发」的主题信号，用它反推浅色/深色，
  // 让 ChartStyle.h 里的 ThemeColor() 宏跟着切换（坐标轴文字、十字线、最高最低价标签等）。
  gKLineChartLightTheme = KLineColorIsLight(backgroundFillTopColor);
  [self setNeedsDisplay];
}

-(void)setBackgroundFillBottomColor:(UIColor *)backgroundFillBottomColor{
  _backgroundFillBottomColor = backgroundFillBottomColor;
  [self setNeedsDisplay];
}

-(void)setTimeLineColor:(UIColor *)timeLineColor{
  _timeLineColor = timeLineColor;
  [self setNeedsDisplay];
}

-(void)setTimeLineFillTopColor:(UIColor *)timeLineFillTopColor{
  _timeLineFillTopColor = timeLineFillTopColor;
  [self setNeedsDisplay];
}

-(void)setTimeLineFillBottomColor:(UIColor *)timeLineFillBottomColor{
  _timeLineFillBottomColor = timeLineFillBottomColor;
  [self setNeedsDisplay];
}

-(void)setTimeLineEndPointColor:(UIColor *)timeLineEndPointColor{
  _timeLineEndPointColor = timeLineEndPointColor;
  [self setNeedsDisplay];
}

-(void)setTimeLineEndRadius:(CGFloat)timeLineEndRadius{
  _timeLineEndRadius = timeLineEndRadius;
  [self setNeedsDisplay];
}

-(void)setIncreaseColor:(UIColor *)increaseColor{
  _increaseColor = increaseColor;
  [self setNeedsDisplay];
}

-(void)setDecreaseColor:(UIColor *)decreaseColor{
  _decreaseColor = decreaseColor;
  [self setNeedsDisplay];
}

-(void)setPriceLabelRightTextColor:(UIColor *)priceLabelRightTextColor{
  _priceLabelRightTextColor = priceLabelRightTextColor;
  [self setNeedsDisplay];
}

-(void)setPriceLabelRightBackgroundColor:(UIColor *)priceLabelRightBackgroundColor{
  _priceLabelRightBackgroundColor = priceLabelRightBackgroundColor;
  [self setNeedsDisplay];
}

-(void)setGridLineColor:(UIColor *)gridLineColor{
    _gridLineColor = gridLineColor;
  [self setNeedsDisplay];
}

-(void)setMa1Color:(UIColor *)ma1Color{
  _ma1Color = ma1Color;
  [self setNeedsDisplay];
}

-(void)setMa2Color:(UIColor *)ma2Color{
  _ma2Color = ma2Color;
  [self setNeedsDisplay];
}

-(void)setMa3Color:(UIColor *)ma3Color{
  _ma3Color = ma3Color;
  [self setNeedsDisplay];
}

-(void)setVolMa1Color:(UIColor *)volMa1Color{
  _volMa1Color = volMa1Color;
  [self setNeedsDisplay];
}

-(void)setVolMa2Color:(UIColor *)volMa2Color{
  _volMa2Color = volMa2Color;
  [self setNeedsDisplay];
}

-(void)setValueFormatter:(NSString *)valueFormatter{
  _valueFormatter = valueFormatter;
  [self setNeedsDisplay];
}

-(void)setVolFormatter:(NSString *)volFormatter{
  _volFormatter = volFormatter;
  [self setNeedsDisplay];
}

-(void)setDateTimeFormatter:(NSString *)dateTimeFormatter{
  _dateTimeFormatter  = dateTimeFormatter;
  [self setNeedsDisplay];
}

-(void)setMainValueFormatter:(NSString *)mainValueFormatter{
  _mainValueFormatter = mainValueFormatter;
  [self setNeedsDisplay];
}

- (void)setLegendMarginLeft:(CGFloat)legendMarginLeft {
    _legendMarginLeft = legendMarginLeft;
    CGFloat resolved = legendMarginLeft > 0 ? legendMarginLeft : ChartStyle_legendMarginLeft;
    if (_mainRenderer != nil) {
        _mainRenderer.legendMarginLeft = resolved;
    }
    if (_volRenderer != nil) {
        _volRenderer.legendMarginLeft = resolved;
    }
    if (_seconderyRender != nil) {
        _seconderyRender.legendMarginLeft = resolved;
    }
    [self setNeedsDisplay];
}

- (instancetype)initWithFrame:(CGRect)frame
                        datas:(NSArray<KLineModel *> *)datas
                      scrollX:(CGFloat)scrollX
                       isLine:(BOOL)isLine
                       scaleX:(CGFloat)scaleX
                  isLongPress:(BOOL)isLongPress
                    mainState:(MainState)mainState
               secondaryState:(SecondaryState)secondaryState
{
    self = [super initWithFrame:frame];
    if (self) {
        _baseCandleWidth = ChartStyle_candleWidth;
        self.datas = datas;
        self.scrollX = scrollX;
        self.isLine = isLine;
        self.scaleX = scaleX;
        self.isLongPress = isLongPress;
        self.mainState = mainState;
        self.secondaryState = secondaryState;
        self.candleWidth = self.baseCandleWidth * self.scaleX;
        self.gridColumns = ChartStyle_gridColumns;
        self.gridRows = ChartStyle_gridRows;
        self.backgroundFillTopColor = [UIColor rgb_r:0x0E g:0x0E b:0x0E alpha:1];
        self.backgroundFillBottomColor = [UIColor rgb_r:0x0E g:0x0E b:0x0E alpha:1];
        self.timeLineColor = [UIColor colorWithCGColor:ChartColors_kLineColor.CGColor];
        self.timeLineFillTopColor = [UIColor rgb_r:0x4c g:0x86 b:0xCD alpha:1];
        self.timeLineFillBottomColor = [UIColor rgb_r:0x00 g:0x00 b:0x00 alpha:0];
        self.timeLineEndPointColor = [UIColor colorWithCGColor:ChartColors_realTimeLineColor.CGColor];
        self.timeLineEndRadius = 2.0;
        self.increaseColor = [UIColor colorWithCGColor:ChartColors_upColor.CGColor];
        self.decreaseColor = [UIColor colorWithCGColor:ChartColors_dnColor.CGColor];
        self.priceLabelRightTextColor = [UIColor colorWithCGColor:ChartColors_rightRealTimeTextColor.CGColor];
        self.priceLabelRightBackgroundColor = [UIColor colorWithCGColor:ChartColors_realTimeBgColor.CGColor];
        self.gridLineColor = [UIColor colorWithCGColor:ChartColors_gridColor.CGColor];
        self.ma1Color = [UIColor colorWithCGColor:ChartColors_ma5Color.CGColor];
        self.ma2Color = [UIColor colorWithCGColor:ChartColors_ma10Color.CGColor];
        self.ma3Color = [UIColor colorWithCGColor:ChartColors_ma30Color.CGColor];
        self.volMa1Color = [UIColor colorWithCGColor:ChartColors_ma5Color.CGColor];
        self.volMa2Color = [UIColor colorWithCGColor:ChartColors_ma10Color.CGColor];
        self.valueFormatter = @"%.03f";
        // JS 不再下发 volFormatter，原生默认必须与 Android VolValueFormatter("%.3f") 一致
        self.volFormatter = @"%.3f";
        self.dateTimeFormatter = @"MM-dd HH:mm";
        self.mainValueFormatter = @"%.03f";
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    _displayHeight = rect.size.height - ChartStyle_topPadding - ChartStyle_bottomDateHigh;
    CGContextRef context = UIGraphicsGetCurrentContext();
    if(context != NULL) {
        [self divisionRect];
        [self calculateValue];
        [self initRenderer];
        [self drawBgColor:context rect:rect];
        [self drawGrid:context];
        if(self.datas.count == 0) { return; }
        [self drawChart:context];
        [self drawRightText:context];
        [self drawDate:context];
        [self drawMaxAndMin:context];
        if(_isLongPress) {
            [self drawLongPressCrossLine:context];
        } else {
            [self drawTopText:context curPoint:self.datas.firstObject];
        }
        [self drawRealTimePrice:context];
    }
}

-(void)divisionRect {
    CGFloat mainHeight = self.displayHeight * 0.6;
    CGFloat volHeigt = self.displayHeight * 0.2;
    CGFloat secondaryHeight = self.displayHeight * 0.2;
    if(_volState == VolStateNONE && _secondaryState == SecondaryStateNONE) {
        mainHeight = self.displayHeight;
    } else if (_volState == VolStateNONE || _secondaryState == SecondaryStateNONE) {
        mainHeight = self.displayHeight * 0.8;
    }
    self.mainRect = CGRectMake(0, ChartStyle_topPadding, self.frame.size.width, mainHeight);
    if(_direction == KLineDirectionHorizontal) {
        self.dateRect = CGRectMake(0, CGRectGetMaxY(_mainRect), self.frame.size.width, ChartStyle_bottomDateHigh);
        if(_volState != VolStateNONE) {
            self.volRect = CGRectMake(0, CGRectGetMaxY(_dateRect), self.frame.size.width, volHeigt);
        }
        if(_secondaryState != SecondaryStateNONE) {
            CGFloat y =  CGRectGetMaxY(_volRect);
            self.secondaryRect = CGRectMake(0, y, self.frame.size.width, secondaryHeight);
        }
    } else {
       
        if(_volState != VolStateNONE) {
            self.volRect = CGRectMake(0, CGRectGetMaxY(_mainRect), self.frame.size.width, volHeigt);
        }
        if(_secondaryState != SecondaryStateNONE) {
            CGFloat y =  CGRectGetMaxY(_volRect);
            self.secondaryRect = CGRectMake(0, y, self.frame.size.width, secondaryHeight);
        }
        self.dateRect = CGRectMake(0,  self.displayHeight + ChartStyle_topPadding, self.frame.size.width, ChartStyle_bottomDateHigh);
    }
}

-(void)calculateValue {
    if(self.datas.count == 0) { return; }
    CGFloat itemWidth = _candleWidth + ChartStyle_canldeMargin;
    if(_scrollX <= 0) {
        self.startX = -_scrollX;
        self.startIndex = 0;
    } else {
        CGFloat start = _scrollX / itemWidth;
        CGFloat offsetX = 0;
        if(floor(start) == ceil(start)) {
            _startIndex = (NSUInteger)floor(start);
        } else {
            _startIndex = (NSUInteger)(floor(_scrollX / itemWidth));
            offsetX = (CGFloat)_startIndex * itemWidth - _scrollX;
        }
        if (_startIndex >= self.datas.count) {
            _startIndex = self.datas.count - 1;
            offsetX = (CGFloat)_startIndex * itemWidth - _scrollX;
        }
        self.startX = offsetX;
    }
    CGFloat visibleWidth = MAX(self.frame.size.width - self.startX + itemWidth, 0);
    NSUInteger diffIndex = (NSUInteger)ceil(visibleWidth / itemWidth);
    _stopIndex = MIN(_startIndex + diffIndex, self.datas.count - 1);
    _mMainMaxValue = -CGFLOAT_MAX;
    _mMainMinValue = CGFLOAT_MAX;
    _mMainHighMaxValue = -CGFLOAT_MAX;
    _mMainLowMinValue = CGFLOAT_MAX;
    _mVolMaxValue = -CGFLOAT_MAX;
    _mVolMinValue = CGFLOAT_MAX;
    _mSecondaryMaxValue = -CGFLOAT_MAX;
    _mSecondaryMinValue = CGFLOAT_MAX;
    for (NSUInteger index = _startIndex; index <= _stopIndex; index++) {
        KLineModel *item = self.datas[index];
        [self getMianMaxMinValue:item i:index];
        [self getVolMaxMinValue:item];
        [self getSecondaryMaxMinValue:item];
    }
//    NSLog(@"startIndex=%ld,endIndex=%ld",_startIndex, _stopIndex);
}

-(void)getMianMaxMinValue:(KLineModel *)item i:(NSUInteger)i {
    if (_isLine == true) {
      _mMainMaxValue = MAX(_mMainMaxValue, item.close);
      _mMainMinValue = MIN(_mMainMinValue, item.close);
    } else {
        CGFloat maxPrice = item.high;
        CGFloat minPrice = item.low;
        if (_mainState == MainStateMA) {
        // 用 isnan 判断「未计算」：算出来的 MA=0 要计入量程；且 NAN 一旦进 MAX/MIN 会把量程整段污染成 NAN
        if(!isnan(item.MA5Price)){
          maxPrice = MAX(maxPrice, item.MA5Price);
          minPrice = MIN(minPrice, item.MA5Price);
        }
        if(!isnan(item.MA10Price)){
          maxPrice = MAX(maxPrice, item.MA10Price);
          minPrice = MIN(minPrice, item.MA10Price);
        }
        if(!isnan(item.MA20Price)){
          maxPrice = MAX(maxPrice, item.MA20Price);
          minPrice = MIN(minPrice, item.MA20Price);
        }
        if(!isnan(item.MA30Price)){
          maxPrice = MAX(maxPrice, item.MA30Price);
          minPrice = MIN(minPrice, item.MA30Price);
        }
        } else if (_mainState == MainStateBOLL) {
        if(item.up != 0){
          maxPrice = MAX(item.up, item.high);
        }
        if(item.dn != 0){
          minPrice = MIN(item.dn, item.low);
        }
      }
      _mMainMaxValue = MAX(_mMainMaxValue, maxPrice);
      _mMainMinValue = MIN(_mMainMinValue, minPrice);

      if (_mMainHighMaxValue < item.high) {
        _mMainHighMaxValue = item.high;
        _mMainMaxIndex = i;
      }
      if (_mMainLowMinValue > item.low) {
        _mMainLowMinValue = item.low;
        _mMainMinIndex = i;
      }
    }
}
-(void)getVolMaxMinValue:(KLineModel *)item {
    _mVolMaxValue = MAX(_mVolMaxValue, MAX(item.vol, MAX(item.MA5Volume, item.MA10Volume)));
    _mVolMinValue = MIN(_mVolMinValue, MIN(item.vol, MIN(item.MA5Volume, item.MA10Volume)));
}

-(void)getSecondaryMaxMinValue:(KLineModel *)item {
    if (_secondaryState == SecondaryStateMacd) {
      // 预热区 DIF/DEA 为 NAN，必须逐项 isnan 跳过，否则 NAN 会污染 MACD 副图的自动缩放范围。
      // macd 始终为实数（预热区为 0），保证 MAX/MIN 恒有有效参与项，不会出现全 NAN 窗口。
      if (!isnan(item.macd)) {
        _mSecondaryMaxValue = MAX(_mSecondaryMaxValue, item.macd);
        _mSecondaryMinValue = MIN(_mSecondaryMinValue, item.macd);
      }
      if (!isnan(item.dif)) {
        _mSecondaryMaxValue = MAX(_mSecondaryMaxValue, item.dif);
        _mSecondaryMinValue = MIN(_mSecondaryMinValue, item.dif);
      }
      if (!isnan(item.dea)) {
        _mSecondaryMaxValue = MAX(_mSecondaryMaxValue, item.dea);
        _mSecondaryMinValue = MIN(_mSecondaryMinValue, item.dea);
      }
    } else if (_secondaryState == SecondaryStateKDJ) {
      _mSecondaryMaxValue = MAX(_mSecondaryMaxValue, MAX(item.k, MAX(item.d, item.j)));
      _mSecondaryMinValue = MIN(_mSecondaryMinValue, MIN(item.k, MIN(item.d, item.j)));
    } else if (_secondaryState == SecondaryStateRSI) {
      _mSecondaryMaxValue = MAX(_mSecondaryMaxValue, item.rsi);
      _mSecondaryMinValue = MIN(_mSecondaryMinValue, item.rsi);
    } else {
      _mSecondaryMaxValue = MAX(_mSecondaryMaxValue, item.r);
      _mSecondaryMinValue = MIN(_mSecondaryMinValue, item.r);
    }
}

-(void)initRenderer {
    _mainRenderer = [[MainChartRenderer alloc] initWithMaxValue:_mMainMaxValue minValue:_mMainMinValue chartRect:_mainRect candleWidth:_candleWidth topPadding:ChartStyle_topPadding isLine:_isLine state:_mainState];
    _mainRenderer.legendMarginLeft = _legendMarginLeft > 0 ? _legendMarginLeft : ChartStyle_legendMarginLeft;
    _mainRenderer.ma1Color = _ma1Color;
    _mainRenderer.ma2Color = _ma2Color;
    _mainRenderer.ma3Color = _ma3Color;
    if(_volState != VolStateNONE) {
        _volRenderer = [[VolChartRenderer alloc] initWithMaxValue:_mVolMaxValue minValue:_mVolMinValue chartRect:_volRect candleWidth:_candleWidth topPadding:ChartStyle_childPadding];
        _volRenderer.legendMarginLeft = _legendMarginLeft > 0 ? _legendMarginLeft : ChartStyle_legendMarginLeft;
        _volRenderer.volMa1Color = _volMa1Color;
        _volRenderer.volMa2Color = _volMa2Color;
    }
    if(_secondaryState != SecondaryStateNONE) {
        _seconderyRender = [[SecondaryChartRenderer alloc] initWithMaxValue:_mSecondaryMaxValue minValue:_mSecondaryMinValue chartRect:_secondaryRect candleWidth:_candleWidth topPadding:ChartStyle_childPadding state:_secondaryState];
        _seconderyRender.legendMarginLeft = _legendMarginLeft > 0 ? _legendMarginLeft : ChartStyle_legendMarginLeft;
    }
}

-(void)drawBgColor:(CGContextRef)context rect:(CGRect)rect {
     CGContextSetFillColorWithColor(context, [_backgroundFillTopColor CGColor]);
     CGContextFillRect(context, rect);
      [_mainRenderer drawBg:context backgroundFillTopColor:_backgroundFillTopColor backgroundFillBottomColor:_backgroundFillBottomColor];
      if(_volRenderer != nil) {
          [_volRenderer drawBg:context backgroundFillTopColor:_backgroundFillTopColor backgroundFillBottomColor:_backgroundFillBottomColor];
      }
      if(_seconderyRender != nil) {
          [_seconderyRender drawBg:context backgroundFillTopColor:_backgroundFillTopColor backgroundFillBottomColor:_backgroundFillBottomColor];
      }
}
-(void)drawGrid:(CGContextRef)context {
    [_mainRenderer drawGrid:context gridRows:_gridRows gridLineColor:_gridLineColor gridColums:_gridColumns];
   if(_volRenderer != nil) {
       [_volRenderer drawGrid:context gridRows:_gridRows gridLineColor:_gridLineColor gridColums:_gridColumns];
   }
   if(_seconderyRender != nil) {
       [_seconderyRender drawGrid:context gridRows:_gridRows gridLineColor:_gridLineColor gridColums:_gridColumns];
   }
     CGContextSetLineWidth(context, 1);
    CGContextAddRect(context, self.bounds);
    CGContextDrawPath(context, kCGPathStroke);
}
-(void)drawChart:(CGContextRef)context {
    for (NSUInteger index = _startIndex; index <= _stopIndex; index++) {
        KLineModel *curPoint = self.datas[index];
        if (curPoint.isPad) { continue; }
        CGFloat itemWidth = _candleWidth + ChartStyle_canldeMargin;
        CGFloat curX = (CGFloat)(index - _startIndex) * itemWidth + _startX;
        CGFloat _curX = self.frame.size.width - curX - _candleWidth / 2;
        KLineModel *lastPoint;
        if(index != _startIndex) {
            lastPoint = self.datas[index - 1];
        }
        [_mainRenderer drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX timeLineColor:_timeLineColor timeLineFillTopColor:_timeLineFillTopColor timeLineFillBottomColor:_timeLineFillBottomColor timeLineEndPointColor:_timeLineEndPointColor timeLineEndRadius:_timeLineEndRadius increaseColor:_increaseColor decreaseColor:_decreaseColor];
        if(_volRenderer != nil) {
            [_volRenderer drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX timeLineColor:_timeLineColor timeLineFillTopColor:_timeLineFillTopColor timeLineFillBottomColor:_timeLineFillBottomColor timeLineEndPointColor:_timeLineEndPointColor timeLineEndRadius:_timeLineEndRadius increaseColor:_increaseColor decreaseColor:_decreaseColor];
        }
        if(_seconderyRender != nil) {
            [_seconderyRender drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX timeLineColor:_timeLineColor timeLineFillTopColor:_timeLineFillTopColor timeLineFillBottomColor:_timeLineFillBottomColor timeLineEndPointColor:_timeLineEndPointColor timeLineEndRadius:_timeLineEndRadius increaseColor:_increaseColor decreaseColor:_decreaseColor];
        }
    }
}
-(void)drawRightText:(CGContextRef)context {
    [_mainRenderer drawRightText:context gridRows:_gridRows gridColums:_gridColumns valueFormatter:_valueFormatter volFormatter:_volFormatter];
    if(_volRenderer != nil) {
        [_volRenderer drawRightText:context gridRows:_gridRows gridColums:_gridColumns valueFormatter:_valueFormatter volFormatter:_volFormatter];
    }
    if(_seconderyRender != nil) {
        [_seconderyRender drawRightText:context gridRows:_gridRows gridColums:_gridColumns valueFormatter:_valueFormatter volFormatter:_volFormatter];
    }
}
-(void)drawDate:(CGContextRef)context {
    CGFloat cloumSpace = self.frame.size.width / (CGFloat)_gridColumns;
    for (int i = 0; i < _gridColumns; i++) {
        NSUInteger index = [self calculateIndexWithSelectX: cloumSpace * (CGFloat)i];
        if([self outRangeIndex:index]) { continue; }
        KLineModel *data = self.datas[index];
        NSString *dataStr = [self calculateDateText:data.id];
        CGRect rect = [dataStr getRectWithFontSize:ChartStyle_bottomDatefontSize];
        CGFloat y = CGRectGetMinY(self.dateRect) + (ChartStyle_bottomDateHigh - rect.size.height) / 2;
        CGFloat textX = cloumSpace * i - rect.size.width / 2;
        if (textX < 0 || textX + rect.size.width > self.frame.size.width) {
            continue;
        }
        [self.mainRenderer drawText:dataStr atPoint:CGPointMake(textX, y) fontSize:ChartStyle_bottomDatefontSize textColor:ChartColors_bottomDateTextColor];
    }
}
-(void)drawMaxAndMin:(CGContextRef)context {
    if(_isLine) { return; }
    CGFloat itemWidth = self.candleWidth + ChartStyle_canldeMargin;
    CGFloat y1 = [self.mainRenderer getY:_mMainHighMaxValue];
    CGFloat x1 = self.frame.size.width - ((self.mMainMaxIndex - self.startIndex) * itemWidth + self.startX + self.candleWidth / 2);
    NSString *str = @"——";
    if(x1 < self.frame.size.width / 2) {
      NSString *text = [NSString stringWithFormat:[str stringByAppendingString: _mainValueFormatter],_mMainHighMaxValue];
        CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x1, y1 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:_priceLabelRightTextColor];

    } else {
        NSString *text = [NSString stringWithFormat:[_mainValueFormatter stringByAppendingString: str],_mMainHighMaxValue];
       CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x1 - rect.size.width, y1 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:_priceLabelRightTextColor];

    }
    
    CGFloat y2 = [self.mainRenderer getY:_mMainLowMinValue];
    CGFloat x2 = self.frame.size.width - ((self.mMainMinIndex - self.startIndex) * itemWidth + self.startX + self.candleWidth / 2);
    if(x2 < self.frame.size.width / 2) {
        NSString *text = [NSString stringWithFormat:[str stringByAppendingString: _mainValueFormatter],_mMainLowMinValue];
        CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x2, y2 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:_priceLabelRightTextColor];

    } else {
        NSString *text = [NSString stringWithFormat:[_mainValueFormatter stringByAppendingString: str],_mMainLowMinValue];
       CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x2 - rect.size.width, y2 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:_priceLabelRightTextColor];

    }
}
-(void)drawLongPressCrossLine:(CGContextRef)context {
    NSUInteger index = [self calculateIndexWithSelectX:self.longPressX];
    if([self outRangeIndex:index]) { return; }
    KLineModel *point = self.datas[index];
    if (point.isPad) { return; }
    // 索引仍用于详情数据和时间，但十字线 X/Y 使用真实触点，不再吸附到 K 线收盘价。
    CGFloat curX = MIN(MAX(self.longPressX, 0), self.frame.size.width);
    CGFloat y = MIN(MAX(self.longPressY, 0), self.frame.size.height);
    CGFloat dashLengths[] = {4.0, 3.0};
    CGContextSetLineDash(context, 0, dashLengths, 2);
    CGContextSetStrokeColorWithColor(context, ChartColors_crossLineColor.CGColor);
    CGContextSetLineWidth(context, 0.5);
    CGContextMoveToPoint(context, curX, 0);
    CGContextAddLineToPoint(context, curX, self.frame.size.height);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextSetStrokeColorWithColor(context, ChartColors_crossLineColor.CGColor);
    CGContextSetLineWidth(context, 0.5);
    CGContextMoveToPoint(context, 0, y);
    CGContextAddLineToPoint(context, self.frame.size.width, y);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextSetLineDash(context, 0, NULL, 0);
    
    CGContextSetFillColorWithColor(context, ChartColors_crossLineColor.CGColor);
    CGContextAddArc(context, curX, y, 2, 0, M_PI_2, true);
    CGContextDrawPath(context, kCGPathFill);
    CGFloat crossPrice = self.mainRenderer.scaleY == 0
        ? point.close
        : self.mainRenderer.maxValue - (y - CGRectGetMinY(self.mainRenderer.chartRect)) / self.mainRenderer.scaleY;
    [self drawLongPressCrossLineText:context curPoint:point curX:curX y:y crossPrice:crossPrice];
}

-(void)drawLongPressCrossLineText:(CGContextRef)context
                         curPoint:(KLineModel *)curPoint
                             curX:(CGFloat)curX
                                y:(CGFloat)y
                       crossPrice:(CGFloat)crossPrice {
    NSString *text = [NSString stringWithFormat:_mainValueFormatter,crossPrice];
    CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
    CGFloat padding = 3;
    CGFloat textHeight = rect.size.height + padding * 2;
    CGFloat textWdith = rect.size.width;
    BOOL isLeft = false;
    if(curX > self.frame.size.width / 2) {
        isLeft = true;
        CGContextMoveToPoint(context, self.frame.size.width, y - textHeight / 2);
        CGContextAddLineToPoint(context, self.frame.size.width, y + textHeight / 2);
        
        CGContextAddLineToPoint(context, self.frame.size.width - textWdith, y + textHeight / 2);
        CGContextAddLineToPoint(context, self.frame.size.width - textWdith - 10, y);
        CGContextAddLineToPoint(context, self.frame.size.width - textWdith, y - textHeight / 2);
        CGContextAddLineToPoint(context, self.frame.size.width, y - textHeight / 2);
        CGContextSetLineWidth(context, 1);
        CGContextSetStrokeColorWithColor(context, ChartColors_markerBorderColor.CGColor);
        CGContextSetFillColorWithColor(context, ChartColors_selectedPriceBoxBgColor.CGColor);
        CGContextDrawPath(context, kCGPathFillStroke);
        [self.mainRenderer drawText:text atPoint:CGPointMake(self.frame.size.width - textWdith - 2, y - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor: [UIColor whiteColor]];
    } else {
        isLeft = false;
        CGContextMoveToPoint(context, 0, y - textHeight / 2);
        CGContextAddLineToPoint(context, 0, y + textHeight / 2);
        
        CGContextAddLineToPoint(context, textWdith, y + textHeight / 2);
        CGContextAddLineToPoint(context,textWdith + 10, y);
        CGContextAddLineToPoint(context,textWdith, y - textHeight / 2);
        CGContextAddLineToPoint(context, 0, y - textHeight / 2);
        CGContextSetLineWidth(context, 1);
        CGContextSetStrokeColorWithColor(context, ChartColors_markerBorderColor.CGColor);
        CGContextSetFillColorWithColor(context, ChartColors_selectedPriceBoxBgColor.CGColor);
        CGContextDrawPath(context, kCGPathFillStroke);
        [self.mainRenderer drawText:text atPoint:CGPointMake(2, y - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor: [UIColor whiteColor]];
    }
    
    NSString *dateText = [self calculateDateText:curPoint.id];
    CGRect dateRect = [dateText getRectWithFontSize:ChartStyle_defaultTextSize];
    CGFloat datepadding = 3;
    CGContextSetStrokeColorWithColor(context, ChartColors_markerBorderColor.CGColor);
    CGContextSetFillColorWithColor(context, ChartColors_selectedLabelBgColor.CGColor);
    CGContextAddRect(context, CGRectMake(curX - dateRect.size.width / 2 - datepadding, CGRectGetMinY(self.dateRect), dateRect.size.width + datepadding * 2, dateRect.size.height + datepadding * 2));
    CGContextDrawPath(context, kCGPathFillStroke);
    [self.mainRenderer drawText:dateText atPoint:CGPointMake(curX - dateRect.size.width  / 2, CGRectGetMinY(self.dateRect) + datepadding) fontSize:ChartStyle_defaultTextSize textColor: [UIColor whiteColor]];
    [self drawMarketInfoBox:context curPoint:curPoint isLeft:isLeft];
    [self drawTopText:context curPoint:curPoint];
}

-(void)drawMarketInfoBox:(CGContextRef)context curPoint:(KLineModel *)curPoint isLeft:(BOOL)isLeft {
    if (self.hideMarketInfoBox) {
        return;
    }
    if (self.selectedInfoLabels.count < 8) {
        return;
    }

    NSString *priceFormat = self.mainValueFormatter.length > 0 ? self.mainValueFormatter : @"%.2f";
    NSString *volFormat = self.volFormatter.length > 0 ? self.volFormatter : @"%.3f";
    CGFloat diff = curPoint.close - curPoint.open;
    NSString *sign = diff >= 0 ? @"+" : @"-";
    UIColor *changeColor = diff >= 0 ? (self.increaseColor ?: ChartColors_upColor) : (self.decreaseColor ?: ChartColors_dnColor);

    NSString *timeStr = [self calculateDateText:curPoint.id];
    NSString *openStr = [NSString stringWithFormat:priceFormat, curPoint.open];
    NSString *highStr = [NSString stringWithFormat:priceFormat, curPoint.high];
    NSString *lowStr = [NSString stringWithFormat:priceFormat, curPoint.low];
    NSString *closeStr = [NSString stringWithFormat:priceFormat, curPoint.close];
    NSString *changeStr = [NSString stringWithFormat:@"%@%@", sign, [NSString stringWithFormat:priceFormat, fabs(diff)]];
    CGFloat changePercent = curPoint.open != 0 ? (diff * 100.0) / curPoint.open : 0;
    NSString *changeRateStr = [NSString stringWithFormat:@"%@%.2f%%", sign, fabs(changePercent)];
    NSString *volStr = [_mainRenderer volFormat:curPoint.vol volFormatter:volFormat];

    NSArray<NSString *> *values = @[timeStr, openStr, highStr, lowStr, closeStr, changeStr, changeRateStr, volStr];

    CGFloat fontSize = ChartStyle_defaultTextSize;
    CGFloat padding = 4;
    CGFloat margin = 5;
    CGFloat top = ChartStyle_topPadding;
    CGFloat lineHeight = fontSize + 4;
    CGFloat maxWidth = 0;

    for (NSInteger i = 0; i < 8; i++) {
        NSString *line = [NSString stringWithFormat:@"%@%@", self.selectedInfoLabels[i], values[i]];
        CGRect rect = [line getRectWithFontSize:fontSize];
        maxWidth = MAX(maxWidth, rect.size.width);
    }

    maxWidth += padding * 2;
    CGFloat height = padding * 2 + lineHeight * 8;
    NSString *maxAxisText = [NSString stringWithFormat:self.valueFormatter, self.mainRenderer.maxValue];
    NSString *minAxisText = [NSString stringWithFormat:self.valueFormatter, self.mainRenderer.minValue];
    CGFloat axisTextWidth = MAX([maxAxisText getRectWithFontSize:ChartStyle_reightTextSize].size.width,
                                [minAxisText getRectWithFontSize:ChartStyle_reightTextSize].size.width);
    // 6pt 是价格刻度自身右边距，另留 12pt 视觉间隔，避免右上详情框盖住价格。
    CGFloat rightAxisReserve = axisTextWidth + 18.0;
    CGFloat rightSideLeft = self.frame.size.width - rightAxisReserve - maxWidth - margin;
    CGFloat left = isLeft ? margin : MAX(margin, rightSideLeft);
    CGRect boxRect = CGRectMake(left, top, maxWidth, height);

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:boxRect cornerRadius:padding / 2.0];
    CGContextAddPath(context, path.CGPath);
    CGContextSetFillColorWithColor(context, ChartColors_markerBgColor.CGColor);
    CGContextFillPath(context);
    CGContextAddPath(context, path.CGPath);
    CGContextSetStrokeColorWithColor(context, ChartColors_markerBorderColor.CGColor);
    // 0.8 而不是 0.5，对齐 Android：selectorBorderPaint 的线宽来自 setLineWidth，
    // 默认 0.8dp（KChartView.java 的 lineWidth attr），模拟器上实测是 2px 的 #DDDDDD。
    // iOS 原来的 0.5pt 在 @3x 上只有 1.5px，抗锯齿摊成两行半透明像素后几乎看不见，
    // 浅色主题下白框白底等于没有边框 —— QA 反馈的就是这个。
    CGContextSetLineWidth(context, 0.8);
    CGContextStrokePath(context);

    // 标签左对齐、数值右对齐，与 Android MainRenderer.drawSelector 保持一致。
    // 之前把「标签+数值」拼成一整行左对齐，而标签宽度不一（开/高/低/收 是 1 个字，
    // 涨跌额/涨跌幅/成交量 是 3 个字），数值列因此参差不齐。
    // 盒宽仍然按拼接后的整行取 max，所以右对齐的数值不可能压到标签上。
    CGFloat right = left + maxWidth;
    CGFloat y = top + padding;
    for (NSInteger i = 0; i < 8; i++) {
        // 标签恒用常规文字色，只有涨跌额/涨跌幅这两行的「数值」才染涨跌色 ——
        // 与 Android MainRenderer.drawSelector 一致（它的 label 一律走 selectorTextPaint，
        // 只有 strings[5]/[6] 走 upPaint/downPaint）。之前 iOS 把 label 也一起染了，
        // 两端并排对比时 iOS 的「涨跌额」三个字是绿的、Android 是黑的。
        UIColor *valueColor = (i == 5 || i == 6) ? changeColor : ChartColors_markerTextColor;
        NSString *value = values[i];
        CGFloat valueWidth = [value getRectWithFontSize:fontSize].size.width;
        [self.mainRenderer drawText:self.selectedInfoLabels[i]
                            atPoint:CGPointMake(left + padding, y)
                           fontSize:fontSize
                          textColor:ChartColors_markerTextColor];
        [self.mainRenderer drawText:value
                            atPoint:CGPointMake(right - padding - valueWidth, y)
                           fontSize:fontSize
                          textColor:valueColor];
        y += lineHeight;
    }
}

-(void)drawTopText:(CGContextRef)context curPoint:(KLineModel *)curPoint {
    [_mainRenderer drawTopText:context curPoint:curPoint mainValueFormatter:_mainValueFormatter volFormatter:_volFormatter];
    if(_volRenderer != nil) {
        [_volRenderer drawTopText:context curPoint:curPoint mainValueFormatter:_mainValueFormatter volFormatter:_volFormatter];
    }
    if(_seconderyRender != nil) {
        [_seconderyRender drawTopText:context curPoint:curPoint mainValueFormatter:_mainValueFormatter volFormatter:_volFormatter];
    }
}
-(void)drawRealTimePrice:(CGContextRef)context {
    KLineModel *point = self.datas.firstObject;
    NSString *text = [NSString stringWithFormat:_mainValueFormatter,point.close];
    CGFloat fontSize = 10;
    CGRect rect = [text getRectWithFontSize:fontSize];
    CGFloat y = [self.mainRenderer getY:point.close];
    if(point.close > self.mMainMaxValue) {
        y = [self.mainRenderer getY:self.mMainMaxValue];
    } else if (point.close < self.mMainMinValue) {
        y = [self.mainRenderer getY:self.mMainMinValue];
    }
    if((-_scrollX - rect.size.width) > 0) {
        CGContextSaveGState(context);
        CGContextSetStrokeColorWithColor(context, ChartColors_realTimeLongLineColor.CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGFloat locations[] = {5,5};
        CGContextSetLineDash(context, 0, locations, 2);
        CGContextMoveToPoint(context,self.frame.size.width + _scrollX, y);
        CGContextAddLineToPoint(context, self.frame.size.width, y);
                CGContextStrokePath(context);
        
                // 清除 dash（确保后续为实线）
                CGContextSetLineDash(context, 0, NULL, 0);
        
                // 2) 背景 + 边框参数
               CGFloat cornerRadius = 4.0;
               CGFloat paddingX = 6.0;      // 水平内边距
                CGFloat paddingY = 3.0;      // 垂直内边距
               CGFloat strokeWidth = 0.5;   // 边框宽度
        
                CGFloat bgWidth = rect.size.width + 2 * paddingX;
                CGFloat bgHeight = rect.size.height + 2 * paddingY;
                CGFloat rightInset = 4.0;
                CGRect backgroundRect = CGRectMake(self.frame.size.width - bgWidth - rightInset,
                                                  y - bgHeight / 2.0,
                                                  bgWidth,
                                                bgHeight);
        
                // 3) 填充圆角背景
                UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:backgroundRect
                                                                     cornerRadius:cornerRadius];
                CGContextAddPath(context, fillPath.CGPath);
                CGContextSetFillColorWithColor(context, _priceLabelRightBackgroundColor.CGColor);
            CGContextFillPath(context);
        
                // 4) 绘制实线边框（在背景内部）
                CGRect strokeRect = CGRectInset(backgroundRect, strokeWidth / 2.0, strokeWidth / 2.0);
                CGFloat innerCornerRadius = MAX(0.0, cornerRadius - strokeWidth / 2.0);
               UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect
                                                                       cornerRadius:innerCornerRadius];
                CGContextAddPath(context, strokePath.CGPath);
                CGContextSetStrokeColorWithColor(context, _priceLabelRightTextColor.CGColor); // 边框色
                CGContextSetLineWidth(context, strokeWidth);
               CGContextStrokePath(context);
        
                CGContextRestoreGState(context);
        
                // 5) 绘制文字，保证在背景内并带 padding
                CGFloat textX = CGRectGetMinX(backgroundRect) + paddingX;
                // 将文字顶点垂直居中放在背景中（你原来用 y - rect.size.height/2 作为 top）
                CGFloat textY = CGRectGetMinY(backgroundRect) + (bgHeight - rect.size.height) / 2.0;
                [self.mainRenderer drawText:text atPoint:CGPointMake(textX, textY) fontSize:fontSize textColor:_priceLabelRightTextColor];

        if(_isLine) {
            // 分时最新价圆点：同样不能写死白色，浅色底下会消失。这一段其余元素
            // （虚线、边框、文字）都用 _priceLabelRightTextColor，圆点跟着它走。
            CGContextSetFillColorWithColor(context, _priceLabelRightTextColor.CGColor);
            CGContextAddArc(context, self.frame.size.width + _scrollX - _candleWidth / 2, y, 2, 0, M_PI_2, true);
            CGContextDrawPath(context, kCGPathFill);
        }
    } else {
        //实时k线虚线颜色
        CGContextSetStrokeColorWithColor(context, _priceLabelRightTextColor.CGColor);
       CGContextSetLineWidth(context, 0.5);
       CGFloat locations[] = {5,5};
       CGContextSetLineDash(context, 0, locations, 2);
       CGContextMoveToPoint(context,0, y);
       CGContextAddLineToPoint(context, self.frame.size.width, y);
       CGContextDrawPath(context, kCGPathStroke);
        
        CGFloat r = 8;
        CGFloat w = rect.size.width + 16;
        CGContextSetLineWidth(context, 0.5);
        CGFloat locations1[] = {};
        CGContextSetLineDash(context, 0, locations1, 0);
        //实时k线背景色
        CGContextSetFillColorWithColor(context, _priceLabelRightBackgroundColor.CGColor );
        CGContextMoveToPoint(context,self.frame.size.width * 0.8, y - r);
        
        CGFloat curX = self.frame.size.width * 0.8;
        CGRect arcRect = CGRectMake(curX - w / 2, y - r, w, 2 * r);
        CGFloat minX = CGRectGetMinX(arcRect);
        CGFloat midX = CGRectGetMidX(arcRect);
        CGFloat maxX = CGRectGetMaxX(arcRect);
        
        CGFloat minY = CGRectGetMinY(arcRect);
        CGFloat midY = CGRectGetMidY(arcRect);
        CGFloat maxY = CGRectGetMaxY(arcRect);
        
        CGContextMoveToPoint(context,minX, midY);
        CGContextAddArcToPoint(context, minX, minY, midX, minY, 4);
        CGContextAddArcToPoint(context, maxX, minY, maxX, midY, 4);
        CGContextAddArcToPoint(context, maxX, maxY, midX, maxY, 4);
        CGContextAddArcToPoint(context, minX, maxY, minX, midY, 4);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        CGFloat startX = CGRectGetMaxX(arcRect) - 4;
        //侧边栏文字颜色
        CGContextSetFillColorWithColor(context, _priceLabelRightTextColor.CGColor);
        CGContextMoveToPoint(context,startX, y);
        CGContextAddLineToPoint(context, startX - 3, y - 3);
        CGContextAddLineToPoint(context, startX - 3, y + 3);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFill);
        [self.mainRenderer drawText:text atPoint:CGPointMake(curX - rect.size.width / 2 - 4, y - rect.size.height / 2) fontSize:fontSize textColor: _priceLabelRightTextColor];

    }
    
    
}

-(NSUInteger)calculateIndexWithSelectX:(CGFloat)selectX {
    NSInteger index = (self.frame.size.width - _startX - selectX) / (_candleWidth + ChartStyle_canldeMargin) + _startIndex;
    return index;
}

-(BOOL)outRangeIndex:(NSUInteger)index {
    if(index < 0 || index >= self.datas.count) {
        return true;
    } else {
        return false;
    }
}

// 该横坐标能否选中：越界或 isPad 占位 K 线不可选中。
// KLineChartView 手势入口用：避免选中态落在「画不出来」的 K 线上，
// 造成看不见的十字线劫持横向滚动 / 图例被吞（对齐 Android onSelectedChange 的占位拦截）。
-(BOOL)canSelectAtX:(CGFloat)selectX {
    NSUInteger index = [self calculateIndexWithSelectX:selectX];
    if ([self outRangeIndex:index]) { return NO; }
    return !((KLineModel *)self.datas[index]).isPad;
}

-(NSString *)calculateDateText:(NSTimeInterval)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    formater.dateFormat = _dateTimeFormatter;
    return [formater stringFromDate:date];
}

@end
