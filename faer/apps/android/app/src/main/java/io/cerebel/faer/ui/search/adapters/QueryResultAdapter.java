package io.cerebel.faer.ui.search.adapters;

import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.location.Location;
import android.os.AsyncTask;
import androidx.annotation.NonNull;
import androidx.swiperefreshlayout.widget.CircularProgressDrawable;
import androidx.recyclerview.widget.RecyclerView;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.widget.CompoundButton;
import android.widget.HorizontalScrollView;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

import io.cerebel.faer.MainActivity;
import io.cerebel.faer.R;
import io.cerebel.faer.data.local.DatabaseHelper;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.model.Store;
import io.cerebel.faer.data.model.WishlistProduct;
import io.cerebel.faer.data.remote.AppEventLogger;
import io.cerebel.faer.ui.brand.BrandActivity;
import io.cerebel.faer.ui.common.WebStoreActivity;
import io.cerebel.faer.ui.product.MapActivity;
import io.cerebel.faer.ui.search.QueryResultActivity;
import io.cerebel.faer.util.RateThisApp;

public class QueryResultAdapter extends RecyclerView.Adapter<QueryResultAdapter.ResultItemViewHolder> {
    private final Typeface mBoldFont;
    private final Typeface mExtraBoldFont;
    private final Typeface mRegularFont;
    private final Typeface mOpenSansFont;

    private List<Product> mItems;
    private final QueryResultActivity mContext;

