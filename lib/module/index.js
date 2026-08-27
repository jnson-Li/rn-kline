"use strict";

import { useRef, forwardRef, useImperativeHandle } from 'react';
import KlineView, { CrossFollowTouch } from './KlineViewNativeComponent';
import KlineAdapter from "./NativeKlineAdapter.js";
import { jsx as _jsx } from "react/jsx-runtime";
export * from './KlineViewNativeComponent';
export const KLineChart = /*#__PURE__*/forwardRef((props, ref) => {
  const listRef = useRef([]);
  useImperativeHandle(ref, () => ({
    resetData(list, resetShowPosition, resetLastAnim) {
      listRef.current = list;
      KlineAdapter.resetData(list, resetShowPosition, resetLastAnim);
    },
    changeItem(position, data) {
      if (position < 0 || position >= listRef.current.length) return;
      listRef.current[position] = data;
      KlineAdapter.changeItem(position, data);
    },
    changeLast(data) {
      const len = listRef.current.length;
      if (len === 0) return;
  
      // JS 层同步更新最后一根
      listRef.current[len - 1] = data;
  
      // Native 层不再传 index
      KlineAdapter.changeLast(data);
    },
    getConstants: KlineAdapter.getConstants,
    addNewData(data, resetShowPosition) {
      if (!listRef.current.length) return;
      listRef.current.push(data);
      KlineAdapter.addNewData(data, resetShowPosition);
    },
    addHistoryData(list, resetShowPosition) {
      if (!listRef.current.length) return;
      listRef.current = list.concat(listRef.current);
      KlineAdapter.addHistoryData(list, resetShowPosition);
    },
    getData() {
      return listRef.current;
    }
  }));
  return /*#__PURE__*/_jsx(KlineView, {
    crossFollowTouch: CrossFollowTouch.TOUCH_FOLLOW_FINGERS,
    ...props
  });
});
//# sourceMappingURL=index.js.map
