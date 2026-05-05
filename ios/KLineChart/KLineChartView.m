//
//  KLineChartView.m
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import "KLineChartView.h"
#import "ChartStyle.h"
#import "KLinePainterView.h"
#import "KLineInfoView.h"
#import <math.h>

@interface KLineChartView()
@property(nonatomic,strong) KLinePainterView *painterView;
@property(nonatomic,strong) KLineInfoView *infoView;

@property(nonatomic,assign) CGFloat maxScroll;
@property(nonatomic,assign) CGFloat minScroll;

@property(nonatomic,assign) CGFloat lastScrollX;


@property(nonatomic,assign) CGFloat dragbeginX;
@property(nonatomic,assign) BOOL isDrag;
@property(nonatomic,assign) CGFloat speedX;
@property(nonatomic,strong) CADisplayLink *displayLink;

@property(nonatomic,assign) BOOL isScale;
@property(nonatomic,assign) CGFloat lastscaleX;
@property(nonatomic, assign) CGFloat pinchAnchorXInView;   // 两指中心（视图坐标）
@property(nonatomic, assign) CGFloat pinchAnchorContentX;
@property (nonatomic, assign) CGFloat rightBlankFactor;

@end


@implementation KLineChartView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.painterView.frame = self.bounds;
    [self initIndicatirs];
}

- (void)setDatas:(NSArray<KLineModel *> *)datas {
    _datas = datas;
    [self initIndicatirs];
    self.painterView.datas = datas;
}

- (void)setIsLine:(BOOL)isLine {
    _isLine = isLine;
    self.painterView.isLine = isLine;
}

- (void)setIsLongPress:(BOOL)isLongPress {
    _isLongPress = isLongPress;
    self.painterView.isLongPress = isLongPress;
    if(!isLongPress) {
        [self.infoView removeFromSuperview];
    }
}

-(void)setScrollX:(CGFloat)scrollX {
    _scrollX = scrollX;
    self.painterView.scrollX = scrollX;
}

- (void)setScaleX:(CGFloat)scaleX {
    _scaleX = scaleX;
    [self initIndicatirs];
    self.painterView.scaleX = scaleX;
}

- (void)setCandleWidth:(CGFloat)candleWidth {
    if (candleWidth <= 0) {
        return;
    }
    _candleWidth = candleWidth;
    ChartStyle_candleWidth = candleWidth;
    ChartStyle_defaultcandleWidth = candleWidth;
    ChartStyle_volWidth = candleWidth;
    self.scrollX = -self.frame.size.width / 5 + ChartStyle_candleWidth * self.scaleX / 2;
    [self initIndicatirs];
    self.painterView.scaleX = self.scaleX;
}

- (void)setMainState:(MainState)mainState {
    _mainState = mainState;
    self.painterView.mainState = mainState;
}

-(void)setSecondaryState:(SecondaryState)secondaryState {
    _secondaryState = secondaryState;
    self.painterView.secondaryState = secondaryState;
}

-(void)setLongPressX:(CGFloat)longPressX {
    _longPressX = longPressX;
    self.painterView.longPressX = longPressX;
}

-(void)setDirection:(KLineDirection)direction {
    _direction = direction;
    self.painterView.direction = direction;
}

-(void)setGridColumns:(NSInteger)gridColumns {
  _gridColumns = gridColumns;
  self.painterView.gridColumns = gridColumns;
}

-(void)setGridRows:(NSInteger)gridRows {
  _gridRows = gridRows;
  self.painterView.gridRows = gridRows;
}

-(void)setBackgroundFillTopColor:(UIColor *)backgroundFillTopColor{
  _backgroundFillTopColor = backgroundFillTopColor;
  self.painterView.backgroundFillTopColor = backgroundFillTopColor;
}

-(void)setBackgroundFillBottomColor:(UIColor *)backgroundFillBottomColor{
  _backgroundFillBottomColor = backgroundFillBottomColor;
  self.painterView.backgroundFillBottomColor = backgroundFillBottomColor;
}

-(void)setTimeLineColor:(UIColor *)timeLineColor{
  _timeLineColor = timeLineColor;
  self.painterView.timeLineColor = timeLineColor;
}

-(void)setTimeLineFillTopColor:(UIColor *)timeLineFillTopColor{
  _timeLineFillTopColor = timeLineFillTopColor;
  self.painterView.timeLineFillTopColor = timeLineFillTopColor;
}

-(void)setTimeLineFillBottomColor:(UIColor *)timeLineFillBottomColor{
  _timeLineFillBottomColor = timeLineFillBottomColor;
  self.painterView.timeLineFillBottomColor = timeLineFillBottomColor;
}

-(void)setTimeLineEndPointColor:(UIColor *)timeLineEndPointColor{
  _timeLineEndPointColor = timeLineEndPointColor;
  self.painterView.timeLineEndPointColor = timeLineEndPointColor;
}

-(void)setTimeLineEndRadius:(CGFloat)timeLineEndRadius{
  _timeLineEndRadius = timeLineEndRadius;
  self.painterView.timeLineEndRadius = timeLineEndRadius;
}

