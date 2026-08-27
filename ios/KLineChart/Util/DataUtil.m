//
//  DataUtil.m
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import "DataUtil.h"


@implementation DataUtil

+(void)calculate:(NSArray<KLineModel *> *)dataList {
    if(dataList == nil) { return; }
    dataList = [[dataList reverseObjectEnumerator] allObjects];
    [self calcMA:dataList isLast:false];
    [self calcBOLL:dataList isLast:false];
    [self calcVolumeMA:dataList isLast:false];
    [self calcKDJ:dataList isLast:false];
    [self calcMACD:dataList isLast:false];
    [self calcRSI:dataList isLast:false];
    [self calcWR:dataList isLast:false];
}

+(void)addLastData:(NSArray<KLineModel *> *)dataList data:(KLineModel *)model {
    if(dataList == nil) { return; }
    NSMutableArray *_dataList = [[NSMutableArray alloc] initWithArray:[[dataList reverseObjectEnumerator] allObjects]];
    [_dataList addObject:model];
    [self calcMA:_dataList isLast:true];
    [self calcBOLL:_dataList isLast:true];
    [self calcVolumeMA:_dataList isLast:true];
    [self calcKDJ:_dataList isLast:true];
    [self calcMACD:_dataList isLast:true];
    [self calcRSI:_dataList isLast:true];
    [self calcWR:_dataList isLast:true];
}

+(void)calcMA:(NSArray<KLineModel *> *)dataList isLast:(BOOL)isLast {
    double ma5 = 0;
    double ma10 = 0;
    double ma20 = 0;
    double ma30 = 0;
    int i = 0;
    if (isLast && dataList.count > 1) {
      i = dataList.count - 1;
      KLineModel *data = dataList[dataList.count - 2];
      // 上一根若仍是未计算态(NAN 占位)，按 0 起算，保持与原逻辑一致并避免 NAN 传播
      ma5 = (isnan(data.MA5Price) ? 0 : data.MA5Price) * 5;
      ma10 = (isnan(data.MA10Price) ? 0 : data.MA10Price) * 10;
      ma20 = (isnan(data.MA20Price) ? 0 : data.MA20Price) * 20;
      ma30 = (isnan(data.MA30Price) ? 0 : data.MA30Price) * 30;
//      ma60 = data.MA60Price * 60;
    }
    for (; i < dataList.count; i++) {
      KLineModel *entity = dataList[i];
      CGFloat closePrice = entity.close;
      ma5 += closePrice;
      ma10 += closePrice;
      ma20 += closePrice;
      ma30 += closePrice;
//      ma60 += closePrice;

      if (i == 4) {
        entity.MA5Price = ma5 / 5;
      } else if (i >= 5) {
        ma5 -= dataList[i - 5].close;
        entity.MA5Price = ma5 / 5;
      } else {
        // 前 period-1 根「未计算出 MA」用 NAN 占位，区别于「真实算出来就是 0」
        // （如上市前全 0 段 MA=0）。原来用 0 占位，绘制端 `!=0` 判断会把真实的
        // MA=0 段也当成没值跳过，导致 iOS 的 MA 线在全 0 段断开；Android 用
        // Float.MIN_VALUE 占位、按 `!=MIN_VALUE` 判断，MA=0 照样连线，故 Android 正常。
        entity.MA5Price = NAN;
      }
      if (i == 9) {
        entity.MA10Price = ma10 / 10;
      } else if (i >= 10) {
        ma10 -= dataList[i - 10].close;
        entity.MA10Price = ma10 / 10;
      } else {
        entity.MA10Price = NAN; // 未计算态用 NAN 占位（见上方 MA5 说明）
      }
      if (i == 19) {
        entity.MA20Price = ma20 / 20;
      } else if (i >= 20) {
        ma20 -= dataList[i - 20].close;
        entity.MA20Price = ma20 / 20;
      } else {
        entity.MA20Price = NAN; // 未计算态用 NAN 占位（见上方 MA5 说明）
      }
      if (i == 29) {
        entity.MA30Price = ma30 / 30;
      } else if (i >= 30) {
        ma30 -= dataList[i - 30].close;
        entity.MA30Price = ma30 / 30;
      } else {
        entity.MA30Price = NAN; // 未计算态用 NAN 占位（见上方 MA5 说明）
      }
//      if (i == 59) {
//        entity.MA60Price = ma60 / 60;
//      } else if (i >= 60) {
//        ma60 -= dataList[i - 60].close;
//        entity.MA60Price = ma60 / 60;
//      } else {
//        entity.MA60Price = 0;
//      }
    }
    
}

