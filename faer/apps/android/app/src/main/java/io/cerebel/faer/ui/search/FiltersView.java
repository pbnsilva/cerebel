package io.cerebel.faer.ui.search;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.ExpandableListView;

import com.crystal.crystalrangeseekbar.interfaces.OnRangeSeekbarFinalValueListener;


public class FiltersView extends ExpandableListView implements OnRangeSeekbarFinalValueListener, CompoundButton.OnCheckedChangeListener, View.OnClickListener {
    private SortByChangeListener sortByChangeListener;
    private PriceChangeListener priceChangeListener;
    private LocationChangeListener locationChangeListener;

    private int lastExpandedPosition = -1;

    public FiltersView(Context context, AttributeSet attrs) {
        super(context, attrs);

        setOnGroupExpandListener(new OnGroupExpandListener() {
            @Override
            public void onGroupExpand(int groupPosition) {
                if (lastExpandedPosition != -1 && groupPosition != lastExpandedPosition) {
                    collapseGroup(lastExpandedPosition);
                }
                lastExpandedPosition = groupPosition;
            }
        });
    }

    public void setOnSortByChangeListener(SortByChangeListener listener) {
        sortByChangeListener = listener;
    }

    public void setOnPriceChangeListener(PriceChangeListener listener) {
        priceChangeListener = listener;
    }

    public void setOnLocationChangeListener(LocationChangeListener listener) {
        locationChangeListener = listener;
    }

    @Override
    public void onCheckedChanged(CompoundButton compoundButton, boolean isChecked) {
        locationChangeListener.onLocationChange(compoundButton, isChecked);
    }

    @Override
    public void onClick(View view) {
        sortByChangeListener.onSortByChange(SortBy.values()[Integer.valueOf((String) view.getTag())]);
    }

    @Override
    public void finalValue(Number minValue, Number maxValue) {
        priceChangeListener.onPriceChange(minValue.intValue(), maxValue.intValue());
    }

    public static abstract class SortByChangeListener {
        public abstract void onSortByChange(SortBy value);
    }

    public static abstract class PriceChangeListener {
        public abstract void onPriceChange(int from, int to);
    }

    public static abstract class LocationChangeListener {
        public abstract void onLocationChange(CompoundButton button, boolean isEnabled);
    }
}
