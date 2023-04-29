package io.cerebel.faer.ui.search;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Typeface;
import android.location.Location;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.appcompat.widget.Toolbar;
import android.util.Base64;
import android.view.View;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.HorizontalScrollView;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.remote.AppEventLogger;
import io.cerebel.faer.ui.search.adapters.FiltersAdapter;
import io.cerebel.faer.ui.search.adapters.QueryResultAdapter;
import io.cerebel.faer.ui.search.fragments.SearchFragment;
import io.nlopez.smartlocation.OnLocationUpdatedListener;
import io.nlopez.smartlocation.SmartLocation;
import io.nlopez.smartlocation.location.providers.LocationGooglePlayServicesProvider;

public class QueryResultActivity extends AppCompatActivity implements OnLocationUpdatedListener {
    public static Bitmap mBitmap = null;
    public static float mMinPrice  = 1;
    public static float mMaxPrice = 2500;
    private static final int PAGE_SIZE = 10;

    // location updates interval - 10sec
    private static final long UPDATE_INTERVAL_IN_MILLISECONDS = 10000;
    // fastest updates interval - 5 sec
    // location updates will be received if another app is requesting the locations
    // than your app can handle
    private static final long FASTEST_UPDATE_INTERVAL_IN_MILLISECONDS = 5000;

    private static final int LOCATION_PERMISSION_ID = 1001;

    private Intent mIntent;

    private Toolbar mToolbar;

    private TextView mQueryTextView;
    private TextView mErrorTextView;
    private TextView mNoResultsTextView;
    private TextView mFiltersTextView;
    private CheckBox mSaleCheckBox;

    private LinearLayout mLoadingLayout;
    private LinearLayout mGuidedLayout;

    private FiltersView mFiltersView;
    private RelativeLayout mFiltersBackgroundLayout;

    private RecyclerView mResultListRecyclerView;
    private QueryResultAdapter mResultListAdapter;

    private Typeface mExtraBoldFont;

    private CompoundButton mCompoundButton;

    private boolean mIsLoadingMore = false;
    private boolean mIsFirstLoad = true;
    private int mNbLoadedPages= 0;
    private int mLastFromPrice = 1;
    private int mLastToPrice = -1;