+(void)calcBOLL:(NSArray<KLineModel *> *)dataList isLast:(BOOL)isLast {
 int i = 0;
 if (isLast && dataList.count > 1) {
   i = dataList.count - 1;
 }
 for (; i < dataList.count; i++) {
   KLineModel *entity = dataList[i];
   if (i < 19) {
     entity.mb = 0;
     entity.up = 0;
     entity.dn = 0;
   } else {
     int n = 20;
     double md = 0;
     for (int j = i - n + 1; j <= i; j++) {
       double c = dataList[j].close;
       double m = entity.MA20Price;
       double value = c - m;
       md += value * value;
     }
     md = md / (n - 1);
     md = sqrt(md);
     entity.mb = entity.MA20Price;
     entity.up = entity.mb + 2.0 * md;
     entity.dn = entity.mb - 2.0 * md;
   }
 }
}

+(void)calcMACD:(NSArray<KLineModel *> *)dataList isLast:(BOOL)isLast {
    // 对齐安卓 DataTools.calcMACD / calculateEma / calculateDea：
    //  1) EMA 用「前 N 根收盘价的 SMA」播种（iOS 原来只用第 0 根收盘价播种）；
    //  2) 预热区 —— i<26-1 的 DIF、i<26+9-2 的 DEA 记为「未计算」(NAN 占位)，MACD 柱记 0。
    // iOS 原实现无预热、从第 1 根就出值，导致最左侧/上市前区域画出安卓压根不画的
    // MACD 柱（EMA 衰减期 ema12<ema26 → dif<0 → 多为负值/红色）。此处补齐预热即可对齐。
    const NSInteger s = 12;              // 短周期 EMA
    const NSInteger l = 26;              // 长周期 EMA
    const NSInteger m = 9;               // DEA 平滑周期
    const NSInteger warmup = m + l - 2;  // 33：index 不足此数的 MACD 柱一律 0（零高度不可见）
    NSInteger count = dataList.count;
 
    double ema12 = 0, ema26 = 0, preDea = 0;
    NSInteger i = 0;

    // isLast 增量更新：仅当「上一根」已越过预热区，才沿用其 EMA/DEA 继续递推；
    // 否则（数据太短、上一根仍在预热区）退回从头整算，避免用未播种的 EMA 递推出错值。
    if (isLast && count >= 2 && (count - 2) >= warmup) {
        i = count - 1;
        KLineModel *prev = dataList[count - 2];
        ema12 = prev.ema12;
        ema26 = prev.ema26;
        preDea = prev.dea;
    }

    for (; i < count; i++) {
        KLineModel *entity = dataList[i];

        // —— EMA12：i+1==s 用前 s 根收盘价 SMA 播种；之后标准递推（权重 2/(s+1)，等价 iOS 原 2/13）——
        if (i + 1 == s) {
            double sum = 0;
            for (NSInteger k = 0; k < s; k++) sum += dataList[k].close;
            ema12 = sum / s;
        } else if (i + 1 > s) {
            ema12 = (ema12 * (s - 1) + entity.close * 2) / (s + 1);
        }
        // —— EMA26：i+1==l 用前 l 根收盘价 SMA 播种；之后标准递推 ——
        if (i + 1 == l) {
            double sum = 0;
            for (NSInteger k = 0; k < l; k++) sum += dataList[k].close;
            ema26 = sum / l;
        } else if (i + 1 > l) {
            ema26 = (ema26 * (l - 1) + entity.close * 2) / (l + 1);
        }

        // —— DIF：i>=l-1 才成立，否则未计算(NAN)。——
        double dif = (i >= l - 1) ? (ema12 - ema26) : NAN;
        entity.dif = dif;

        // —— DEA：i==warmup 用前 m 根 DIF 的 SMA 播种；i>warmup 标准递推；预热区内 NAN。——
        double dea;
        if (i == warmup) {
            double sum = 0;
            for (NSInteger k = l - 1; k <= warmup; k++) sum += dataList[k].dif;
            dea = sum / m;
            preDea = dea;
        } else if (i > warmup) {
            dea = (preDea * (m - 1) + dif * 2) / (m + 1);
            preDea = dea;
        } else {
            dea = NAN;
        }
        entity.dea = dea;

        // —— MACD 柱：预热区(i<warmup)记 0（零高度不可见，对齐安卓）；之后 (DIF-DEA)*2（沿用 iOS 原倍数）——
        entity.macd = (i >= warmup) ? ((dif - dea) * 2) : 0;

        entity.ema12 = ema12;
        entity.ema26 = ema26;
    }
}

