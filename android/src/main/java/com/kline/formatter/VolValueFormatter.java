package com.kline.formatter;

import java.util.Locale;

/**
 * 成交量格式化，与 iOS BaseChartRenderer.volFormat 规则一致。
 * 成交量不做固定精度补零：格式化后去掉小数尾部多余的 0 和孤立小数点
 * （0.00→0、1.50M→1.5M、1.45M/30.08 不变）。
 */
public class VolValueFormatter implements IValueFormatter {

    private final String baseFormat;

    public VolValueFormatter(String baseFormat) {
        this.baseFormat = (baseFormat == null || baseFormat.isEmpty()) ? "%.3f" : baseFormat;
    }

    private static String trimZeros(String s) {
        if (s.indexOf('.') < 0) return s;
        int end = s.length();
        while (end > 0 && s.charAt(end - 1) == '0') end--;
        if (end > 0 && s.charAt(end - 1) == '.') end--;
        return s.substring(0, end);
    }

    @Override
    public String format(double value) {
        if (value > 10000 && value < 999999) {
            return trimZeros(String.format(Locale.US, baseFormat, value / 1000)) + "K";
        }
        if (value > 1000000) {
            return trimZeros(String.format(Locale.US, baseFormat, value / 1000000)) + "M";
        }
        return trimZeros(String.format(Locale.US, baseFormat, value));
    }
}