    public Location mCurrentLocation;
    private LocationGooglePlayServicesProvider mLocationProvider;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_query_result);

        mIntent = getIntent();

        mExtraBoldFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_extra_bold));

        mResultListRecyclerView = findViewById(R.id.result_list_recyclerview);
        RecyclerView.LayoutManager mResultListLayoutManager = new LinearLayoutManager(this, RecyclerView.VERTICAL, false);
        mResultListRecyclerView.setLayoutManager(mResultListLayoutManager);

        mResultListAdapter = new QueryResultAdapter(QueryResultActivity.this);
        mResultListRecyclerView.setAdapter(mResultListAdapter);

        mToolbar = findViewById(R.id.toolbar);
        mQueryTextView = findViewById(R.id.query_text_view);
        mNoResultsTextView = findViewById(R.id.query_no_results_text_view);
        mErrorTextView = findViewById(R.id.error_text_view);
        mLoadingLayout = findViewById(R.id.loading_linear_layout);
        mGuidedLayout = findViewById(R.id.guided_layout);
        mFiltersTextView = findViewById(R.id.filters_text_view);
        mSaleCheckBox = findViewById(R.id.sale_text_view);

        mQueryTextView.setTypeface(mExtraBoldFont);
        mFiltersTextView.setTypeface(mExtraBoldFont);
        mSaleCheckBox.setTypeface(mExtraBoldFont);
        mErrorTextView.setTypeface(mExtraBoldFont);
        mNoResultsTextView.setTypeface(mExtraBoldFont);

        mFiltersView = findViewById(R.id.filters_expandable_view);
        mFiltersBackgroundLayout = findViewById(R.id.filters_background_view);

        mQueryTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
            }
        });

        LinearLayout backLayout = findViewById(R.id.back_layout);
        backLayout.setOnClickListener(new View.OnClickListener() {
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

        mResultListRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                LinearLayoutManager layoutManager = (LinearLayoutManager)recyclerView.getLayoutManager();
                int firstVisibleItemPosition = layoutManager.findFirstVisibleItemPosition();
                int visibleItemCount = layoutManager.getChildCount();
                int totalItemCount = layoutManager.getItemCount();
                if ((firstVisibleItemPosition + visibleItemCount > totalItemCount - 5) && (totalItemCount != 0)) {
                    if (!mIsLoadingMore) {
                        mIsLoadingMore = true;
                        queueSearchFromIntent(mIntent, mNbLoadedPages++);
                    }
                }
            }
        });

        queueSearchFromIntent(mIntent, mNbLoadedPages++);

        FiltersAdapter adapter = new FiltersAdapter(this);
        mFiltersView.setAdapter(adapter);

        mFiltersBackgroundLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mFiltersBackgroundLayout.setVisibility(View.GONE);
            }
        });

        mFiltersView.setOnSortByChangeListener(new FiltersView.SortByChangeListener() {
            @Override
            public void onSortByChange(SortBy value) {
                QueryResultAdapter adapter = (QueryResultAdapter) mResultListRecyclerView.getAdapter();
                adapter.clear();
                adapter.notifyDataSetChanged();
                mGuidedLayout.removeAllViews();
                mIntent.putExtra(SearchFragment.WITH_FILTERS, true);
                mIntent.putExtra(SearchFragment.SORT_BY, value.ordinal());
                queueSearchFromIntent(mIntent, 0);
            }
        });

        mFiltersView.setOnPriceChangeListener(new FiltersView.PriceChangeListener() {
            @Override
            public void onPriceChange(int from, int to) {
                if (from != mLastFromPrice || to != mLastToPrice) {
                    QueryResultAdapter adapter = (QueryResultAdapter) mResultListRecyclerView.getAdapter();
                    adapter.clear();
                    adapter.notifyDataSetChanged();
                    mGuidedLayout.removeAllViews();
                    mIntent.putExtra(SearchFragment.WITH_FILTERS, true);
                    mIntent.putExtra(SearchFragment.PRICE_FROM, from);
                    mIntent.putExtra(SearchFragment.PRICE_TO, to);
                    queueSearchFromIntent(mIntent, 0);
                    mMinPrice= from;
                    mMaxPrice = to;
                }
                mLastFromPrice = from;
                mLastToPrice = to;
            }
        });

        mFiltersView.setOnLocationChangeListener(new FiltersView.LocationChangeListener() {
            @Override
            public void onLocationChange(CompoundButton button, boolean isEnabled) {
                QueryResultAdapter adapter = (QueryResultAdapter) mResultListRecyclerView.getAdapter();
                Bundle loc;
                if (isEnabled) {
                    if (mCurrentLocation == null) {
                        button.setEnabled(false);
                        mCompoundButton = button;
                        button.setChecked(false);
                        if (ContextCompat.checkSelfPermission(QueryResultActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(QueryResultActivity.this, new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, LOCATION_PERMISSION_ID);
                            return;
                        }
                        startLocation();
                    } else {
                        loc = new Bundle();
                        loc.putDouble("lat", mCurrentLocation.getLatitude());
                        loc.putDouble("lon", mCurrentLocation.getLongitude());
                        adapter.clear();
                        adapter.notifyDataSetChanged();
                        mGuidedLayout.removeAllViews();
                        mIntent.putExtra(SearchFragment.LOCATION, loc);
                        mIntent.putExtra(SearchFragment.WITH_FILTERS, true);
                        queueSearchFromIntent(mIntent, 0);
                    }
                } else {
                    adapter.clear();
                    adapter.notifyDataSetChanged();
                    mGuidedLayout.removeAllViews();
                    mIntent.removeExtra(SearchFragment.LOCATION);
                    mIntent.putExtra(SearchFragment.WITH_FILTERS, true);
                    queueSearchFromIntent(mIntent, 0);
                }
            }
        });

        mFiltersView.setOnTouchListener(new OnSwipeTouchListener() {
            @Override
            public void onRightToLeftSwipe() {

            }

            @Override
            public void onLeftToRightSwipe() {

            }

            @Override
            public void onTopToBottomSwipe() {
                mFiltersView.animate().setDuration(200).translationY(mFiltersView.getHeight()).withEndAction(new Runnable() {
                    @Override
                    public void run() {
                        mFiltersBackgroundLayout.setVisibility(View.GONE);
                        mFiltersView.animate().setDuration(0).translationY(0);
                    }
                });
            }

            @Override
            public void onBottomToTopSwipe() {
            }
        });

        mFiltersTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (mFiltersBackgroundLayout.getVisibility() == View.GONE) {
                    mFiltersBackgroundLayout.setVisibility(View.VISIBLE);
                } else {
                    mFiltersBackgroundLayout.setVisibility(View.GONE);
                }
                mFiltersView.expandGroup(0);
            }
        });

        mSaleCheckBox.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, boolean isChecked) {
                QueryResultAdapter adapter = (QueryResultAdapter) mResultListRecyclerView.getAdapter();
                adapter.clear();
                adapter.notifyDataSetChanged();
                mGuidedLayout.removeAllViews();
                mIntent.putExtra(SearchFragment.ON_SALE, isChecked);
                queueSearchFromIntent(mIntent, 0);
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (mLocationProvider != null) {
            mLocationProvider.onActivityResult(requestCode, resultCode, data);
        }
    }

    private void startLocation() {
        mLocationProvider = new LocationGooglePlayServicesProvider();
        mLocationProvider.setCheckLocationSettings(true);

        SmartLocation smartLocation = new SmartLocation.Builder(this).logging(true).build();

        smartLocation.location(mLocationProvider).start(this);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == LOCATION_PERMISSION_ID && grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startLocation();
        }
    }

    private void queueSearchFromIntent(final Intent intent, final int page) {
        JSONObject body = null;
        int sortBy = intent.getIntExtra(SearchFragment.SORT_BY, SortBy.RELEVANCE.ordinal());
        int priceFrom = intent.getIntExtra(SearchFragment.PRICE_FROM, -1);
        int priceTo = intent.getIntExtra(SearchFragment.PRICE_TO, -1);
        boolean onSale = intent.getBooleanExtra(SearchFragment.ON_SALE, false);
        Bundle loc = intent.getBundleExtra(SearchFragment.LOCATION);
        try {
            body = buildQueryBody(page, SortBy.values()[sortBy], priceFrom, priceTo, loc, !intent.hasExtra(SearchFragment.SEARCH_QUERY), onSale);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        String url;
        final boolean isTextSearch = intent.hasExtra(SearchFragment.SEARCH_QUERY);
        //If the intent has the extra, it's a text search query
        if (isTextSearch) {
            mQueryTextView.setText(intent.getStringExtra(SearchFragment.SEARCH_QUERY));
            url = getString(R.string.text_search_base_url);
        } else {
            url = getString(R.string.image_search_base_url);
        }

        if (mFiltersView != null && !intent.getBooleanExtra(SearchFragment.WITH_FILTERS, false)) {
            mFiltersBackgroundLayout.setVisibility(View.GONE);
        }

        RequestQueue queue = Volley.newRequestQueue(this);

        JsonObjectRequest jsonObjectRequest = new JsonObjectRequest
                (Request.Method.POST, url, body, new Response.Listener<JSONObject>() {

                    @Override
                    public void onResponse(JSONObject response) {

                        try {
                            JSONObject matches = response.getJSONObject("matches");

                            List<Product> searchResults = new ArrayList<>();
                            if (matches.has("items")) {

                                JSONArray items = matches.getJSONArray("items");

                                for (int itemIndex = 0; itemIndex < items.length(); itemIndex++) {
                                    Product item = Product.fromJSONObject(items.getJSONObject(itemIndex));
                                    searchResults.add(item);

                                }
                            }

                            if (!isTextSearch && searchResults.size() > 0) {
                                if(searchResults.size() > 1) {
                                    mQueryTextView.setText(String.format(Locale.ENGLISH, "%d results found", searchResults.size()));
                                } else {
                                    mQueryTextView.setText(String.format(Locale.ENGLISH, "%d result found", searchResults.size()));
                                }
                            }

                            mErrorTextView.setVisibility(View.INVISIBLE);
                            mLoadingLayout.setVisibility(View.INVISIBLE);

                            mIsLoadingMore = false;
                            mToolbar.setVisibility(View.VISIBLE);
                            if (searchResults.size() > 0 && page == 0) {
                                mSaleCheckBox.setVisibility(View.VISIBLE);
                                mQueryTextView.setVisibility(View.VISIBLE);
                                mFiltersView.setVisibility(View.VISIBLE);
                                //filtersTextView.setEnabled(true);
                                mNoResultsTextView.setVisibility(View.INVISIBLE);
                                mErrorTextView.setVisibility(View.INVISIBLE);
                            } else if (page == 0) {
                                //filtersTextView.setEnabled(false);
                                mSaleCheckBox.setVisibility(View.GONE);
                                mFiltersTextView.setVisibility(View.GONE);
                                if (intent.getBooleanExtra(SearchFragment.WITH_FILTERS, false)) {
                                    mNoResultsTextView.setVisibility(View.VISIBLE);
                                } else {
                                    mQueryTextView.setVisibility(View.INVISIBLE);
                                    mErrorTextView.setVisibility(View.VISIBLE);
                                    if (intent.hasExtra(SearchFragment.SEARCH_QUERY)) {
                                        String errorMessage = getString(R.string.text_error, intent.getStringExtra(SearchFragment.SEARCH_QUERY));
                                        mErrorTextView.setText(errorMessage);
                                    }

                                }
                            }

                            JSONObject aggs = response.getJSONObject("aggregations");
                            JSONObject maxAgg = aggs.getJSONObject("max");
                            JSONObject minAgg = aggs.getJSONObject("min");
                            mMinPrice = (float) minAgg.getDouble(minAgg.keys().next());
                            mMaxPrice = (float) maxAgg.getDouble(maxAgg.keys().next());

                            //analytics
                            if (searchResults.size() > 0 && mIsFirstLoad) {
                                mIsFirstLoad = false;
                                Bundle params = new Bundle();

                                if (intent.hasExtra(SearchFragment.SEARCH_QUERY)) {
                                    String searchTerm = mIntent.getExtras().getString(SearchFragment.SEARCH_QUERY);
                                    AppEventLogger.getInstance(getApplicationContext()).logViewSearchResults(searchTerm, searchResults.size());
                                } else {
                                    AppEventLogger.getInstance(getApplicationContext()).logViewSearchResults("<ImageSearch>", searchResults.size());
                                }
                            }

                            mResultListAdapter.addItems(searchResults);

                            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                                    LinearLayout.LayoutParams.WRAP_CONTENT,
                                    LinearLayout.LayoutParams.WRAP_CONTENT
                            );
                            params.setMarginEnd(25);
                            // guided search suggestions
                            HorizontalScrollView scrollView = findViewById(R.id.guided_scroll_view);
                            if (!isTextSearch) {
                                scrollView.setVisibility(View.GONE);
                            } else if (response.has("guided")) {
                                JSONArray guidedSuggestions = response.getJSONArray("guided");
                                scrollView.setVisibility(View.VISIBLE);
                                mGuidedLayout.removeAllViews();
                                for (int i = 0; i < guidedSuggestions.length(); i++) {
                                    //Button btn = new Button(getApplicationContext());
                                    TextView btn = new TextView(getApplicationContext());
                                    btn.setClickable(true);
                                    btn.setTextColor(Color.BLACK);
                                    btn.setLayoutParams(params);
                                    btn.setBackgroundResource(R.drawable.button_rectangle_border);
                                    btn.setText(guidedSuggestions.getString(i));
                                    btn.setTextSize(19.0f);
                                    btn.setTypeface(mExtraBoldFont);
                                    btn.setPadding(25, 13, 25, 13);
                                    btn.setLayoutParams(params);
                                    btn.setOnClickListener(new View.OnClickListener() {
                                        @Override
                                        public void onClick(View view) {
                                            mResultListAdapter.clear();
                                            mResultListAdapter.notifyDataSetChanged();
                                            mGuidedLayout.removeAllViews();
                                            TextView btn = (TextView) view;
                                            intent.putExtra(SearchFragment.WITH_FILTERS, true);
                                            intent.putExtra(SearchFragment.SEARCH_QUERY, intent.getStringExtra(SearchFragment.SEARCH_QUERY) + " " + btn.getText());
                                            queueSearchFromIntent(intent, 0);
                                        }
                                    });
                                    mGuidedLayout.addView(btn);
                                }
                            } else {
                                scrollView.setVisibility(View.GONE);
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

            //Passes the header for authentication
            @Override
            public Map<String, String> getHeaders() {
                Map<String, String> header = new HashMap<>();
                header.put("Content-Type", "application/json");
                header.put("X-Cerebel-Token", getString(R.string.cerebel_api_token));
                return header;
            }
        };
        queue.add(jsonObjectRequest);
    }

    private JSONObject buildQueryBody(int page, SortBy sortBy, int priceFrom, int priceTo, Bundle location, boolean isImageSearch, boolean onSale) throws JSONException {
        JSONObject body = new JSONObject();

        if (!isImageSearch) {
            body.put("query", mIntent.getExtras().get(SearchFragment.SEARCH_QUERY));

        } else { //image search
            Bitmap resizedBitmap = Bitmap.createScaledBitmap(mBitmap, 300, 300, false);
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            resizedBitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
            byte[] byteArray = byteArrayOutputStream.toByteArray();
            String encodedImage = Base64.encodeToString(byteArray, Base64.DEFAULT);

            JSONObject image = new JSONObject();
            image.put("content", encodedImage);
            body.put("image", image);
        }

        JSONObject filters = new JSONObject();
        //Get gender from user's preferences.
        String gender = PreferencesHelper.getInstance(getApplicationContext()).getGender();
        String currency = PreferencesHelper.getInstance(getApplicationContext()).getCurrency();

        if(onSale) {
            filters.put("onSale", true);
        }

        if (priceFrom != -1 || priceTo != -1) {
            JSONObject priceFilter = new JSONObject();
            if (priceFrom != -1) {
                priceFilter.put("gt", priceFrom);
            }
            if (priceTo != -1) {
                priceFilter.put("lt", priceTo);
            }
            filters.put("price." + currency, priceFilter);
        }

        filters.put("gender", gender);
        body.put("filters", filters);
        body.put("size", PAGE_SIZE);
        body.put("offset", page * PAGE_SIZE);
        body.put("showGuided", true);

        if (sortBy != SortBy.RELEVANCE) {
            JSONObject sortByField = new JSONObject();
            JSONObject priceField = new JSONObject();
            priceField.put("order", sortBy == SortBy.LOW_TO_HIGH ? "asc" : "desc");
            sortByField.put("price.eur", priceField);
            body.put("sortByField", sortByField);
        }

        if (location != null) {
            JSONObject locationFilter = new JSONObject();
            locationFilter.put("distance", "20km");
            JSONObject coords = new JSONObject();
            coords.put("lat", location.getDouble("lat"));
            coords.put("lon", location.getDouble("lon"));
            locationFilter.put("location", coords);
            filters.put("store_locations", locationFilter);
        }

        JSONObject aggs = new JSONObject();
        JSONArray aggFields = new JSONArray();
        aggFields.put(String.format(Locale.ENGLISH, "price.%s", currency));
        JSONObject minAgg = new JSONObject();
        minAgg.put("fields", aggFields);
        JSONObject maxAgg = new JSONObject();
        maxAgg.put("fields", aggFields);
        aggs.put("max", maxAgg);
        aggs.put("min", minAgg);
        body.put("aggregations", aggs);

        return body;
    }

    @Override
    public void onLocationUpdated(Location location) {
        mCurrentLocation = location;

        Bundle loc = new Bundle();
        loc.putDouble("lat", mCurrentLocation.getLatitude());
        loc.putDouble("lon", mCurrentLocation.getLongitude());
        mResultListAdapter.clear();
        mResultListAdapter.notifyDataSetChanged();
        mGuidedLayout.removeAllViews();
        mIntent.putExtra(SearchFragment.LOCATION, loc);
        mIntent.putExtra(SearchFragment.WITH_FILTERS, true);
        queueSearchFromIntent(mIntent, 0);
        mCompoundButton.setEnabled(true);
        mCompoundButton.setChecked(true);
    }

}
