package io.cerebel.faer.ui.wishlist.adapters;


import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Typeface;
import androidx.swiperefreshlayout.widget.CircularProgressDrawable;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;

import java.util.List;

import io.cerebel.faer.MainActivity;
import io.cerebel.faer.R;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.model.WishlistProduct;
import io.cerebel.faer.ui.product.ProductDetailActivity;


public class WishlistGridViewAdapter extends BaseAdapter {
    private final Activity context;
    private final List<WishlistProduct> items;

    private final int favoritedToday;
    private final int favoritedThisWeek;
    private final int favoritedLastWeek;
    private final int favoritedSomeTimeAgo;

    private final int totalCount;


    public WishlistGridViewAdapter(Activity context, List<WishlistProduct> items,
                                   int favoritedToday, int favoritedThisWeek,
                                   int favoritedLastWeek, int favoritedSomeTimeAgo) {
        this.favoritedToday = favoritedToday;
        this.favoritedThisWeek = favoritedThisWeek;
        this.favoritedLastWeek = favoritedLastWeek;
        this.favoritedSomeTimeAgo = favoritedSomeTimeAgo;
        this.items = items;
        this.context = context;
        totalCount = roundUpMultipleTwo(this.favoritedToday) + roundUpMultipleTwo(this.favoritedThisWeek) +
                roundUpMultipleTwo(this.favoritedLastWeek) + roundUpMultipleTwo(this.favoritedSomeTimeAgo);
    }

    @Override
    public int getCount() {

        if (items == null) {
            return 0;
        }

        return (totalCount + 1) / 2;
    }

    @Override
    public Object getItem(int position) {
        return null;
    }

    @Override
    public long getItemId(int position) {
        return position;
    }


    private int getMaxIndexTimeFrame(String timeFrame) {

        if (timeFrame.equals("today")) {
            return favoritedToday;
        } else if (timeFrame.equals("this week")) {

            return roundUpMultipleTwo(favoritedToday) + favoritedThisWeek;
        } else if (timeFrame.equals("last week")) {
            return roundUpMultipleTwo(favoritedToday) + roundUpMultipleTwo(favoritedThisWeek) +
                    favoritedLastWeek;

        } else if (timeFrame.equals("sometime ago")) {
            return roundUpMultipleTwo(favoritedToday) + roundUpMultipleTwo(favoritedThisWeek) +
                    roundUpMultipleTwo(favoritedLastWeek) + favoritedSomeTimeAgo;
        }

        return 0;
    }

    private int getItemIndex(String timeFrame, int position) {

        if (timeFrame.equals("today")) {
            return items.size() - 1 - position;
        } else if (timeFrame.equals("this week")) {
            return items.size() - 1 - (position - (roundUpMultipleTwo(favoritedToday) - favoritedToday));

        } else if (timeFrame.equals("last week")) {
            return items.size() - 1 - (position - (roundUpMultipleTwo(favoritedToday) - favoritedToday) -
                    (roundUpMultipleTwo(favoritedThisWeek) - favoritedThisWeek));

        } else if (timeFrame.equals("sometime ago")) {
            return items.size() - 1 - (position - (roundUpMultipleTwo(favoritedToday) - favoritedToday) -
                    (roundUpMultipleTwo(favoritedThisWeek) - favoritedThisWeek) -
                    (roundUpMultipleTwo(favoritedLastWeek) - favoritedLastWeek));
        }
        return 0;
    }

    @Override
    public View getView(int position, final View convertView, ViewGroup parent) {
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View gridView;

        if (convertView == null) {
            // get layout from mobile.xml
            gridView = inflater.inflate(R.layout.view_grid_tile_favorite, null);
        } else {
            gridView = convertView;
        }

        position = position * 2;

        if (position < getMaxIndexTimeFrame("today")) {

            int itemIndex = getItemIndex("today", position);

            final WishlistProduct item = items.get(itemIndex);
            position++;
            setItem(gridView, item, R.id.image_view_0);

            if (position < getMaxIndexTimeFrame("today")) {

                itemIndex = getItemIndex("today", position);

                final WishlistProduct nextIem = items.get(itemIndex);

                setItem(gridView, nextIem, R.id.image_view_1);
            } else {
                removeItem(gridView);
            }

        } else if (position < getMaxIndexTimeFrame("this week")) {

            int itemIndex = getItemIndex("this week", position);

            final WishlistProduct item = items.get(itemIndex);
            position++;
            setItem(gridView, item, R.id.image_view_0);

            if (position < getMaxIndexTimeFrame("this week")) {

                itemIndex = getItemIndex("this week", position);

                final WishlistProduct nextIem = items.get(itemIndex);

                setItem(gridView, nextIem, R.id.image_view_1);
            } else {
                removeItem(gridView);
            }
        } else if (position < getMaxIndexTimeFrame("last week")) {

            int itemIndex = getItemIndex("last week", position);

            final WishlistProduct item = items.get(itemIndex);
            position++;
            setItem(gridView, item, R.id.image_view_0);

            if (position < getMaxIndexTimeFrame("last week")) {

                itemIndex = getItemIndex("last week", position);
                final WishlistProduct nextIem = items.get(itemIndex);

                setItem(gridView, nextIem, R.id.image_view_1);
            } else {
                removeItem(gridView);
            }
        } else if (position < getMaxIndexTimeFrame("sometime ago")) {

            int itemIndex = getItemIndex("sometime ago", position);

            final WishlistProduct item = items.get(itemIndex);
            position++;
            setItem(gridView, item, R.id.image_view_0);

            if (position < getMaxIndexTimeFrame("sometime ago")) {

                itemIndex = getItemIndex("sometime ago", position);
                final WishlistProduct nextIem = items.get(itemIndex);

                setItem(gridView, nextIem, R.id.image_view_1);
            } else {
                removeItem(gridView);
            }
        }

        addHeader(gridView, position - 1);

        return gridView;
    }

