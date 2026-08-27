package com.kline.base;

import android.content.Context;
import android.util.AttributeSet;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.ViewConfiguration;
import android.widget.OverScroller;
import android.widget.RelativeLayout;

import androidx.core.view.GestureDetectorCompat;

import com.kline.utils.Status;

/*************************************************************************
 * Description   :
 *
 * @PackageName  : com.kline.base
 * @FileName     : ScrollAndScaleView.java
 * @Author       : chao
 * @Date         : 2019/4/8
 * @Email        : icechliu@gmail.com
 * @version      : V1
 *************************************************************************/
public abstract class ScrollAndScaleView extends RelativeLayout implements
        GestureDetector.OnGestureListener,
        ScaleGestureDetector.OnScaleGestureListener {
    private static final float PAN_VERTICAL_DOMINANCE_RATIO = 2.0f;

    protected int scrollX = 0;
    protected androidx.core.view.GestureDetectorCompat gestureDetector;
    protected ScaleGestureDetector scaleDetector;

    protected boolean showSelected = false;
    protected boolean forceStopSlid = false;
    protected boolean drawShapeEnable = false;

    protected int selectedIndex = -1;

    protected OverScroller overScroller;

    protected boolean touch = false;

    protected float scaleX = 1;

    protected float scaleXMax = 2f;

    protected float scaleXMin = 0.1f;

    private boolean isMultipleTouch = false;

    private boolean isScrollEnable = true;

    private boolean isScaleEnable = true;

    private int touchSlop;

    private float touchDownX;

    private float touchDownY;

    private boolean panAxisLocked = false;

    private boolean panGestureIsHorizontal = false;

    private boolean panGestureIsVertical = false;

    public ScrollAndScaleView(Context context) {
        super(context);
        init();
    }

    public ScrollAndScaleView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public ScrollAndScaleView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        setWillNotDraw(false);
        gestureDetector = new GestureDetectorCompat(getContext(), this);
        scaleDetector = new ScaleGestureDetector(getContext(), this);
        overScroller = new OverScroller(getContext());
        touchSlop = ViewConfiguration.get(getContext()).getScaledTouchSlop();
    }

    @Override
    public boolean onDown(MotionEvent e) {
        return false;
    }

    @Override
    public void onShowPress(MotionEvent e) {

    }

    public abstract boolean changeDrawShape(MotionEvent e1, MotionEvent e, float distanceX, float distanceY);


    private boolean isTapShow;

    protected @Status.ShowCrossModel int model = Status.SELECT_BOTH;
    @Override
    public boolean onSingleTapUp(MotionEvent e) {

        if (drawShapeEnable) {
            return changeDrawShape(e, e, 0, 0);
        } else {
            switch (model) {
                default:
                case Status.SELECT_NONE:
                case Status.SELECT_PRESS:
                    showSelected = false;
                    return true;
                case Status.SELECT_BOTH:
                    if (!isTapShow && showSelected) {
                        showSelected = false;
                        isTapShow = false;
                    } else {
                        isTapShow = true;
                        showSelected = true;
                        onSelectedChange(e);
                    }
                    return true;
                case Status.SELECT_TOUCHE:
                    showSelected = true;
                    onSelectedChange(e);
                    return true;
            }
        }
    }

    @Override
    public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {

        if (drawShapeEnable) {
            return changeDrawShape(e1, e2, distanceX, distanceY);
        } else {
            if (panGestureIsVertical) {
                return false;
            }
            if (isTapShow) {
                showSelected = false;
                isTapShow = false;
            }
            if (!showSelected && !isMultipleTouch() && isScrollEnable() && panGestureIsHorizontal) {
                scrollBy(Math.round(distanceX), 0);
                return true;
            }
            return false;
        }
    }

    @Override
    public void onLongPress(MotionEvent e) {
        if (!drawShapeEnable) {
            if (model == Status.SELECT_PRESS || model == Status.SELECT_BOTH) {
                showSelected = true;
                onSelectedChange(e);
            }
        }
    }


    public abstract void onSelectedChange(MotionEvent e);

    @Override
    public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {

        if (!showSelected && !isTouch() && isScrollEnable() && panGestureIsHorizontal) {
            overScroller.fling(scrollX, 0
                    , Math.round(velocityX / scaleX / 2), 0,
                    Integer.MIN_VALUE, Integer.MAX_VALUE,
                    0, 0);
        }
        return true;
    }

    @Override
    public void computeScroll() {
        if (overScroller.computeScrollOffset()) {
            if (!isTouch() && isScrollEnable()) {
                scrollTo(overScroller.getCurrX(), overScroller.getCurrY());
            } else {
                overScroller.forceFinished(true);
            }
            invalidate();
        }
    }

    @Override
    public void scrollBy(int x, int y) {
        if (isScrollEnable()) {
            scrollTo(scrollX - Math.round(x / scaleX), 0);
        } else {
            overScroller.forceFinished(true);
        }

    }

    @Override
    public void scrollTo(int x, int y) {
        if (isScrollEnable()) {
            int oldX = scrollX;
            scrollX = x;
            if (scrollX != oldX) {
                onScrollChanged(scrollX, 0, oldX, 0);
            }
        } else {
            overScroller.forceFinished(true);
        }

    }

    @Override
    public boolean onScale(ScaleGestureDetector detector) {
        if (!isScaleEnable()) {
            return false;
        }
        float oldScale = scaleX;
        scaleX *= detector.getScaleFactor();
        if (scaleX < scaleXMin) {
            scaleX = scaleXMin;
        } else if (scaleX > scaleXMax) {
            scaleX = scaleXMax;
        }
        onScaleChanged(scaleX, oldScale);

        return true;
    }

    public float getScaleX() {
        return this.scaleX;
    }

    protected void onScaleChanged(float scale, float oldScale) {
//        invalidate();
    }

    @Override
    public boolean onScaleBegin(ScaleGestureDetector detector) {
        return true;
    }

    @Override
    public void onScaleEnd(ScaleGestureDetector detector) {

    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (event.getPointerCount() > 1) {
            showSelected = false;
            setSelectedIndex(-1);
            panAxisLocked = true;
            panGestureIsHorizontal = true;
            panGestureIsVertical = false;
            getParent().requestDisallowInterceptTouchEvent(true);
        }
        switch (event.getAction() & MotionEvent.ACTION_MASK) {
            case MotionEvent.ACTION_DOWN:
                touchDownX = event.getX();
                touchDownY = event.getY();
                panAxisLocked = false;
                panGestureIsHorizontal = false;
                panGestureIsVertical = false;
                getParent().requestDisallowInterceptTouchEvent(false);
                changeDrawShape(event, null, 0, 0);
                setForceStopSlid(false);
                touch = true;
                break;
            case MotionEvent.ACTION_MOVE:
                // 长按进入选中态后，X/Y 都交给十字线连续跟随；不能再按普通滚动手势
                // 做方向锁，否则首次纵向拖动会清掉选中态，交点无法跟手。
                if (showSelected && !isMultipleTouch()) {
                    getParent().requestDisallowInterceptTouchEvent(true);
                    onSelectedChange(event);
                    break;
                }
                if (!isMultipleTouch() && !lockPanAxisIfNeeded(event)) {
                    return false;
                }
                break;
            case MotionEvent.ACTION_POINTER_UP:
                invalidate();
                break;
            case MotionEvent.ACTION_UP:
                touch = false;
                getParent().requestDisallowInterceptTouchEvent(false);
                changeDrawShape(event, event, 0, 0);
                invalidate();
                resetPanAxisLock();
                break;
            case MotionEvent.ACTION_CANCEL:
                showSelected = false;
                setSelectedIndex(-1);
                touch = false;
                getParent().requestDisallowInterceptTouchEvent(false);
                invalidate();
                resetPanAxisLock();
                break;
            default:
                break;
        }
        isMultipleTouch = event.getPointerCount() > 1;
        if (panGestureIsVertical) {
            return false;
        }
        this.gestureDetector.onTouchEvent(event);
        this.scaleDetector.onTouchEvent(event);
        return true;
    }

    private boolean lockPanAxisIfNeeded(MotionEvent event) {
        if (panAxisLocked) {
            return !panGestureIsVertical;
        }

        float absX = Math.abs(event.getX() - touchDownX);
        float absY = Math.abs(event.getY() - touchDownY);

        if (absX < touchSlop && absY < touchSlop) {
            return true;
        }

        panAxisLocked = true;
        if (absY > absX * PAN_VERTICAL_DOMINANCE_RATIO) {
            panGestureIsVertical = true;
            panGestureIsHorizontal = false;
            touch = false;
            showSelected = false;
            setSelectedIndex(-1);
            getParent().requestDisallowInterceptTouchEvent(false);
            return false;
        }

        panGestureIsHorizontal = true;
        panGestureIsVertical = false;
        getParent().requestDisallowInterceptTouchEvent(true);
        return true;
    }

    private void resetPanAxisLock() {
        panAxisLocked = false;
        panGestureIsHorizontal = false;
        panGestureIsVertical = false;
    }

    public void setSelectedIndex(int selectedIndex) {
        this.selectedIndex = selectedIndex;
    }

    /**
     * 清除选中态（十字线 + 选中信息框）。
     * 选中态在松手后会保留，所以切周期/币对 resetData 时必须主动清掉。
     * isTapShow 是 private，只能在本类清：漏掉它会让下一次长按选中后「单击取消」失效
     * （onSingleTapUp 会走到重新选中分支），且拖动会被误判成取消选中并滚动图表。
     */
    protected void clearSelectedState() {
        showSelected = false;
        isTapShow = false;
        setSelectedIndex(-1);
    }

    /**
     * 是否在触摸中
     *
     * @return bool正在点击
     */
    public boolean isTouch() {
        return touch;
    }

    /**
     * 设置ScrollX
     *
     * @param scrollX
     */
    public void setScrollX(int scrollX) {
        this.scrollX = scrollX;
        scrollTo(scrollX, 0);
    }

    /**
     * 是否是多指触控
     *
     * @return isMultipleTouch
     */
    public boolean isMultipleTouch() {
        return isMultipleTouch;
    }


    public float getScaleXMax() {
        return scaleXMax;
    }

    public float getScaleXMin() {
        return scaleXMin;
    }

    public boolean isScrollEnable() {
        return isScrollEnable;
    }

    public boolean isScaleEnable() {
        return isScaleEnable;
    }

    /**
     * 设置缩放的最大值
     */
    public void setScaleXMax(float scaleXMax) {
        this.scaleXMax = scaleXMax;
    }

    /**
     * 设置缩放的最小值
     */
    public void setScaleXMin(float scaleXMin) {
        this.scaleXMin = scaleXMin;
    }

    /**
     * 设置是否可以滑动
     */
    public void setScrollEnable(boolean scrollEnable) {
        isScrollEnable = scrollEnable;
    }

    /**
     * 设置是否可以缩放
     */
    public void setScaleEnable(boolean scaleEnable) {
        isScaleEnable = scaleEnable;
    }

    public boolean getForceStopSlid() {
        return forceStopSlid;
    }

    public void setForceStopSlid(boolean forceStopSlid) {
        this.forceStopSlid = forceStopSlid;
    }
}
