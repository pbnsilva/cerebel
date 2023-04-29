package io.cerebel.faer.ui.freshlooks.adapters;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Typeface;
import android.location.Location;
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

import java.util.ArrayList;
import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.FreshLooksItem;
import io.cerebel.faer.ui.product.ProductDetailActivity;
import io.nlopez.smartlocation.SmartLocation;


/**
 * Created by pedro on 16.02.18.
 */
public class FreshLooksGridViewAdapter extends BaseAdapter {

    private final List<FreshLooksItem> records = new ArrayList<>();

    private final int[] imgIds = {
            R.id.image_view_0,
            R.id.image_view_1,
            R.id.image_view_2,
            R.id.image_view_3,
            R.id.image_view_4,
            R.id.image_view_5
    };

    private final int[] txtIds= {
            R.id.text_view_0,
            R.id.text_view_1,
            R.id.text_view_2,
            R.id.text_view_3,
            R.id.text_view_4,
            R.id.text_view_5
    };

    private final Activity context;
    private final int numberOfGridItems = 6;
    private final Typeface mBoldFont;

    public FreshLooksGridViewAdapter(Activity context) {
        this.context = context;
        this.mBoldFont = Typeface.createFromAsset(context.getAssets(), "fonts/Montserrat-ExtraBold.ttf");
    }

    public void addItems(List<FreshLooksItem> feed) {
        records.addAll(feed);
        notifyDataSetChanged();
    }

    public void clear() {
        records.clear();
        notifyDataSetChanged();
    }

    @Override
    public int getCount() {
        return 1 + records.size() / numberOfGridItems;
    }

    @Override
    public Object getItem(int position) {
        return null;
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, final View convertView, ViewGroup parent) {

        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View gridView;
        position = position * numberOfGridItems;

        if (convertView == null) {
            // get layout from mobile.xml
            gridView = inflater.inflate(R.layout.view_grid_tile_feed, null);
        } else {
            gridView = convertView;
        }

        addFreshLooksHeader(gridView, position);

        //setting the images to each image view in the grid
        for (int currentViewIndex = 0; currentViewIndex < numberOfGridItems; currentViewIndex++) {

            final int currentItem = position + currentViewIndex;
            //out of bounds index for record
            if (currentItem >= records.size()) {
                break;
            }
            addProduct(currentItem, currentViewIndex, gridView);
        }

        return gridView;
    }

    /**
     * Finds the image view loads the current product at that view.
     * Sets up the progress bar (loading wheel).
     * Sets up an on click listener. If clicked, opens a new activity to show
     * more information about the product.
     *
     * @param currentItem      index of the current product from the feed
     * @param currentViewIndex index of the image view in the gridView row
     * @param gridView         current grid view row
     */
    private void addProduct(int currentItem, int currentViewIndex, View gridView) {
        int currentId = imgIds[currentViewIndex];
        final FreshLooksItem item = records.get(currentItem);

        ImageView imageView = gridView.findViewById(currentId);
        imageView.setAdjustViewBounds(true);
        imageView.setImageDrawable(null);

        // promotion label
        TextView textView = gridView.findViewById(txtIds[currentViewIndex]);
        textView.setTypeface(mBoldFont);
        if(!item.getProduct().getPromotion().equals("")) {
            textView.setText(item.getProduct().getPromotion());
            textView.setVisibility(View.VISIBLE);
        } else {
            textView.setVisibility(View.GONE);
        }

        final String initialImageUrl = item.getImageURL();

        CircularProgressDrawable circularProgressDrawable = new CircularProgressDrawable(context);
        circularProgressDrawable.setStrokeWidth(10 / context.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setCenterRadius(60 / context.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setColorSchemeColors(context.getResources().getColor(R.color.progressBar));
        circularProgressDrawable.start();

        Glide.with(gridView)
                .load(initialImageUrl)
                .thumbnail(0.1f)
                .apply(new RequestOptions().placeholder(circularProgressDrawable))
                .into(imageView);

        imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Class destinationActivity = ProductDetailActivity.class;
                Intent startProductActivityIntent = new Intent(context, destinationActivity);
                startProductActivityIntent.putExtra("screen_origin", context.getClass().getSimpleName());
                startProductActivityIntent.putExtra("item", item.getProduct());
                Location lastLocation = SmartLocation.with(context).location().getLastLocation();
                if (lastLocation != null) {
                    startProductActivityIntent.putExtra("lat", lastLocation.getLatitude());
                    startProductActivityIntent.putExtra("lng", lastLocation.getLongitude());
                }
                context.startActivity(startProductActivityIntent);

            }
        });
    }

    /**
     * Add the fresh look text view at the top of the feed.
     * Puts the text view on the first row and removes it from any other view.
     *
     * @param gridView
     * @param position
     */
    private void addFreshLooksHeader(View gridView, int position) {

        LinearLayout parentLinearLayout = gridView.findViewById(R.id.parent_linear_layout);
        if (position == 0 && parentLinearLayout.getChildCount() == 2) {
            TextView freshLooksTextView = new TextView(context);
            freshLooksTextView.setText(context.getString(R.string.freshLooks));
            freshLooksTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 25);
            freshLooksTextView.setTypeface(mBoldFont);

            LinearLayout.LayoutParams freshLooksLayout = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.MATCH_PARENT);
            int density = (int) context.getResources().getDisplayMetrics().density;
            freshLooksLayout.setMargins(20 * density, 35 * density, 0, 35 * density);
            freshLooksTextView.setLayoutParams(freshLooksLayout);
            freshLooksTextView.setTextColor(context.getColor(R.color.colorPrimaryDark));

            parentLinearLayout.addView(freshLooksTextView, 0);
        }

        if (position != 0 && parentLinearLayout.getChildCount() != 2) {
            parentLinearLayout.removeViewAt(0);
        }

    }
}

