package io.cerebel.faer.ui.search.adapters;

import android.content.Context;
import android.content.Intent;
import android.graphics.Typeface;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;

import java.util.List;

import io.cerebel.faer.MainActivity;
import io.cerebel.faer.R;
import io.cerebel.faer.data.model.CategoryTeaser;
import io.cerebel.faer.ui.search.QueryResultActivity;
import io.cerebel.faer.util.Convert;

import static android.content.Context.WINDOW_SERVICE;
import static io.cerebel.faer.ui.search.fragments.SearchFragment.SEARCH_QUERY;

public class SearchCategoriesAdapter extends BaseAdapter {
    private final Context mContext;
    private List<CategoryTeaser> mItems;
    private final Typeface mExtraBoldFont;

    public SearchCategoriesAdapter(Context ctx) {
        mContext = ctx;
        mExtraBoldFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_extra_bold));
    }

    public void setItems(List<CategoryTeaser> items) {
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
    public View getView(final int i, View view, ViewGroup viewGroup) {
        LayoutInflater inflater = (LayoutInflater) mContext
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        View gridView = view;
        if (view == null) {
            gridView = inflater.inflate(R.layout.category_teaser_grid_item, null);

            gridView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    Intent queryIntent = new Intent(mContext, QueryResultActivity.class);
                    MainActivity.leftActivity = true;
                    queryIntent.putExtra(SEARCH_QUERY, mItems.get(i).getTitle());
                    mContext.startActivity(queryIntent);
                }
            });

        }

        DisplayMetrics dm = new DisplayMetrics();
        WindowManager windowManager = (WindowManager) mContext.getSystemService(WINDOW_SERVICE);
        windowManager.getDefaultDisplay().getMetrics(dm);

        int width = (int)(dm.widthPixels - Convert.DpToPixel(52, mContext)) / 2;
        ImageView mImageView = gridView.findViewById(R.id.image_view);
        mImageView.getLayoutParams().width = width;
        mImageView.getLayoutParams().height = width;


        Glide.with(mContext)
                .load(mItems.get(i).getImageURL())
                .thumbnail(0.1f)
                .into(mImageView);

        TextView textView = gridView.findViewById(R.id.text_view);
        textView.setTypeface(mExtraBoldFont);
        textView.setText(mItems.get(i).getTitle());

        return gridView;
    }
}
