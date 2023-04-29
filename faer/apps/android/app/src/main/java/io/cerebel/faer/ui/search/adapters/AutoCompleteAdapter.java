package io.cerebel.faer.ui.search.adapters;

import android.content.Context;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

import io.cerebel.faer.R;

public class AutoCompleteAdapter extends BaseAdapter {
    private final Context mContext;
    private final List<String> mItems;
    private final Typeface mExtraBoldFont;

    public AutoCompleteAdapter(Context ctx) {
        mContext = ctx;
        mItems = new ArrayList<>();
        mExtraBoldFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_extra_bold));
    }

    @Override
    public int getCount() {
        return mItems.size();
    }

    @Override
    public Object getItem(int i) {
        return mItems.get(i);
    }

    @Override
    public long getItemId(int i) {
        return 0;
    }

    public void setData(List<String> list) {
        mItems.clear();
        mItems.addAll(list);
    }

    @Override
    public View getView(int i, View view, ViewGroup viewGroup) {
        LayoutInflater inflater = (LayoutInflater) mContext
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        if (view == null) {
            view = inflater.inflate(R.layout.view_suggester_dropdown_item, null);
        }

        TextView textView = view.findViewById(R.id.suggestion_item_textview);
        textView.setText(mItems.get(i));
        textView.setTypeface(mExtraBoldFont);

        return view;
    }
}