    public QueryResultAdapter(QueryResultActivity ctx) {
        mContext = ctx;

        mBoldFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_bold));
        mExtraBoldFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_extra_bold));
        mRegularFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_medium));
        mOpenSansFont = Typeface.createFromAsset(ctx.getAssets(), ctx.getString(R.string.font_open_sans));
    }

   public void addItems(List<Product> items) {
        if(mItems == null) {
            mItems = new ArrayList<>();
        }

        mItems.addAll(items);
        notifyDataSetChanged();
   }

   public void clear() {
        mItems.clear();
   }

    @NonNull
    @Override
    public ResultItemViewHolder onCreateViewHolder(@NonNull ViewGroup viewGroup, int i) {
        LinearLayout v = (LinearLayout) LayoutInflater.from(viewGroup.getContext())
                .inflate(R.layout.view_search_result_product, viewGroup, false);

        v.getLayoutParams().height = (int)(Resources.getSystem().getDisplayMetrics().heightPixels * 0.9);

        return new ResultItemViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ResultItemViewHolder resultItemViewHolder, int i) {
        final Product item = mItems.get(i);

        if (mContext.mCurrentLocation != null) {
            final List<Store> nearbyStores = getNearStores(item.getStores());
            if (nearbyStores.size() > 0) {
                ImageButton locationButton = resultItemViewHolder.mView.findViewById(R.id.location_button);
                locationButton.setVisibility(View.VISIBLE);
                locationButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        Class destinationActivity = MapActivity.class;
                        Intent startProductActivityIntent = new Intent(mContext, destinationActivity);

                        Location centerLocation = getMapCenter(nearbyStores);

                        double lat = centerLocation.getLatitude();
                        double lon = centerLocation.getLongitude();

                        startProductActivityIntent.putExtra(mContext.getString(R.string.nearStoresKey), (ArrayList<Store>) nearbyStores);
                        startProductActivityIntent.putExtra(mContext.getString(R.string.centerLat), lat);
                        startProductActivityIntent.putExtra(mContext.getString(R.string.centerLon), lon);

                        mContext.startActivity(startProductActivityIntent);
                    }
                });
            }
        }

        final LinearLayout resultList = resultItemViewHolder.mView;
        HorizontalScrollView horizontalScrollView = resultList.findViewById(R.id.horizontal_scroll_view);
        horizontalScrollView.setHorizontalScrollBarEnabled(false);

        LinearLayout horizontalLinearLayout = resultList.findViewById(R.id.horizontal_linear_layout);


        setProductTextLabels(resultList, item);

        LinearLayout productInformationLinearLayout = resultList.findViewById(R.id.product_information_linear_layout);
        productInformationLinearLayout.getLayoutParams().width = Resources.getSystem().getDisplayMetrics().widthPixels;

        /*
         * For each row we are adding several views (Images) to the horizontal linear layout.
         * However, the recycler does not get rid of the added views.
         * Thus, it is necessary to remove the views added to the horizontal linear layout;
         * otherwise they build up in the same row.
         *
         * Notice that we remove all but one view, the remaining view is the view with the product's
         * information.
         */
        int numberOfImageViews = horizontalLinearLayout.getChildCount() - 1;
        for (int viewIndex = 0; viewIndex < numberOfImageViews; viewIndex++) {
            horizontalLinearLayout.removeViewAt(0);
        }

        // limit to 5 images per product
        int totalImages = Math.min(item.getImageURLs().size(), 5);

        for (int imageIndex = totalImages - 1; imageIndex >= 0; imageIndex--) {
            addImageToScrollView(imageIndex, item, horizontalLinearLayout);
        }

        horizontalScrollView.scrollTo(75, 0);

        ToggleButton likeButton = resultList.findViewById(R.id.like_toggle_button);
        CompoundButton.OnCheckedChangeListener onCheckedChangeListener = new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {
                    new QueryResultAdapter.AddToFavoritesTask(mContext).execute(item);
                    RateThisApp.showRateDialogIfNeeded(mContext);
                } else {
                    new QueryResultAdapter.RemoveFromFavoritesTask(mContext).execute(item);
                }

            }
        };

        likeButton.setOnCheckedChangeListener(onCheckedChangeListener);


        new QueryResultAdapter.CheckIfFavorited(mContext, likeButton, onCheckedChangeListener).execute(item.getId());


        List<String> productImages = item.getImageURLs();
        int numberOfImages = productImages.size();

        int imagesSectionSize = numberOfImages * Resources.getSystem().getDisplayMetrics().widthPixels;
        int margin = Resources.getSystem().getDisplayMetrics().widthPixels * 18 / 100;
        final int imageDetailsWidth = imagesSectionSize - margin;
        horizontalScrollView.setOnScrollChangeListener(new View.OnScrollChangeListener() {
            @Override
            public void onScrollChange(View v, int scrollX, int scrollY, int oldScrollX, int oldScrollY) {

                if (scrollX > imageDetailsWidth) {
                    setViewsInvisible(resultList);
                } else {
                    setViewsVisible(resultList);
                }

            }
        });
    }

    private Location getMapCenter(List<Store> stores) {

        double highestLat;
        double lowestLat;
        double highestLon;
        double lowestLon;

        List<Double> lats = new ArrayList<>();
        List<Double> lons = new ArrayList<>();

        for (int storeIndex = 0; storeIndex < stores.size(); storeIndex++) {
            Store currentStore = stores.get(storeIndex);
            lats.add(currentStore.getLat());
            lons.add(currentStore.getLon());

        }

        highestLat = Collections.max(lats);
        lowestLat = Collections.min(lats);
        highestLon = Collections.max(lons);
        lowestLon = Collections.min(lons);

        //Midpoint formula
        double midLat = (highestLat + lowestLat) / 2.0;
        double midLon = (highestLon + lowestLon) / 2.0;

        Location centerLocation = new Location("");
        centerLocation.setLatitude(midLat);
        centerLocation.setLongitude(midLon);

        return centerLocation;

    }


    /**
     * Checks for product store's that are located nearby (determined by a certain radius).
     *
     * @param productStores
     * @return list of stores nearby
     */
    private List<Store> getNearStores(List<Store> productStores) {
        List<Store> nearStores = new ArrayList<>();

        if(productStores == null) {
            return nearStores;
        }

        int MaxRadius = 20000;
        for (int storeIndex = 0; storeIndex < productStores.size(); storeIndex++) {
            Store currentStore = productStores.get(storeIndex);
            double currentStoreLat = currentStore.getLat();
            double currentStoreLon = currentStore.getLon();

            Location currentStoreLocation = new Location("");
            currentStoreLocation.setLatitude(currentStoreLat);
            currentStoreLocation.setLongitude(currentStoreLon);

            float distanceInMeters = mContext.mCurrentLocation.distanceTo(currentStoreLocation);


            if (distanceInMeters < MaxRadius) {
                nearStores.add(currentStore);
            }
        }
        return nearStores;
    }

    private void setViewsInvisible(View view) {
        TextView nameBrandTextView= view.findViewById(R.id.overlay_name_brand_textview);
        nameBrandTextView.setVisibility(View.INVISIBLE);

        TextView priceTextView= view.findViewById(R.id.overlay_price_text_view);
        priceTextView.setVisibility(View.INVISIBLE);

        TextView originalPriceTextView= view.findViewById(R.id.overlay_original_price_text_view);
        originalPriceTextView.setVisibility(View.INVISIBLE);

        ToggleButton likeButton = view.findViewById(R.id.like_toggle_button);
        likeButton.setBackgroundResource(R.drawable.ic_toggle_bg_black);

        ImageButton shareButton = view.findViewById(R.id.share_button);
        shareButton.setBackgroundResource(R.drawable.ic_share_black_solid_24dp);

        ImageButton shopButton = view.findViewById(R.id.shop_button);
        shopButton.setBackgroundResource(R.drawable.ic_shopping_basket_black_solid_24dp);

        ImageButton locationButton = view.findViewById(R.id.location_button);
        locationButton.setBackgroundResource(R.drawable.ic_location_black_24dp);
    }

    private void setViewsVisible(View view) {
        TextView nameBrandTextView= view.findViewById(R.id.overlay_name_brand_textview);
        nameBrandTextView.setVisibility(View.VISIBLE);

        TextView priceTextView= view.findViewById(R.id.overlay_price_text_view);
        priceTextView.setVisibility(View.VISIBLE);

        TextView originalPriceTextView= view.findViewById(R.id.overlay_original_price_text_view);
        originalPriceTextView.setVisibility(View.VISIBLE);

        ToggleButton likeButton = view.findViewById(R.id.like_toggle_button);
        likeButton.setBackgroundResource(R.drawable.ic_toggle_bg);

        ImageButton shareButton = view.findViewById(R.id.share_button);
        shareButton.setBackgroundResource(R.drawable.ic_share_white_24dp);

        ImageButton shopButton = view.findViewById(R.id.shop_button);
        shopButton.setBackgroundResource(R.drawable.ic_shopping_basket_white_24dp);

        ImageButton locationButton = view.findViewById(R.id.location_button);
        locationButton.setBackgroundResource(R.drawable.ic_location_white_24dp);
    }

    private void setProductTextLabels(final View gridView, final Product item) {
        TextView overlayNameBrandTextView = gridView.findViewById(R.id.overlay_name_brand_textview);
        TextView overlayPriceTextView = gridView.findViewById(R.id.overlay_price_text_view);

        final String productName = item.getName();
        final String productBrand = item.getBrand();
        final String productPrice = getProductPrice(item);
        final String productUrl = item.getURL();

        overlayNameBrandTextView.setText(String.format("%s\nby %s", productName, productBrand));
        overlayNameBrandTextView.setTypeface(mBoldFont);

        overlayPriceTextView.setTypeface(mBoldFont);
        overlayPriceTextView.setText(productPrice);

        TextView overlayOriginalPriceTextView = gridView.findViewById(R.id.overlay_original_price_text_view);
        TextView productOriginalPriceTextView = gridView.findViewById(R.id.original_price_text_view);
        if(item.getOriginalPrice() != null && item.getOriginalPrice().size() > 0) {
            String productOriginalPrice = getProductOriginalPrice(item);

            overlayOriginalPriceTextView.setVisibility(View.VISIBLE);
            overlayOriginalPriceTextView.setTypeface(mBoldFont);
            overlayOriginalPriceTextView.setPaintFlags(overlayOriginalPriceTextView.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
            overlayOriginalPriceTextView.setText(productOriginalPrice);

            productOriginalPriceTextView.setVisibility(View.VISIBLE);
            productOriginalPriceTextView.setPaintFlags(productOriginalPriceTextView.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
            productOriginalPriceTextView.setTypeface(mBoldFont);
            productOriginalPriceTextView.setText(productOriginalPrice);
        } else {
            overlayOriginalPriceTextView.setVisibility(View.GONE);
            productOriginalPriceTextView.setVisibility(View.GONE);
        }

        TextView productNameTextView = gridView.findViewById(R.id.product_name_text_view);
        productNameTextView.setText(item.getName());
        productNameTextView.setTypeface(mExtraBoldFont);
        productNameTextView.setMaxWidth(Resources.getSystem().getDisplayMetrics().widthPixels * 3 / 4);

        TextView productBrandTextView = gridView.findViewById(R.id.brand_text_view);
        productBrandTextView.setTypeface(mRegularFont);
        productBrandTextView.setText(String.format("by %s", item.getBrand()));

        TextView productPriceTextView = gridView.findViewById(R.id.price_text_view);
        productPriceTextView.setTypeface(mExtraBoldFont);
        productPriceTextView.setText(productPrice);

        LinearLayout brandNameLayout = gridView.findViewById(R.id.brand_name_layout);
        brandNameLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent brandIntent = new Intent(mContext, BrandActivity.class);
                MainActivity.leftActivity = true;
                brandIntent.putExtra("brandID", item.getBrandID());
                mContext.startActivity(brandIntent);
            }
        });

        final TextView productDescriptionTextView = gridView.findViewById(R.id.description_text_view);
        productDescriptionTextView.setTypeface(mOpenSansFont);
        productDescriptionTextView.setText(item.getDescription());
        productDescriptionTextView.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
            @Override
            public void onGlobalLayout() {
                TextView priceTv = gridView.findViewById(R.id.price_text_view);
                TextView nameTv = gridView.findViewById(R.id.product_name_text_view);
                TextView brandTv = gridView.findViewById(R.id.brand_text_view);
                int maxHeight = (int)(Resources.getSystem().getDisplayMetrics().heightPixels * 0.8 - ((priceTv.getHeight() + nameTv.getHeight() + brandTv.getHeight())) * 2);
                if(maxHeight > 0) {
                    productDescriptionTextView.setMaxLines(maxHeight / productDescriptionTextView.getLineHeight());
                }
                productDescriptionTextView.getViewTreeObserver().removeOnGlobalLayoutListener(this);

            }
        });

        ImageButton shareButton = gridView.findViewById(R.id.share_button);
        shareButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(Intent.ACTION_SEND);
                intent.setType("text/plain");
                intent.putExtra(Intent.EXTRA_SUBJECT, productName);
                intent.putExtra(Intent.EXTRA_TEXT, productUrl);
                mContext.startActivity(intent);
            }
        });

        ImageButton shopButton = gridView.findViewById(R.id.shop_button);
        shopButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AppEventLogger.getInstance(mContext.getApplicationContext()).logVisitShop(
                        item.getId(),
                        item.getName(),
                        item.getBrand(),
                        item.getPriceInCurrency("eur"),
                        "eur"
                );


                Class destinationActivity = WebStoreActivity.class;
                Intent startWebStore = new Intent(mContext, destinationActivity);
                startWebStore.putExtra("item", item);
                mContext.startActivity(startWebStore);
            }
        });
    }

    private String getProductPrice(Product item) {
        String currency = PreferencesHelper.getInstance(mContext.getApplicationContext()).getCurrency();
        String productPrice = "";
        if (currency.equals(mContext.getString(R.string.shoppingInUsd))) {
            currency = "$ ";
            productPrice = String.valueOf(item.getPriceInCurrency("usd"));
        } else if (currency.equals(mContext.getString(R.string.shoppingInGbp))) {
            currency = "£ ";
            productPrice = String.valueOf(item.getPriceInCurrency("gbp"));
        } else if (currency.equals(mContext.getString(R.string.shoppingInDkk))) {
            currency = "Kr. ";
            productPrice = String.valueOf(item.getPriceInCurrency("dkk"));
        } else if (currency.equals(mContext.getString(R.string.shoppingInEur))) {
            productPrice = String.valueOf(item.getPriceInCurrency("eur"));
            currency = "€ ";
        }
        return currency + productPrice;
    }

    private String getProductOriginalPrice(Product item) {
        String currency = PreferencesHelper.getInstance(mContext.getApplicationContext()).getCurrency();
        String productPrice = "";
        if (currency.equals(mContext.getString(R.string.shoppingInUsd))) {
            currency = "$ ";
            productPrice = String.valueOf(item.getOriginalPriceInCurrency("usd"));
        } else if (currency.equals(mContext.getString(R.string.shoppingInGbp))) {
            currency = "£ ";
            productPrice = String.valueOf(item.getOriginalPriceInCurrency("gbp"));
        } else if (currency.equals(mContext.getString(R.string.shoppingInDkk))) {
            currency = "Kr. ";
            productPrice = String.valueOf(item.getOriginalPriceInCurrency("dkk"));
        } else if (currency.equals(mContext.getString(R.string.shoppingInEur))) {
            productPrice = String.valueOf(item.getOriginalPriceInCurrency("eur"));
            currency = "€ ";
        }
        return currency + productPrice;
    }

    private void addImageToScrollView(int imageIndex, final Product item, LinearLayout horizontalLinearLayout) {
        RelativeLayout relativeLayout = new RelativeLayout(mContext);
        int relativeLayoutWidth = Resources.getSystem().getDisplayMetrics().widthPixels;
        relativeLayout.setLayoutParams(new RelativeLayout.LayoutParams(relativeLayoutWidth, RelativeLayout.LayoutParams.MATCH_PARENT));

        ImageView imageView = new ImageView(mContext);
        final GestureDetector detector = new GestureDetector(mContext, new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onDoubleTap(MotionEvent arg0) {
                Class destinationActivity = WebStoreActivity.class;
                Intent startWebStore = new Intent(mContext, destinationActivity);
                startWebStore.putExtra("item", item);
                mContext.startActivity(startWebStore);
                return false;
            }

            @Override
            public boolean onDown(MotionEvent ev) {
                return true;
            }
        });

        View.OnTouchListener gestureListener = new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                return detector.onTouchEvent(motionEvent);
            }
        };
        imageView.setOnTouchListener(gestureListener);

        RelativeLayout.LayoutParams imageViewRelativeLayout = new RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        imageView.setLayoutParams(imageViewRelativeLayout);
        imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        relativeLayout.addView(imageView);

        String imageUrl = item.getImageURLs().get(imageIndex);

        CircularProgressDrawable circularProgressDrawable = new CircularProgressDrawable(mContext);
        circularProgressDrawable.setStrokeWidth(10 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setCenterRadius(60 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setColorSchemeColors(mContext.getResources().getColor(R.color.progressBar));
        circularProgressDrawable.start();
        Glide.with(relativeLayout).load(imageUrl).thumbnail(0.1f).apply(new RequestOptions().placeholder(circularProgressDrawable)).into(imageView);

        horizontalLinearLayout.addView(relativeLayout, 0);

    }

    @Override
    public int getItemCount() {
        if(mItems == null) {
            return 0;
        }
        return mItems.size();
    }

    public class ResultItemViewHolder extends RecyclerView.ViewHolder {
        private final LinearLayout mView;

        ResultItemViewHolder(@NonNull LinearLayout itemView) {
            super(itemView);
            mView = itemView;
        }
    }

    class AddToFavoritesTask extends AsyncTask<Product, Void, Void> {

        final Context context;

        AddToFavoritesTask(Context context) {
            this.context = context;
        }

        @Override
        protected Void doInBackground(Product... items) {
            Product item = items[0];

            Date date = new Date();
            DatabaseHelper.getInstance(context).addToFavorites(new WishlistProduct(item, date));

            AppEventLogger.getInstance(mContext.getApplicationContext()).logAddToWishlist(
                    item.getId(),
                    item.getName(),
                    item.getBrand(),
                    item.getPriceInCurrency("eur"),
                    "eur"
            );

            RateThisApp.incrementLikesCount(context);

            return null;
        }

    }

    class RemoveFromFavoritesTask extends AsyncTask<Product, Void, Void> {

        final Context context;

        RemoveFromFavoritesTask(Context context) {
            this.context = context;
        }

        @Override
        protected Void doInBackground(Product... items) {
            Product item = items[0];
            AppEventLogger.getInstance(context).logRemoveFromWishlist(item.getId());
            DatabaseHelper.getInstance(context).deleteFromFavorites(item.getId());
            return null;
        }

    }

    class CheckIfFavorited extends AsyncTask<String, Void, Boolean> {

        final Context context;
        final ToggleButton toggleButton;
        final CompoundButton.OnCheckedChangeListener onCheckedChangeListener;

        CheckIfFavorited(Context context, ToggleButton toggleButton, CompoundButton.OnCheckedChangeListener onCheckedChangeListener) {
            this.context = context;
            this.toggleButton = toggleButton;
            this.onCheckedChangeListener = onCheckedChangeListener;
        }

        @Override
        protected Boolean doInBackground(String... strings) {
            String id = strings[0];
            return DatabaseHelper.getInstance(context).getItem(id) != null;
        }

        @Override
        protected void onPostExecute(Boolean exists) {
            super.onPostExecute(exists);
            toggleButton.setOnCheckedChangeListener(null);
            toggleButton.setChecked(exists);
            toggleButton.setOnCheckedChangeListener(onCheckedChangeListener);

        }
    }
}