+(void)calcVolumeMA:(NSArray<KLineModel *> *)dataList isLast:(BOOL)isLast {
    double volumeMa5 = 0;
     double volumeMa10 = 0;

     int i = 0;
     if (isLast && dataList.count > 1) {
       i = dataList.count - 1;
       KLineModel *data = dataList[dataList.count - 2];
       volumeMa5 = data.MA5Volume * 5;
       volumeMa10 = data.MA10Volume * 10;
     }

     for (; i < dataList.count; i++) {
       KLineModel *entry = dataList[i];

       volumeMa5 += entry.vol;
       volumeMa10 += entry.vol;

       if (i == 4) {
         entry.MA5Volume = (volumeMa5 / 5);
       } else if (i > 4) {
         volumeMa5 -= dataList[i - 5].vol;
         entry.MA5Volume = volumeMa5 / 5;
       } else {
         entry.MA5Volume = 0;
       }

       if (i == 9) {
         entry.MA10Volume = volumeMa10 / 10;
       } else if (i > 9) {
         volumeMa10 -= dataList[i - 10].vol;
         entry.MA10Volume = volumeMa10 / 10;
       } else {
         entry.MA10Volume = 0;
       }
     }
}

+(void)calcRSI:(NSArray<KLineModel *> *)dataList isLast:(BOOL)isLast {
    double rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;

    int i = 0;
    if (isLast && dataList.count > 1) {
      i = dataList.count - 1;
      KLineModel *data = dataList[dataList.count - 2];
      rsi = data.rsi;
      rsiABSEma = data.rsiABSEma;
      rsiMaxEma = data.rsiMaxEma;
    }

    for (; i < dataList.count; i++) {
      KLineModel *entity = dataList[i];
      CGFloat closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double Rmax = MAX(0, closePrice - dataList[i - 1].close);
        double RAbs = ABS((closePrice - dataList[i - 1].close));

        rsiMaxEma = (Rmax + (14 - 1) * rsiMaxEma) / 14;
        rsiABSEma = (RAbs + (14 - 1) * rsiABSEma) / 14;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < 13) rsi = 0;
//      if (rsi.isNaN) rsi = 0;
      entity.rsi = rsi;
      entity.rsiABSEma = rsiABSEma;
      entity.rsiMaxEma = rsiMaxEma;
    }
}

+(void)calcKDJ:(NSArray<KLineModel *> *)dataList isLast:(BOOL)isLast {
    double k = 0;
    double d = 0;

    int i = 0;
    if (isLast && dataList.count > 1) {
      i = dataList.count - 1;
      KLineModel *data = dataList[dataList.count - 2];
      k = data.k;
      d = data.d;
    }

    for (; i < dataList.count; i++) {
      KLineModel *entity = dataList[i];
       CGFloat closePrice = entity.close;
      int startIndex = i - 13;
      if (startIndex < 0) {
        startIndex = 0;
      }
      CGFloat max14 =  -CGFLOAT_MAX;
      CGFloat min14 = CGFLOAT_MAX;
      for (int index = startIndex; index <= i; index++) {
        max14 = MAX(max14, dataList[index].high);
        min14 = MIN(min14, dataList[index].low);
      }
      double rsv = 100 * (closePrice - min14) / (max14 - min14);
//      if (rsv.isNaN) {
//        rsv = 0;
//      }
      if (i == 0) {
        k = 50;
        d = 50;
      } else {
        k = (rsv + 2 * k) / 3;
        d = (k + 2 * d) / 3;
      }
      if (i < 13) {
        entity.k = 0;
        entity.d = 0;
        entity.j = 0;
      } else if (i == 13 || i == 14) {
        entity.k = k;
        entity.d = 0;
        entity.j = 0;
      } else {
        entity.k = k;
        entity.d = d;
        entity.j = 3 * k - 2 * d;
      }
    }
}

+(void)calcWR:(NSArray<KLineModel *> *)dataList isLast:(BOOL)isLast {
    int i = 0;
    if (isLast && dataList.count > 1) {
      i = dataList.count - 1;
    }
    for (; i < dataList.count; i++) {
      KLineModel *entity = dataList[i];
      int startIndex = i - 14;
      if (startIndex < 0) {
        startIndex = 0;
      }
      CGFloat max14 =  -CGFLOAT_MAX;
      CGFloat min14 = CGFLOAT_MAX;
      for (int index = startIndex; index <= i; index++) {
        max14 = MAX(max14, dataList[index].high);
        min14 = MIN(min14, dataList[index].low);
      }
      if (i < 13) {
        entity.r = 0;
      } else {
        if ((max14 - min14) == 0) {
          entity.r = 0;
        } else {
          entity.r = 100 * (max14 - dataList[i].close) / (max14 - min14);
        }
      }
    }
}


@end
