import type { NativeProps } from './KlineViewNativeComponent';
import type { KLineEntity, Spec } from './NativeKlineAdapter';
export * from './KlineViewNativeComponent';
export type { KLineEntity } from './NativeKlineAdapter';
export interface KLineChartProps extends NativeProps {
}
export interface KLineChartRef extends Spec {
    getData(): KLineEntity[];
}
export declare const KLineChart: import("react").ForwardRefExoticComponent<KLineChartProps & import("react").RefAttributes<KLineChartRef>>;
//# sourceMappingURL=index.d.ts.map