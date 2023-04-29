package io.cerebel.faer.ui.brand.adapters;

import android.content.Context;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import java.util.List;

import io.cerebel.faer.R;

public class TagsAdapter extends ArrayAdapter<String> {
    private final Context mContext;
    private final List<String> mValues;
    private final Typeface mOpenSansFont;

    public TagsAdapter(Context context, List<String> values) {
        super(context, -1, values);
        mContext = context;
        mValues = values;
        mOpenSansFont = Typeface.createFromAsset(mContext.getAssets(), mContext.getString(R.string.font_open_sans));
    }

    @Override
    public View getView(int position, View view, ViewGroup parent) {
        LayoutInflater inflater = (LayoutInflater)mContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        if(view == null) {
            view = inflater.inflate(R.layout.view_tag_item, parent, false);
        }

        String tag = mValues.get(position);

            TextView tagText = view.findViewById(R.id.tag_text);
            tagText.setTypeface(mOpenSansFont);
            tagText.setText(tag.substring(0, 1).toUpperCase() + tag.substring(1));

        int imageRes = getImageResourceForTag(tag);
        if(imageRes != -1) {
            ImageView tagImage = view.findViewById(R.id.tag_image);
            tagImage.setBackgroundResource(imageRes);
        }

        return view;
    }

    private int getImageResourceForTag(String tag) {
        if(tag.equals("vintage")) {
            return R.drawable.ic_criteria_vintage;
        } else if(tag.equals("recycled") || tag.equals("upcycled")) {
            return R.drawable.ic_criteria_recycled;
        } else if(tag.equals("community work") || tag.equals("social cause")) {
            return R.drawable.ic_criteria_socialcause;
        } else if(tag.equals("organic")) {
            return R.drawable.ic_criteria_organicfabrics;
        } else if(tag.equals("vegan")) {
            return R.drawable.ic_criteria_vegan;
        } else if(tag.equals("plastic free")) {
            return R.drawable.ic_criteria_plasticfree;
        } else if(tag.equals("natural fabrics")) {
            return R.drawable.ic_criteria_naturalfabrics;
        } else if(tag.equals("fair trade") || tag.equals("fairtrade")) {
            return R.drawable.ic_criteria_fairtrade;
        } else if(tag.equals("made locally")) {
            return R.drawable.ic_criteria_localproduction;
        } else if(tag.equals("handmade")) {
            return R.drawable.ic_criteria_handcrafted;
        } else if(tag.equals("women empowerment")) {
            return R.drawable.ic_criteria_socialcause;
        } else if(tag.equals("closed loop")) {
            return R.drawable.ic_criteria_closedloop;
        } else if(tag.equals("peta approved")) {
            return R.drawable.ic_criteria_peta;
        } else if(tag.equals("fair working conditions")) {
            return R.drawable.ic_criteria_ethicalfair;
        } else if(tag.equals("gots certified")) {
            return R.drawable.ic_criteria_gots;
        } else if(tag.equals("chemical free")) {
            return R.drawable.ic_criteria_chemicalfree;
        }
        return -1;
    }

    public void clear() {
        super.clear();
        notifyDataSetChanged();
    }
}