    private void removeItem(View gridView) {
        ImageView imageView = gridView.findViewById(R.id.image_view_1);
        imageView.setImageBitmap(null);
        imageView.setOnClickListener(null);
    }

    private void setItem(View gridView, WishlistProduct wishlistProduct, int imageViewId) {
        final Product item = wishlistProduct.getProduct();
        if(item.getImageURLs().isEmpty()) {
            return;
        }

        ImageView imageView = gridView.findViewById(imageViewId);

        imageView.setAdjustViewBounds(true);
        imageView.setImageDrawable(null);
        imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);

        CircularProgressDrawable circularProgressDrawable = new CircularProgressDrawable(context);
        circularProgressDrawable.setStrokeWidth(10 / context.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setCenterRadius(60 / context.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setColorSchemeColors(context.getResources().getColor(R.color.colorAccent));
        circularProgressDrawable.start();
        Glide.with(gridView)
                .load(item.getImageURLs().get(0))
                .thumbnail(0.1f)
                .apply(new RequestOptions().placeholder(circularProgressDrawable))
                .into(imageView);

        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent productDetailIntent = new Intent(context, ProductDetailActivity.class);
                productDetailIntent.putExtra("screen_origin", context.getClass().getSimpleName());
                productDetailIntent.putExtra("item", item);
                MainActivity.leftActivity = true;
                context.startActivity(productDetailIntent);

            }
        });

    }

    private void addHeader(View gridView, int position) {
        LinearLayout parentLinearLayout = gridView.findViewById(R.id.vertical_linear_layout);
        if (requiresHeader(position)) {
            while (parentLinearLayout.getChildCount() != 1) {
                parentLinearLayout.removeViewAt(0);
            }
            Typeface boldFont = Typeface.createFromAsset(context.getAssets(), context.getString(R.string.font_extra_bold));

            LinearLayout titleLayout = new LinearLayout(context);
            titleLayout.setOrientation(LinearLayout.HORIZONTAL);

            TextView freshLooksTextView = new TextView(context);
            freshLooksTextView.setText(headerText(position));
            freshLooksTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 25);
            freshLooksTextView.setTypeface(boldFont);
            freshLooksTextView.setBackgroundColor(context.getResources().getColor(R.color.colorPrimary));
            freshLooksTextView.setTextColor(context.getColor(R.color.colorPrimaryDark));
            titleLayout.addView(freshLooksTextView);

            if (position == 0) {
                float scale = context.getResources().getDisplayMetrics().density;
                ImageView heart = new ImageView(context);
                heart.setImageResource(R.drawable.ic_favorite_heart);
                int dimen = (int) (25 * scale + 0.5f);
                LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(dimen, dimen);
                layoutParams.setMargins((int) (10 * scale + 0.5f), (int) (4 * scale + 0.5f), 0, 0);
                heart.setLayoutParams(layoutParams);
                titleLayout.addView(heart);
            }

            LinearLayout.LayoutParams freshLooksLayout = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT);
            freshLooksLayout.setMargins(40, 60, 0, 60);
            titleLayout.setLayoutParams(freshLooksLayout);

            parentLinearLayout.addView(titleLayout, 0);
            parentLinearLayout.setBackgroundColor(context.getResources().getColor(R.color.colorPrimary));
        }
        if (!requiresHeader(position)) {
            while (parentLinearLayout.getChildCount() != 1) {
                parentLinearLayout.removeViewAt(0);
            }
        }
    }

    private boolean requiresHeader(int position) {

        if (position == 0) { //first row
            return true;
        }
        if (position == roundUpMultipleTwo(favoritedToday)) {
            return true;
        }
        if (position == roundUpMultipleTwo(favoritedToday) + roundUpMultipleTwo(favoritedThisWeek)) {
            return true;
        }
        return position == roundUpMultipleTwo(favoritedToday) + roundUpMultipleTwo(favoritedThisWeek) + roundUpMultipleTwo(favoritedLastWeek);
    }

    private String headerText(int position) {

        if (position < favoritedToday) { //first row

            if (position == 0) {
                return "Today You️";
            }

            return "Today";
        }

        if (position < roundUpMultipleTwo(favoritedToday) + favoritedThisWeek) {

            if (position == 0) {
                return "This Week You️";
            }

            return "This Week";
        }

        if (position < roundUpMultipleTwo(favoritedToday) + roundUpMultipleTwo(favoritedThisWeek) + favoritedLastWeek) {

            if (position == 0) {
                return "Last Week You️";
            }

            return "Last Week";
        }

        if (position == 0) {
            return "Some Time Ago You️";
        }
        return "Some Time Ago";
    }

    private int roundUpMultipleTwo(int x) {
        return ((x + 1) / 2) * 2;
    }


}