-(void)setIncreaseColor:(UIColor *)increaseColor{
  _increaseColor = increaseColor;
  self.painterView.increaseColor = increaseColor;
}

-(void)setDecreaseColor:(UIColor *)decreaseColor{
  _decreaseColor = decreaseColor;
  self.painterView.decreaseColor = decreaseColor;
}

-(void)setPriceLabelRightTextColor:(UIColor *)priceLabelRightTextColor{
  _priceLabelRightTextColor = priceLabelRightTextColor;
    self.painterView.priceLabelRightTextColor = priceLabelRightTextColor;
}

-(void)setPriceLabelRightBackgroundColor:(UIColor *)priceLabelRightBackgroundColor{
  _priceLabelRightBackgroundColor = priceLabelRightBackgroundColor;
    self.painterView.priceLabelRightBackgroundColor = priceLabelRightBackgroundColor;
}

-(void)setGridLineColor:(UIColor *)gridLineColor{
    _gridLineColor = gridLineColor;
    self.painterView.gridLineColor = gridLineColor;
}

-(void)setMa1Color:(UIColor *)ma1Color{
    _ma1Color = ma1Color;
    self.painterView.ma1Color = ma1Color;
}

-(void)setMa2Color:(UIColor *)ma2Color{
    _ma2Color = ma2Color;
    self.painterView.ma2Color = ma2Color;
}

-(void)setMa3Color:(UIColor *)ma3Color{
    _ma3Color = ma3Color;
    self.painterView.ma3Color = ma3Color;
}

-(void)setVolMa1Color:(UIColor *)volMa1Color{
    _volMa1Color = volMa1Color;
    self.painterView.volMa1Color = volMa1Color;
}

-(void)setVolMa2Color:(UIColor *)volMa2Color{
    _volMa2Color = volMa2Color;
    self.painterView.volMa2Color = volMa2Color;
}

-(void)setValueFormatter:(NSString *)valueFormatter{
  _valueFormatter = valueFormatter;
  self.painterView.valueFormatter = valueFormatter;
}

-(void)setVolFormatter:(NSString *)volFormatter{
  _volFormatter = volFormatter;
  self.painterView.volFormatter = volFormatter;
}

-(void)setDateTimeFormatter:(NSString *)dateTimeFormatter{
  _dateTimeFormatter  = dateTimeFormatter;
  self.painterView.dateTimeFormatter = dateTimeFormatter;
}

-(void)setMainValueFormatter:(NSString *)mainValueFormatter{
  _mainValueFormatter = mainValueFormatter;
  self.painterView.mainValueFormatter = mainValueFormatter;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scaleX = 1;
        _mainState = MainStateMA;
        _secondaryState = SecondaryStateWR;
        _scrollX = -self.frame.size.width / 5 + ChartStyle_candleWidth / 2;
        _rightBlankFactor = 4.0; // 初始：1/4
        [self initIndicatirs];
        _painterView = [[KLinePainterView alloc] initWithFrame:self.bounds datas:_datas scrollX:_scrollX isLine:_isLine scaleX:_scaleX isLongPress:_isLongPress mainState:_mainState secondaryState:_secondaryState];
        [self addSubview:_painterView];
         __weak typeof(self) weakSelf = self;
        _painterView.showInfoBlock = ^(KLineModel * _Nonnull model, BOOL isLeft) {
            weakSelf.infoView.model = model;
            [weakSelf addSubview:weakSelf.infoView];
            CGFloat padding = 5;
            if(isLeft){
                weakSelf.infoView.frame = CGRectMake(padding, 30,  weakSelf.infoView.frame.size.width,  weakSelf.infoView.frame.size.height);
            } else {
                weakSelf.infoView.frame = CGRectMake(weakSelf.frame.size.width - weakSelf.infoView.frame.size.width - padding, 30,  weakSelf.infoView.frame.size.width,  weakSelf.infoView.frame.size.height);
            }
        };
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragKlineEvent:)];
        UILongPressGestureRecognizer *longGresture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressKlineEvent:)];
        UIPinchGestureRecognizer *pinGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(secalXEvent:)];
        [_painterView addGestureRecognizer:panGesture];
        [_painterView addGestureRecognizer:longGresture];
        [_painterView addGestureRecognizer:pinGesture];
    }
    return self;
}


-(void)initIndicatirs {
    CGFloat dataLength = ((CGFloat)_datas.count) * (ChartStyle_candleWidth * _scaleX + ChartStyle_canldeMargin) - ChartStyle_canldeMargin;
      _maxScroll = dataLength - self.frame.size.width;
//    if(dataLength > self.frame.size.width) {
//        _maxScroll = dataLength - self.frame.size.width;
//    } else {
//        _maxScroll =  -(self.frame.size.width - dataLength);
//    }
    CGFloat dataScroll = self.frame.size.width - dataLength;
    CGFloat normalminScroll = -self.frame.size.width / self.rightBlankFactor
                                + (ChartStyle_candleWidth * _scaleX) / 2.0;
    self.minScroll = MIN(normalminScroll,-dataScroll);
    self.scrollX = [self clamp:_scrollX min:_minScroll max:_maxScroll];
    self.lastScrollX = self.scrollX;
    
}

