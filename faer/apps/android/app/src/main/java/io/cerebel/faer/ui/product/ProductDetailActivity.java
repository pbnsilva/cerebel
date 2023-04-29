package io.cerebel.faer.ui.product;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.content.Context;
import android.content.Intent;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.location.Location;
import android.os.AsyncTask;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
import io.cerebel.faer.ui.product.adapters.ProductGalleryAdapter;
import io.cerebel.faer.ui.product.adapters.ProductGridGalleryAdapter;
import io.cerebel.faer.ui.search.QueryResultActivity;
import io.cerebel.faer.util.RateThisApp;

import static io.cerebel.faer.ui.search.fragments.SearchFragment.SEARCH_QUERY;

public class ProductDetailActivity extends AppCompatActivity {
    private Product mItem = null;
    private Location mLocation = null;

    private RelativeLayout categoryLayout;
    private TextView mPromotionTextView;
    private TextView mNameTextView;
    private TextView mPriceTextView;
    private TextView mOriginalPriceTextView;
    private TextView mDescriptionTextView;
    private TextView mImagePageTextView;
    private TextView mProductBrandName;
    private TextView mProductCategoryName;

    private ToggleButton mLikeButton;

    private ProductGalleryAdapter mImagesAdapter;
    private ProductGridGalleryAdapter mMoreByBrandAdapter, mMoreByCategoryAdapter;

