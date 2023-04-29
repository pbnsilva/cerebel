package io.cerebel.faer.ui.search.adapters;

import android.content.Context;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseExpandableListAdapter;
import android.widget.ImageView;
import android.widget.RadioButton;
import android.widget.Switch;
import android.widget.TextView;

import com.crystal.crystalrangeseekbar.interfaces.OnRangeSeekbarChangeListener;
import com.crystal.crystalrangeseekbar.widgets.CrystalRangeSeekbar;

import java.util.Currency;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.ui.search.FiltersView;
import io.cerebel.faer.ui.search.QueryResultActivity;


public class FiltersAdapter extends BaseExpandableListAdapter implements OnRangeSeekbarChangeListener {

    private final Context context;
    private final String[] titles = {"Sort by", "Price", "Location"};
    private final View[] views = {null, null, null};
    private final Map<String, String> currencySymbols;
    private final Typeface boldFont;
    private final Typeface regularFont;

    public FiltersAdapter(Context context) {
        this.context = context;

        currencySymbols = new HashMap<>();
        currencySymbols.put("eur", Currency.getInstance("eur").getSymbol());
        currencySymbols.put("usd", Currency.getInstance("usd").getSymbol());
        currencySymbols.put("gbp", Currency.getInstance("gbp").getSymbol());
        currencySymbols.put("dkk", Currency.getInstance("dkk").getSymbol());

        boldFont = Typeface.createFromAsset(context.getAssets(), context.getString(R.string.font_extra_bold));
        regularFont = Typeface.createFromAsset(context.getAssets(), context.getString(R.string.font_medium));
    }

    @Override
    public Object getChild(int listPosition, int expandedListPosition) {
        return null;
    }

    @Override
    public long getChildId(int listPosition, int expandedListPosition) {
        return expandedListPosition;
    }

    @Override
    public View getChildView(int listPosition, final int expandedListPosition,
                             boolean isLastChild, View convertView, ViewGroup parent) {
        if (listPosition == 0) {
            if (views[listPosition] == null) {
                LayoutInflater layoutInflater = (LayoutInflater) this.context
                        .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                views[listPosition] = layoutInflater.inflate(R.layout.view_filter_item_sortby, null);

                FiltersView parentView = (FiltersView) parent;

                RadioButton lowToHighRadio = views[listPosition].findViewById(R.id.low_high_radio);
                lowToHighRadio.setTypeface(regularFont);
                lowToHighRadio.setOnClickListener(parentView);

                RadioButton highToLowRadio = views[listPosition].findViewById(R.id.high_low_radio);
                highToLowRadio.setTypeface(regularFont);
                highToLowRadio.setOnClickListener(parentView);

                RadioButton relevanceRadio = views[listPosition].findViewById(R.id.relevance_radio);
                relevanceRadio.setTypeface(regularFont);
                relevanceRadio.setOnClickListener(parentView);
            }
        } else if (listPosition == 1) {
            CrystalRangeSeekbar seekBar;
            if (views[listPosition] == null) {
                LayoutInflater layoutInflater = (LayoutInflater) this.context
                        .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                views[listPosition] = layoutInflater.inflate(R.layout.view_filter_item_price, null);

                final FiltersView parentView = (FiltersView) parent;
                CrystalRangeSeekbar seekbar = views[listPosition].findViewById(R.id.price_range_bar);
                seekbar.setMinValue((float) Math.floor(QueryResultActivity.mMinPrice / 10) * 10.0f);
                seekbar.setMaxValue((float) Math.ceil(QueryResultActivity.mMaxPrice/ 10) * 10.0f);
                float delta = QueryResultActivity.mMaxPrice- QueryResultActivity.mMinPrice;
                if (delta < 50) {
                    seekbar.setSteps(5.0f);
                }
                seekbar.setOnRangeSeekbarFinalValueListener(parentView);

                // set listener
                seekbar.setOnRangeSeekbarChangeListener(this);

                // set final value listener
                seekbar.setOnRangeSeekbarFinalValueListener(parentView);
            } else {
                CrystalRangeSeekbar seekbar = views[listPosition].findViewById(R.id.price_range_bar);
                float minValue = (float) Math.floor(QueryResultActivity.mMinPrice / 10) * 10.0f;
                float maxValue = (float) Math.ceil(QueryResultActivity.mMaxPrice / 10) * 10.0f;
                seekbar.setMinStartValue(minValue);
                seekbar.setMaxStartValue(maxValue);
                float delta = QueryResultActivity.mMaxPrice - QueryResultActivity.mMinPrice;
                if (delta < 50) {
                    seekbar.setSteps(5.0f);
                }
                valueChanged(minValue, maxValue);
            }
        } else if (listPosition == 2) {
            if (views[listPosition] == null) {
                LayoutInflater layoutInflater = (LayoutInflater) this.context
                        .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                views[listPosition] = layoutInflater.inflate(R.layout.view_filter_item_location, null);

                Switch locationSwitch = views[listPosition].findViewById(R.id.enable_location_switch);
                locationSwitch.setTypeface(regularFont);
                FiltersView parentView = (FiltersView) parent;
                locationSwitch.setOnCheckedChangeListener(parentView);
            }
        }

        return views[listPosition];
    }

    @Override
    public void valueChanged(Number minValue, Number maxValue) {
        // get min and max text view
        TextView tvMin = views[1].findViewById(R.id.price_min_text);
        TextView tvMax = views[1].findViewById(R.id.price_max_text);
        tvMin.setTypeface(regularFont);
        tvMax.setTypeface(regularFont);

        final String currency = PreferencesHelper.getInstance(context).getCurrency();
        if (currency.equals("usd") || currency.equals("gbp")) {
            tvMin.setText(String.format(Locale.ENGLISH, "%s%d", currencySymbols.get(currency), minValue.intValue()));
            tvMax.setText(String.format(Locale.ENGLISH, "%s%d", currencySymbols.get(currency), maxValue.intValue()));
        } else {
            tvMin.setText(String.format(Locale.ENGLISH, "%d%s", minValue.intValue(), currencySymbols.get(currency)));
            tvMax.setText(String.format(Locale.ENGLISH, "%d%s", maxValue.intValue(), currencySymbols.get(currency)));
        }
    }

    @Override
    public int getChildrenCount(int listPosition) {
        return 1;
    }

    @Override
    public Object getGroup(int listPosition) {
        return titles[listPosition];
    }

    @Override
    public int getGroupCount() {
        return titles.length;
    }

    @Override
    public long getGroupId(int listPosition) {
        return listPosition;
    }

    @Override
    public View getGroupView(int listPosition, boolean isExpanded, View convertView, ViewGroup parent) {
        String listTitle = (String) getGroup(listPosition);
        if (convertView == null) {
            LayoutInflater layoutInflater = (LayoutInflater) this.context.
                    getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            convertView = layoutInflater.inflate(R.layout.view_expandable_list_group, null);
        }
        TextView listTitleTextView = convertView.findViewById(R.id.listTitle);
        listTitleTextView.setTypeface(boldFont);
        listTitleTextView.setText(listTitle);

        ImageView icon = convertView.findViewById(R.id.filter_expand_icon);
        if (isExpanded) {
            icon.setImageDrawable(context.getResources().getDrawable(R.drawable.ic_arrow_up_black_24dp));
        } else {
            icon.setImageDrawable(context.getResources().getDrawable(R.drawable.ic_arrow_down_black_24dp));
        }

        return convertView;
    }

    @Override
    public boolean hasStableIds() {
        return false;
    }

    @Override
    public boolean isChildSelectable(int listPosition, int expandedListPosition) {
        return true;
    }
}