-(void)dragKlineEvent:(UIPanGestureRecognizer *)gesture{
    if(_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint point = [gesture locationInView:self.painterView];
            self.rightBlankFactor = 2.0;
            [self initIndicatirs];
            _dragbeginX = point.x;
            _isDrag = true;
        } break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self.painterView];
            CGFloat dragX = point.x - _dragbeginX;
            self.scrollX = [self clamp:_lastScrollX + dragX min:_minScroll max:_maxScroll];
        } break;
        case UIGestureRecognizerStateEnded:
        {
            CGPoint speed = [gesture velocityInView:self.painterView];
            self.speedX = speed.x;
            _isDrag = false;
            self.lastScrollX = self.scrollX;
            if(speed.x != 0) {
                _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshEvent:)];
                [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            }
        }break;
        default:
            break;
    }
    
}

-(void)longPressKlineEvent:(UILongPressGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint point = [gesture locationInView:self.painterView];
            self.longPressX = point.x;
            self.isLongPress = YES;
        } break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self.painterView];
            self.longPressX = point.x;
            self.isLongPress = YES;
        } break;
        case UIGestureRecognizerStateEnded:
            self.isLongPress = NO;
        default:
            break;
    }
}
-(void)secalXEvent:(UIPinchGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            _isScale = true;
            if(_displayLink) {
                [_displayLink invalidate];
                _displayLink = nil;
            }
            // 记录锚点（两指中点）
            CGPoint p = [gesture locationInView:self.painterView];
            self.pinchAnchorXInView = p.x;
            // 记录起始缩放
            self.lastscaleX = self.scaleX;
            CGFloat unitW = ChartStyle_candleWidth * self.lastscaleX + ChartStyle_canldeMargin;
            if (unitW < 0.0001) unitW = 0.0001;
            // 将锚点映射到小数索引，缩放时保持同一根 K 线在手指中点下方
            self.pinchAnchorContentX = (self.scrollX + self.pinchAnchorXInView) / unitW;
            break;
            
        }
        case UIGestureRecognizerStateChanged: {
            _isScale = true;
            
            CGFloat gestureScale = gesture.scale;
            CGFloat acceleratedScale = gestureScale < 1.0
                ? pow(gestureScale, 3.0)
                : pow(gestureScale, 1.4);
            CGFloat newScaleX = [self clamp:(self.lastscaleX * acceleratedScale) min:0.05 max:2.0];
            
            // 1) 用 setter 设置 scaleX（很重要！）
            //    这样 painterView.scaleX 会同步，initIndicatirs 会重算 min/max
            self.scaleX = newScaleX;
            
            // 2) 用“新单位宽”反解出为了让锚点不动所需要的 scrollX
            CGFloat unitW_new = ChartStyle_candleWidth * self.scaleX + ChartStyle_canldeMargin;
            CGFloat newScrollX = self.pinchAnchorContentX * unitW_new - self.pinchAnchorXInView;
            
            // 3) clamp 到“当前（新边界）”范围，再落到属性（会同步到 painterView）
            self.scrollX = [self clamp:newScrollX min:self.minScroll max:self.maxScroll];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            _isScale = false;
            self.lastscaleX = self.scaleX;
            break;
        }
    }
}
-(void)refreshEvent:(CADisplayLink *)displaylink {
    CGFloat space = 100;
    if(self.speedX < 0) {
        self.speedX = MIN(self.speedX + space,0);
        self.scrollX = [self clamp:self.scrollX - 5 min:_minScroll max:_maxScroll];
        self.lastscaleX = self.scrollX;
    } else if (self.speedX > 0) {
        self.speedX = MAX(self.speedX - space,0);
        self.scrollX = [self clamp:self.scrollX + 5 min:_minScroll max:_maxScroll];
        self.lastScrollX = self.scrollX;
    } else {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    if(self.scrollX == self.minScroll) {
        [_displayLink invalidate];
        _displayLink = nil;
        SEL selector = NSSelectorFromString(@"onSlidRight");
        if ([self.delegate respondsToSelector:selector]) {
            [self.delegate onSlidRight];
        }
    }
    if (self.scrollX == self.maxScroll) {
        SEL selector = NSSelectorFromString(@"onSlidLeft");
        if ([self.delegate respondsToSelector:selector]) {
            [self.delegate onSlidLeft];
        }
    }
}


-(CGFloat)clamp:(CGFloat)value min:(CGFloat)min max:(CGFloat)max {
    if (value < min) {
        return min;
    } else if (value > max) {
        return max;
    } else {
        return value;
    }
}

-(KLineInfoView *)infoView {
    if(_infoView == nil) {
        _infoView = [[KLineInfoView alloc] initWithFrame:CGRectMake(0, 0, 120, 145)];
    }
    return _infoView;
}


@end
