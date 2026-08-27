//
//  ChartStyle.h
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import "UIColor+RGB.h"

#define Color(rgbValue)  [UIColor rgbFromHex:rgbValue]

/**
 * 浅色主题开关。
 *
 * 这套图表的配色本来全是编译期 #define，只有深色底一套；RN 侧又只接了 31 个 prop
 * （Android 接了 118 个），坐标轴文字/十字线/最高最低价标签这些根本没有 prop 可传，
 * 浅色页面上会出现白字白线。为避免新增一堆没接线的 prop，这里从「已经接了线的」
 * backgroundFillTopColor 反推主题：背景亮 => 浅色。由 KLinePainterView 在设置背景色时更新。
 */
extern BOOL gKLineChartLightTheme;
#define ThemeColor(darkHex, lightHex)  (gKLineChartLightTheme ? Color(lightHex) : Color(darkHex))

  //背景颜色
#define ChartColors_bgColor   ThemeColor(0xff06141D, 0xffffffff)
#define ChartColors_kLineColor   Color(0xff4C86CD)
#define ChartColors_gridColor   Color(0xff4c5c74)
#define ChartColors_ma5Color   Color(0xffC9B885)
#define ChartColors_ma10Color   Color(0xff6CB0A6)
#define ChartColors_ma30Color   Color(0xff9979C6)
#define ChartColors_upColor   Color(0xff4DAA90)
#define ChartColors_dnColor   Color(0xffC15466)
#define ChartColors_volColor   Color(0xff4729AE)

#define ChartColors_macdColor   Color(0xff4729AE)
#define ChartColors_difColor   Color(0xffC9B885)
#define ChartColors_deaColor   Color(0xff6CB0A6)

#define ChartColors_kColor   Color(0xffC9B885)
#define ChartColors_dColor   Color(0xff6CB0A6)
#define ChartColors_jColor   Color(0xff9979C6)
#define ChartColors_rsiColor   Color(0xffC9B885)

#define ChartColors_wrColor   Color(0xffD2D2B4)

#define ChartColors_yAxisTextColor   ThemeColor(0xff70839E, 0xff8d8d8d)  //右边y轴刻度
#define ChartColors_xAxisTextColor   ThemeColor(0xff60738E, 0xff8d8d8d)  //下方时间刻度

#define ChartColors_maxMinTextColor   ThemeColor(0xffffffff, 0xff000000)  //最大最小值的颜色

//深度颜色
#define ChartColors_depthBuyColor   Color(0xff60A893)
#define ChartColors_depthSellColor   Color(0xffC15866)

//选中后显示值边框颜色
#define ChartColors_markerBorderColor   ThemeColor(0xffFFFFFF, 0xffDDDDDD)

// 长按信息框底色（现在只有 drawMarketInfoBox 在用，Y 轴价格气泡已拆到
// ChartColors_selectedPriceBoxBgColor）。深色的 0x444444 是对齐 Android：
// detailTheme.js 的 selectedInfoBox.backgroundColor 深色分支就是 #444444
// （= Android 原生默认 DKGRAY），iOS 原生默认是 0x0D1722，两端并排看不一样。
// 浅色两端本来就都是 #FFFFFF（模拟器取色实测 (255,255,255)）。
#define ChartColors_markerBgColor   ThemeColor(0xff444444, 0xffFFFFFF)

/**
 * 长按（十字线 + 三个气泡 + 信息框）整套配色。
 *
 * 原来这一整条链路的文字/线条全是写死的 [UIColor whiteColor]，深色底下没问题，
 * 浅色主题下就是白线白字画在白底上 —— QA 看到的现象是「长按只剩一条灰竖带，
 * 时间/开/高/低/收/成交量 全都没有」，其实是画了但看不见。
 *
 * 浅色取值刻意对齐 JS 侧 src/theme/detailTheme.js 的 getKlineChartColors()
 * （crossXLine / crossY / selectedLabelBackground / selectedPriceBoxBackground /
 * selectedInfoBox.textColor），这样 iOS 和 Android 长按出来是同一套颜色。
 * 深色取值与改动前逐字相同，深色模式视觉零改动。
 */
//长按信息框文字（时间/开/高/低/收/成交量；涨跌额、涨跌幅另取涨跌色）
#define ChartColors_markerTextColor   ThemeColor(0xffFFFFFF, 0xff000000)

//长按十字线横线与交点圆
#define ChartColors_crossLineColor   ThemeColor(0xffFFFFFF, 0xff333333)

//长按 Y 轴价格气泡底色（文字恒为白，浅色下靠深底保证对比度）
#define ChartColors_selectedPriceBoxBgColor   ThemeColor(0xff0D1722, 0xff333333)

//长按 X 轴时间气泡底色
#define ChartColors_selectedLabelBgColor   ThemeColor(0xff06141D, 0xff333333)

//实时线颜色等
#define ChartColors_realTimeBgColor   ThemeColor(0xffffffff, 0xff000000)
#define ChartColors_rightRealTimeTextColor   ThemeColor(0xff000000, 0xffffffff)

#define ChartColors_realTimeTextBorderColor   ThemeColor(0xffffffff, 0xff333333)
#define ChartColors_realTimeTextColor   ThemeColor(0xffffffff, 0xff000000)

//实时线
#define ChartColors_realTimeLineColor   ThemeColor(0xffffffff, 0xff333333)
#define ChartColors_realTimeLongLineColor   Color(0xff4C86CD)


//表格右边文字颜色
#define ChartColors_reightTextColor   ThemeColor(0xff70839E, 0xff8d8d8d)
#define ChartColors_bottomDateTextColor   ThemeColor(0xff70839E, 0xff8d8d8d)

#define ChartColors_crossHlineColor   ThemeColor(0x1FFFFFFF, 0x1F000000)

static CGFloat dd = 11.0;
//点与点的距离（）不用这种方式实现
static CGFloat ChartStyle_pointWidth = 11.0;

    //蜡烛之间的间距
static CGFloat ChartStyle_canldeMargin =  1.5;

    //蜡烛默认宽度
static CGFloat ChartStyle_defaultcandleWidth =  8.5;

    //蜡烛宽度
static CGFloat ChartStyle_candleWidth  = 8.5;

    //蜡烛中间线的宽度
static CGFloat ChartStyle_candleLineWidth =  1.5;

    //vol柱子宽度
static CGFloat ChartStyle_volWidth = 8.5;

    //macd柱子宽度
static CGFloat ChartStyle_macdWidth = 3.0;

    //垂直交叉线宽度
static CGFloat ChartStyle_vCrossWidth  = 8.5;

    //水平交叉线宽度
static CGFloat ChartStyle_hCrossWidth = 0.5;

    //网格
static CGFloat ChartStyle_gridRows = 4;
   
static CGFloat ChartStyle_gridColumns = 5;

static CGFloat ChartStyle_topPadding = 30.0;
   
static CGFloat ChartStyle_bottomDateHigh = 20.0;
   
static CGFloat ChartStyle_childPadding = 25.0;

static CGFloat ChartStyle_defaultTextSize = 10;
   
static CGFloat ChartStyle_bottomDatefontSize = 10;
   
   //表格右边文字价格
static CGFloat ChartStyle_reightTextSize = 10;

static CGFloat ChartStyle_legendMarginLeft = 16.0;
