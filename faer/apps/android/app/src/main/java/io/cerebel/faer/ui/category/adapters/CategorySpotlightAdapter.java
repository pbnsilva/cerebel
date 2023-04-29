package io.cerebel.faer.ui.category.adapters;

import android.content.Context;
import android.graphics.Typeface;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.CategoryProducts;
import io.cerebel.faer.ui.common.adapters.HorizontalProductsAdapter;

public class CategorySpotlightAdapter extends BaseAdapter {
    private final Context mContext;
    private List<CategoryProducts> mCategoryProducts;
    private final Typeface mExtraBoldFont;

    public CategorySpotlightAdapter(Context ctx) {
        mContext = ctx;
        mExtraBoldFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_extra_bold));
    }

    public void setItems(List<CategoryProducts> categoryProducts) {
        mCategoryProducts = categoryProducts;
    }

    @Override
    public int getCount() {
        if(mCategoryProducts == null) {
            return 0;
        }
        return mCategoryProducts.size();
    }

    public void clear() {
        mCategoryProducts.clear();
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

        final String categoryName = mCategoryProducts.get(i).getCategoryName();

        if (view == null) {
            view = inflater.inflate(R.layout.category_spotlight_list_item, null);

            final TextView textView = view.findViewById(R.id.category_name_text_view);
            textView.setTypeface(mExtraBoldFont);
            textView.setText(categoryName.substring(0, 1).toUpperCase() + categoryName.substring(1));

            HorizontalProductsAdapter adapter = new HorizontalProductsAdapter(mContext, mCategoryProducts.get(i).getProducts());
            RecyclerView recyclerView = view.findViewById(R.id.category_products_recycler_view);
            recyclerView.setAdapter(adapter);

            LinearLayoutManager horizontalLayoutManager = new LinearLayoutManager(mContext, LinearLayoutManager.HORIZONTAL, false);
            recyclerView.setLayoutManager(horizontalLayoutManager);
        }

        return view;
    }
}