    private Typeface mBoldFont;
    private Typeface mExtraBoldFont;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_product_detail);

        mBoldFont = Typeface.createFromAsset(getAssets(), getString(R.string.font_bold));
        mExtraBoldFont = Typeface.createFromAsset(getAssets(), getString(R.string.font_extra_bold));
        Typeface mRegularFont = Typeface.createFromAsset(getAssets(), getString(R.string.font_medium));
        Typeface mOpenSansFont = Typeface.createFromAsset(getAssets(), getString(R.string.font_open_sans));

        // toolbar buttons
        ImageButton shopButton = findViewById(R.id.shop_button);
        shopButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AppEventLogger.getInstance(getApplicationContext()).logVisitShop(
                        mItem.getId(),
                        mItem.getName(),
                        mItem.getBrand(),
                        mItem.getPriceInCurrency("eur"),
                        "eur"
                );
                navigateToProductPage();
            }
        });

        ImageButton shareButton = findViewById(R.id.share_button);
        shareButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AppEventLogger.getInstance(getApplicationContext()).logShare(
                        mItem.getId(),
                        mItem.getName(),
                        mItem.getBrand(),
                        mItem.getPriceInCurrency("eur"),
                        "eur"
                );

                Intent intent = new Intent(Intent.ACTION_SEND);
                intent.setType("text/plain");
                intent.putExtra(Intent.EXTRA_SUBJECT, mItem.getName());
                intent.putExtra(Intent.EXTRA_TEXT, mItem.getShareURL());
                startActivity(intent);
            }
        });

        mLikeButton = findViewById(R.id.like_toggle_button);

        LinearLayout mBackLayout = findViewById(R.id.back_layout);
        mBackLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onBackPressed();
            }
        });

        ImageButton backButton = findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onBackPressed();
            }
        });

        // promotion label
        mPromotionTextView = findViewById(R.id.product_promotion);
        mPromotionTextView.setVisibility(View.VISIBLE);
        mPromotionTextView.setTypeface(mExtraBoldFont);

        //product name and price
        mNameTextView = findViewById(R.id.product_name);
        mNameTextView.setTypeface(mExtraBoldFont);

        mPriceTextView = findViewById(R.id.product_price);
        mPriceTextView.setTypeface(mBoldFont);

        mOriginalPriceTextView = findViewById(R.id.product_original_price);

        // product brand
        TextView productBrandTitle = findViewById(R.id.product_brand_title);
        productBrandTitle.setTypeface(mRegularFont);

        mProductBrandName = findViewById(R.id.product_brand);
        mProductBrandName.setTypeface(mExtraBoldFont);

        RelativeLayout brandLayout = findViewById(R.id.product_brand_layout);
        brandLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent queryIntent = new Intent(ProductDetailActivity.this, BrandActivity.class);
                MainActivity.leftActivity = true;
                queryIntent.putExtra("brandID", mItem.getBrandID());
                startActivity(queryIntent);
            }
        });

        // product category
        TextView productCategoryTitle = findViewById(R.id.product_category_title);
        productCategoryTitle.setTypeface(mRegularFont);

        mProductCategoryName = findViewById(R.id.product_category);
        mProductCategoryName.setTypeface(mExtraBoldFont);

        categoryLayout = findViewById(R.id.product_category_layout);
        categoryLayout.setVisibility(View.GONE);
        categoryLayout.setOnClickListener(new View.OnClickListener() {
                                      @Override
                                      public void onClick(View view) {
                Intent queryIntent = new Intent(ProductDetailActivity.this, QueryResultActivity.class);
                MainActivity.leftActivity = true;
                queryIntent.putExtra(SEARCH_QUERY, mItem.getCategories().get(0));
                startActivity(queryIntent);
        }
    });

        View divider = findViewById(R.id.divider);
        divider.setVisibility(View.VISIBLE);

        // product images
        RecyclerView mImagesRecyclerView = findViewById(R.id.product_images_recyclerview);

        DisplayMetrics dm = new DisplayMetrics();
        WindowManager windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        windowManager.getDefaultDisplay().getMetrics(dm);

        ViewGroup.LayoutParams params = mImagesRecyclerView.getLayoutParams();
        params.height = (int) Math.round(dm.heightPixels * 0.9);
        mImagesRecyclerView.setLayoutParams(params);

        RecyclerView.LayoutManager mImagesLayoutManager = new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false);
        mImagesRecyclerView.setLayoutManager(mImagesLayoutManager);

        mImagesAdapter = new ProductGalleryAdapter(ProductDetailActivity.this);
        mImagesRecyclerView.setAdapter(mImagesAdapter);
        mImagesRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                if(mImagePageTextView.getVisibility() == View.VISIBLE) {
                    if(dx > 0) {
                        mImagePageTextView.animate()
                                .alpha(0.0f)
                                .setDuration(5000)
                                .setListener(new AnimatorListenerAdapter() {
                                    @Override
                                    public void onAnimationEnd(Animator animation) {
                                        super.onAnimationEnd(animation);
                                        mImagePageTextView.setVisibility(View.GONE);
                                    }
                                });
                    }
                }
            }
        });

        mImagePageTextView = findViewById(R.id.image_page_textview);
        mImagePageTextView.setTypeface(mRegularFont);

        // product description
        mDescriptionTextView = findViewById(R.id.product_description);
        mDescriptionTextView.setTypeface(mOpenSansFont);

        // visit shop button
        Button mVisitShopButton = findViewById(R.id.visit_shop_button);
        mVisitShopButton.setTypeface(mBoldFont);
        mVisitShopButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AppEventLogger.getInstance(getApplicationContext()).logVisitShop(
                        mItem.getId(),
                        mItem.getName(),
                        mItem.getBrand(),
                        mItem.getPriceInCurrency("eur"),
                        "eur"
                );

                navigateToProductPage();
            }
        });
    }

    @Override
    protected void onStart() {
        super.onStart();

        if(getIntent().getExtras() != null) {
            mItem = (Product) getIntent().getExtras().getSerializable("item");

            if(getIntent().hasExtra("screen_origin")) {
                AppEventLogger.getInstance(getApplicationContext()).logViewProduct(
                        mItem.getId(),
                        mItem.getName(),
                        mItem.getBrand(),
                        mItem.getPriceInCurrency("eur"),
                        "eur",
                        getIntent().getStringExtra("screen_origin")
                );
            }
        }

        mImagesAdapter.setImages(mItem.getImageURLs());
        mImagesAdapter.notifyDataSetChanged();

        new CheckIfLiked(this, mLikeButton, mItem).execute(mItem.getId());

        // promotion label
        if(!mItem.getPromotion().equals("")) {
            mPromotionTextView.setText(mItem.getPromotion());
        }

        //product name and price
        mNameTextView.setText(mItem.getName());

        if(mItem.getOriginalPrice() != null && mItem.getOriginalPrice().size() > 0 && mItem.getOriginalPriceInCurrency("eur") > 0) {
            mOriginalPriceTextView.setVisibility(View.VISIBLE);
            mOriginalPriceTextView.setTypeface(mBoldFont);
            mOriginalPriceTextView.setText(getOriginalPriceString());
            mOriginalPriceTextView.setPaintFlags(mOriginalPriceTextView.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
        }

        mProductBrandName.setText(mItem.getBrand());

        // product category
        if(mItem.getCategories() != null && mItem.getCategories().size() > 0) {
            String category = mItem.getCategories().get(0);
            if(category.trim().length() > 0) {
                categoryLayout.setVisibility(View.GONE);
                mProductCategoryName.setText(category.substring(0, 1).toUpperCase() + category.substring(1));
            }
        }

        mImagePageTextView.setText(String.format("1 / %d", mItem.getImageURLs().size()));

        mDescriptionTextView.setText(mItem.getDescription());

        mPriceTextView.setText(getPriceString());

        // recommendations
        loadMoreByBrand();
        if(mItem.getCategories() != null && mItem.getCategories().size() > 0) {
            loadMoreByCategory();
        }

        // check whether to display location pin
        if (mLocation != null) {
            final List<Store> nearbyStores = getNearStores(mItem.getStores());
            if (nearbyStores.size() > 0) {
                ImageButton locationButton = findViewById(R.id.location_button);
                locationButton.setVisibility(View.VISIBLE);
                locationButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        Class destinationActivity = MapActivity.class;
                        Intent startProductActivityIntent = new Intent(ProductDetailActivity.this, destinationActivity);

                        Location centerLocation = getMapCenter(nearbyStores);

                        double lat = centerLocation.getLatitude();
                        double lon = centerLocation.getLongitude();

                        startProductActivityIntent.putExtra(getString(R.string.nearStoresKey), (ArrayList<Store>) nearbyStores);
                        startProductActivityIntent.putExtra(getString(R.string.centerLat), lat);
                        startProductActivityIntent.putExtra(getString(R.string.centerLon), lon);

                        startActivity(startProductActivityIntent);
                    }
                });
            }
        }
    }

    @Override
    protected void onStop() {
        super.onStop();

        mImagesAdapter.clear();
        mImagesAdapter.notifyDataSetChanged();

        if(mMoreByBrandAdapter != null) {
            mMoreByBrandAdapter.clear();
            mMoreByBrandAdapter.notifyDataSetChanged();
        }

        if(mMoreByCategoryAdapter != null) {
            mMoreByCategoryAdapter.clear();
            mMoreByCategoryAdapter.notifyDataSetChanged();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        mItem = (Product)data.getSerializableExtra("item");

        if (data.hasExtra("lat")) {
            mLocation = new Location("");
            mLocation.setLatitude(data.getDoubleExtra("lat", -1));
            mLocation.setLongitude(data.getDoubleExtra("lng", -1));
        }
    }

    private void loadMoreByBrand() {
        try {
            RequestQueue queue = Volley.newRequestQueue(this);

            String url = getString(R.string.text_search_base_url);
            JSONObject request = getBrandRequest();

            JsonObjectRequest brandRequest = new JsonObjectRequest
                    (Request.Method.POST, url, request, new Response.Listener<JSONObject>() {

                        @Override
                        public void onResponse(JSONObject response) {
                            try {
                                JSONObject matches = response.getJSONObject("matches");
                                List<Product> results = new ArrayList<>();
                                if (matches.has("items")) {
                                    JSONArray items = matches.getJSONArray("items");
                                    for (int itemIndex = 0; itemIndex < items.length(); itemIndex++) {
                                        Product item = Product.fromJSONObject(items.getJSONObject(itemIndex));
                                        results.add(item);
                                    }
                                }

                                if (results.size() > 0) {
                                    RecyclerView recyclerView = findViewById(R.id.more_by_brand_recyclerview);
                                    recyclerView.setLayoutManager(new GridLayoutManager(ProductDetailActivity.this, 2));

                                    DisplayMetrics dm = new DisplayMetrics();
                                    WindowManager windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
                                    windowManager.getDefaultDisplay().getMetrics(dm);

                                    ViewGroup.LayoutParams params = recyclerView.getLayoutParams();
                                    int rowCount = (int) Math.ceil(results.size() / 2);
                                    params.height = rowCount * (dm.widthPixels / 2) + rowCount * 11;
                                    recyclerView.setLayoutParams(params);

                                    mMoreByBrandAdapter = new ProductGridGalleryAdapter(results, ProductDetailActivity.this);
                                    recyclerView.setAdapter(mMoreByBrandAdapter);

                                    TextView moreByBrandTextView = findViewById(R.id.more_by_brand_textview);
                                    moreByBrandTextView.setTypeface(mExtraBoldFont);
                                    moreByBrandTextView.setText(String.format("More by %s", mItem.getBrand()));

                                    LinearLayout moreByBrandLayout = findViewById(R.id.more_by_brand_layout);
                                    moreByBrandLayout.setVisibility(View.VISIBLE);
                                }
                            } catch (JSONException e) {
                                e.printStackTrace();
                            }

                        }
                    }, new Response.ErrorListener() {
                        @Override
                        public void onErrorResponse(VolleyError error) {
                            error.printStackTrace();
                        }
                    }) {

                @Override
                public Map<String, String> getHeaders() {
                    return getRequestHeaders();
                }
            };

            queue.add(brandRequest);

        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void loadMoreByCategory() {
        try {
            RequestQueue queue = Volley.newRequestQueue(this);

            String url = getString(R.string.text_search_base_url);
            JSONObject request = getCategoryRequest();

            JsonObjectRequest categoryRequest = new JsonObjectRequest
                    (Request.Method.POST, url, request, new Response.Listener<JSONObject>() {

                        @Override
                        public void onResponse(JSONObject response) {
                            try {
                                JSONObject matches = response.getJSONObject("matches");
                                List<Product> results = new ArrayList<>();
                                if (matches.has("items")) {
                                    JSONArray items = matches.getJSONArray("items");
                                    for (int itemIndex = 0; itemIndex < items.length(); itemIndex++) {
                                        Product item = Product.fromJSONObject(items.getJSONObject(itemIndex));
                                        results.add(item);
                                    }
                                }

                                if (results.size() > 0) {
                                    RecyclerView recyclerView = findViewById(R.id.more_by_category_recyclerview);
                                    recyclerView.setLayoutManager(new GridLayoutManager(ProductDetailActivity.this, 2));

                                    DisplayMetrics dm = new DisplayMetrics();
                                    WindowManager windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
                                    windowManager.getDefaultDisplay().getMetrics(dm);

                                    ViewGroup.LayoutParams params = recyclerView.getLayoutParams();
                                    int rowCount = (int) Math.ceil(results.size() / 2);
                                    params.height = rowCount * (dm.widthPixels / 2) + rowCount * 11;
                                    recyclerView.setLayoutParams(params);

                                    mMoreByCategoryAdapter = new ProductGridGalleryAdapter(results, ProductDetailActivity.this);
                                    recyclerView.setAdapter(mMoreByCategoryAdapter);

                                    TextView moreByCategoryTextView = findViewById(R.id.more_by_category_textview);
                                    moreByCategoryTextView.setTypeface(mExtraBoldFont);
                                    String category = mItem.getCategories().get(0);
                                    moreByCategoryTextView.setText(String.format("Other %s", category.substring(0, 1).toUpperCase() + category.substring(1)));

                                    LinearLayout moreByCategoryLayout = findViewById(R.id.more_by_category_layout);
                                    moreByCategoryLayout.setVisibility(View.VISIBLE);
                                }
                            } catch (JSONException e) {
                                e.printStackTrace();
                            }

                        }
                    }, new Response.ErrorListener() {
                        @Override
                        public void onErrorResponse(VolleyError error) {
                            error.printStackTrace();
                        }
                    }) {

                @Override
                public Map<String, String> getHeaders() {
                    return getRequestHeaders();
                }
            };

            queue.add(categoryRequest);

        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private JSONObject getBrandRequest() throws JSONException {
        JSONObject body = new JSONObject();

        JSONObject filters = new JSONObject();
        filters.put("gender", PreferencesHelper.getInstance(getApplicationContext()).getGender());
        filters.put("brand", mItem.getBrand());
        body.put("filters", filters);
        body.put("size", 12);

        return body;
    }

    private JSONObject getCategoryRequest() throws JSONException {
        JSONObject body = new JSONObject();

        JSONObject filters = new JSONObject();
        filters.put("gender", PreferencesHelper.getInstance(getApplicationContext()).getGender());
        filters.put("annotations.category", mItem.getCategories().get(0));
        body.put("filters", filters);
        body.put("size", 12);

        return body;
    }

    private Map<String, String> getRequestHeaders() {
        Map<String, String> header = new HashMap<>();
        header.put("Content-Type", "application/json");
        header.put("X-Cerebel-Token", getString(R.string.cerebel_api_token));
        return header;
    }

    private void navigateToProductPage() {
        Class destinationActivity = WebStoreActivity.class;
        Intent startWebStore = new Intent(this, destinationActivity);
        startWebStore.putExtra("item", mItem);
        startActivity(startWebStore);
    }

    private String getPriceString() {
        String currency = PreferencesHelper.getInstance(getApplicationContext()).getCurrency();
        String productPrice = "";
        if (currency.equals(getString(R.string.shoppingInUsd))) {
            currency = "$ ";
            productPrice = String.valueOf(mItem.getPriceInCurrency("usd"));
        } else if (currency.equals(getString(R.string.shoppingInGbp))) {
            currency = "£ ";
            productPrice = String.valueOf(mItem.getPriceInCurrency("gbp"));
        } else if (currency.equals(getString(R.string.shoppingInDkk))) {
            currency = "Kr. ";
            productPrice = String.valueOf(mItem.getPriceInCurrency("dkk"));
        } else if (currency.equals(getString(R.string.shoppingInEur))) {
            productPrice = String.valueOf(mItem.getPriceInCurrency("eur"));
            currency = "€ ";
        }
        return currency + productPrice;
    }

    private String getOriginalPriceString() {
        String currency = PreferencesHelper.getInstance(getApplicationContext()).getCurrency();
        String productPrice = "";
        if (currency.equals(getString(R.string.shoppingInUsd))) {
            currency = "$ ";
            productPrice = String.valueOf(mItem.getOriginalPriceInCurrency("usd"));
        } else if (currency.equals(getString(R.string.shoppingInGbp))) {
            currency = "£ ";
            productPrice = String.valueOf(mItem.getOriginalPriceInCurrency("gbp"));
        } else if (currency.equals(getString(R.string.shoppingInDkk))) {
            currency = "Kr. ";
            productPrice = String.valueOf(mItem.getOriginalPriceInCurrency("dkk"));
        } else if (currency.equals(getString(R.string.shoppingInEur))) {
            productPrice = String.valueOf(mItem.getOriginalPriceInCurrency("eur"));
            currency = "€ ";
        }
        return currency + productPrice;
    }

    /**
     * Finds the center of the map to display all nearby stores.
     * Uses midpoint formula with the extreme stores.
     *
     * @param stores list of nearby stores
     * @return center position of all the stores as coordinates
     */
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

            float distanceInMeters = mLocation.distanceTo(currentStoreLocation);

            if (distanceInMeters < MaxRadius) {
                nearStores.add(currentStore);
            }
        }
        return nearStores;
    }

    class CheckIfLiked extends AsyncTask<String, Void, Boolean> {

        final Context context;
        final ToggleButton toggleButton;
        final Product item;

        CheckIfLiked(Context context, ToggleButton toggleButton, Product item) {
            this.context = context;
            this.toggleButton = toggleButton;
            this.item = item;
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

            CompoundButton.OnCheckedChangeListener onCheckedChangeListener = new CompoundButton.OnCheckedChangeListener() {
                @Override
                public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                    if (isChecked) {
                        new ProductDetailActivity.AddToFavoritesTask(context).execute(item);
                        RateThisApp.showRateDialogIfNeeded(context);
                    } else {
                        new ProductDetailActivity.RemoveFromFavoritesTask(context).execute(item);
                    }
                }
            };

            toggleButton.setOnCheckedChangeListener(onCheckedChangeListener);

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

            AppEventLogger.getInstance(getApplicationContext()).logAddToWishlist(
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
}
