package io.cerebel.faer.ui.search;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.os.Parcel;
import android.os.Parcelable;
import androidx.annotation.DrawableRes;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.util.AttributeSet;
import android.view.MotionEvent;

import io.cerebel.faer.R;


public class ClearableAutoCompleteTextView extends androidx.appcompat.widget.AppCompatAutoCompleteTextView
        implements TextWatcher {

    @DrawableRes private static final int DEFAULT_CLEAR_ICON_RES_ID = R.drawable.ic_circle_solid_grey;

    private Drawable mClearIconDrawable;
    private Drawable mStartDrawable;

    private boolean mIsClearIconShown = false;

    private boolean mClearIconDrawWhenFocused = false;

    public ClearableAutoCompleteTextView(Context context) {
        this(context, null);
    }

    public ClearableAutoCompleteTextView(Context context, AttributeSet attrs) {
        this(context, attrs, android.R.attr.autoCompleteTextViewStyle);
    }

    public ClearableAutoCompleteTextView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(attrs, defStyleAttr);
    }

    private void init(AttributeSet attrs, int defStyle) {
        // Load attributes
        final TypedArray a =
                getContext().obtainStyledAttributes(attrs, R.styleable.ClearableAutoCompleteTextView,
                        defStyle, 0);

        if (a.hasValue(R.styleable.ClearableAutoCompleteTextView_clearIconDrawable)) {
            mClearIconDrawable =
                    a.getDrawable(R.styleable.ClearableAutoCompleteTextView_clearIconDrawable);
            if (mClearIconDrawable != null) {
                mClearIconDrawable.setCallback(this);
            }
        }

        mClearIconDrawWhenFocused =
                a.getBoolean(R.styleable.ClearableEditText_clearIconDrawWhenFocused, true);

        mStartDrawable = a.getDrawable(R.styleable.ClearableAutoCompleteTextView_drawableStart);

        a.recycle();
    }

    @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {
        // no operation
    }

    @Override public void afterTextChanged(Editable s) {
    }

    @Override public Parcelable onSaveInstanceState() {
        Parcelable superState = super.onSaveInstanceState();
        return mIsClearIconShown ? new ClearIconSavedState(superState) : superState;
    }

    @Override public void onRestoreInstanceState(Parcelable state) {
        if (!(state instanceof ClearIconSavedState)) {
            super.onRestoreInstanceState(state);
            return;
        }
        ClearIconSavedState savedState = (ClearIconSavedState) state;
        super.onRestoreInstanceState(savedState.getSuperState());
        mIsClearIconShown = savedState.isClearIconShown();
        showClearIcon(mIsClearIconShown);
    }

    @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
        if (hasFocus()) {
            showClearIcon(!TextUtils.isEmpty(s));
        }
    }

    @Override
    protected void onFocusChanged(boolean focused, int direction, Rect previouslyFocusedRect) {
        showClearIcon(
                (!mClearIconDrawWhenFocused || focused) && !TextUtils.isEmpty(getText().toString()));
        super.onFocusChanged(focused, direction, previouslyFocusedRect);
    }

    @SuppressLint("ClickableViewAccessibility") @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (isClearIconTouched(event)) {
            setText(null);
            event.setAction(MotionEvent.ACTION_CANCEL);
            showClearIcon(false);
            return false;
        }
        return super.onTouchEvent(event);
    }

    private boolean isClearIconTouched(MotionEvent event) {
        if (!mIsClearIconShown) {
            return false;
        }

        final int touchPointX = (int) event.getX();

        final int widthOfView = getWidth();
        final int compoundPaddingRight = getCompoundPaddingRight();

        return touchPointX >= widthOfView - compoundPaddingRight;
    }

    private void showClearIcon(boolean show) {
        if (show) {
            // show icon on the right
            if (mClearIconDrawable != null) {
                setCompoundDrawablesWithIntrinsicBounds(mStartDrawable, null, mClearIconDrawable, null);
            } else {
                setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_baseline_search_24px, 0, DEFAULT_CLEAR_ICON_RES_ID, 0);
            }
        } else {
            // remove icon
            setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_baseline_search_24px, 0, 0, 0);
        }
        mIsClearIconShown = show;
    }

    protected static class ClearIconSavedState extends BaseSavedState {

        public static final Creator<ClearIconSavedState> CREATOR =
                new Creator<ClearIconSavedState>() {
                    @Override public ClearIconSavedState createFromParcel(Parcel source) {
                        return new ClearIconSavedState(source);
                    }

                    @Override public ClearIconSavedState[] newArray(int size) {
                        return new ClearIconSavedState[size];
                    }
                };
        private final boolean mIsClearIconShown;

        private ClearIconSavedState(Parcel source) {
            super(source);
            mIsClearIconShown = source.readByte() != 0;
        }

        ClearIconSavedState(Parcelable superState) {
            super(superState);
            mIsClearIconShown = true;
        }

        @Override public void writeToParcel(Parcel out, int flags) {
            super.writeToParcel(out, flags);
            out.writeByte((byte) (mIsClearIconShown ? 1 : 0));
        }

        boolean isClearIconShown() {
            return mIsClearIconShown;
        }
    }
}
