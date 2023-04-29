package io.cerebel.faer.ui.brand.adapters;

import android.content.Context;
import android.content.Intent;
import android.graphics.Typeface;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.util.List;

import io.cerebel.faer.MainActivity;
import io.cerebel.faer.R;
import io.cerebel.faer.data.model.BrandSpotlight;
import io.cerebel.faer.ui.brand.BrandActivity;
import io.cerebel.faer.ui.common.adapters.HorizontalProductsAdapter;

public class BrandSpotlightAdapter extends BaseAdapter {
    private final Context mContext;
    private List<BrandSpotlight> mItems;
    private final Typeface mExtraBoldFont;

    public BrandSpotlightAdapter(Context ctx) {
        mContext = ctx;
        mExtraBoldFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_extra_bold));
    }

    public void setItems(List<BrandSpotlight> items) {
        mItems = items;
    }

    @Override
    public int getCount() {
        if(mItems == null) {
            return 0;
        }
        return mItems.size();
    }

    @Override
    public Object getItem(int i) {
        return null;
    }

    @Override
    public long getItemId(int i) {
        return 0;
    }

    @Override
    public View getView(int i, View view, ViewGroup viewGroup) {
        LayoutInflater inflater = (LayoutInflater) mContext
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        final String brandID = mItems.get(i).getBrandID();
        final String brandName = mItems.get(i).getBrandName();

        if (view == null) {
            view = inflater.inflate(R.layout.brand_spotlight_list_item, null);

            final TextView textView = view.findViewById(R.id.brand_name_text_view);
            textView.setTypeface(mExtraBoldFont);
            textView.setText(brandName);

            RelativeLayout headerLayout = view.findViewById(R.id.brand_header_layout);
            headerLayout.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    Intent brandIntent = new Intent(mContext, BrandActivity.class);
                    MainActivity.leftActivity = true;
                    brandIntent.putExtra("brandID", brandID);
                    mContext.startActivity(brandIntent);
                }
            });

            HorizontalProductsAdapter adapter = new HorizontalProductsAdapter(mContext, mItems.get(i).getProducts());
            RecyclerView recyclerView = view.findViewById(R.id.brand_products_recycler_view);
            recyclerView.setAdapter(adapter);

            LinearLayoutManager horizontalLayoutManagaer = new LinearLayoutManager(mContext, LinearLayoutManager.HORIZONTAL, false);
            recyclerView.setLayoutManager(horizontalLayoutManagaer);
        }

        return view;
    }
}
