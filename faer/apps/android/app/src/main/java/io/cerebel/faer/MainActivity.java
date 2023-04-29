package io.cerebel.faer;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentStatePagerAdapter;
import androidx.viewpager.widget.PagerAdapter;
import androidx.viewpager.widget.ViewPager;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.analytics.FirebaseAnalytics;

import io.cerebel.faer.data.local.DatabaseHelper;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.model.WishlistProduct;
import io.cerebel.faer.data.remote.AppEventLogger;
import io.cerebel.faer.data.service.SearchService;
import io.cerebel.faer.ui.common.EmailActivity;
import io.cerebel.faer.ui.freshlooks.fragments.FreshLooksFragment;
import io.cerebel.faer.ui.product.ProductDetailActivity;
import io.cerebel.faer.ui.search.OnSearchListener;
import io.cerebel.faer.ui.search.QueryResultActivity;
import io.cerebel.faer.ui.search.fragments.SearchFragment;
import io.cerebel.faer.ui.wishlist.fragments.WishlistFragment;
import io.cerebel.faer.util.RateThisApp;

import static io.cerebel.faer.ui.common.EmailActivity.RESULT_EMAIL_ACTIVITY;
import static io.cerebel.faer.ui.search.fragments.SearchFragment.SEARCH_QUERY;


public class MainActivity extends FragmentActivity implements OnSearchListener {
    public static final int REQUEST_CHECK_SETTINGS = 0x1;
    private static final int NUM_PAGES = 3;
    private static final int FRESH_LOOKS_PAGE_INDEX = 0;
    private static final int SEARCH_PAGE_INDEX = 1;
    private static final int WISHLIST_PAGE_INDEX = 2;
    private static final int PAGES = 2147483647;
    private static final int INITIAL_POSITION = 9999;
    private static final int LOCATION_PERMISSION_ID = 1001;
    public static boolean leftActivity = false;
    private boolean mFromProductNotification = false;
    private TextView getStartedButton;
    private ViewPager mPager;
    private ImageView[] ivArrayDotsPager;
    private LinearLayout llPagerDots;
    private int devicePxHeight;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mFromProductNotification = false;

        FirebaseAnalytics.getInstance(getApplicationContext()).getAppInstanceId().addOnCompleteListener(new OnCompleteListener<String>() {
            @Override
            public void onComplete(@NonNull Task<String> task) {
                if (!task.isSuccessful()) {
                    Log.w("Get app instance id", "error getting app instance ID");
                    return;
                }

                PreferencesHelper.getInstance(getApplicationContext()).setAppInstanceID(task.getResult());
            }
        });

        // app was opened from a push notification
        if (getIntent().hasExtra("product_id")) {
            String productID = getIntent().getStringExtra("product_id");
            SearchService.getProduct(getApplicationContext(), productID, new Response.Listener<Product>() {
                @Override
                public void onResponse(Product product) {
                    DatabaseHelper db = DatabaseHelper.getInstance(getApplicationContext());
                    WishlistProduct wishlistProduct = db.getItem(product.getId());
                    if (wishlistProduct != null) {
                        wishlistProduct.setProduct(product);
                        db.updateFavorite(wishlistProduct);
                    }
                    Intent productDetailIntent = new Intent(getApplicationContext(), ProductDetailActivity.class);
                    productDetailIntent.putExtra("item", product);
                    startActivity(productDetailIntent);
                    getIntent().removeExtra("product_id");
                }
            }, new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    Toast.makeText(getApplicationContext(), "There was a problem getting the product", Toast.LENGTH_LONG).show();
                }
            });
            mFromProductNotification = true;
        }

        devicePxHeight = getResources().getDisplayMetrics().heightPixels;
        if (devicePxHeight > 1300) {
            getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        } else {
            getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING);
        }

        final RelativeLayout onboardingRelativeLayout = findViewById(R.id.onboarding_relative_layout);
        final RelativeLayout defaultRelativeLayout = findViewById(R.id.default_relative_layout);

        boolean firstSession = PreferencesHelper.getInstance(getApplicationContext()).isFirstSession();
        if (firstSession) {
            onboardingRelativeLayout.setVisibility(View.VISIBLE);
            defaultRelativeLayout.setVisibility(View.INVISIBLE);
        } else {
            onboardingRelativeLayout.setVisibility(View.GONE);
            defaultRelativeLayout.setVisibility(View.VISIBLE);
        }

        // Instantiate a ViewPager and a PagerAdapter.
        mPager = findViewById(R.id.pager);
        mPager.setOffscreenPageLimit(3);

        llPagerDots = findViewById(R.id.pager_dots);

        final PagerAdapter mPagerAdapter = new ScreenSlidePagerAdapter(getSupportFragmentManager());
        mPager.setAdapter(mPagerAdapter);

        mPager.setCurrentItem(INITIAL_POSITION, false);

        setupPagerIndicatorDots();
        //initially the first dot is selected
        ivArrayDotsPager[0].setImageResource(R.drawable.selected);

        mPager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int i, float v, int i1) {
            }

            @Override
            public void onPageSelected(int position) {

                int posIdx = position % NUM_PAGES;
                if (posIdx == 1) {
                    if (devicePxHeight > 1300) {
                        getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
                    } else {
                        getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING);
                    }
                } else {
                    getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING);
                }

                PreferencesHelper.getInstance(getApplicationContext()).setIsFirstSession(false);

                //Set the current page's dot to selected
                for (ImageView anIvArrayDotsPager : ivArrayDotsPager) {
                    anIvArrayDotsPager.setImageResource(R.drawable.unselected);
                }
                ivArrayDotsPager[posIdx].setImageResource(R.drawable.selected);

                if(posIdx == FRESH_LOOKS_PAGE_INDEX) {
                    AppEventLogger.getInstance(getApplicationContext()).logCurrentScreenClass(MainActivity.this, "fresh_looks", FreshLooksFragment.class.getSimpleName());
                } else if(posIdx == SEARCH_PAGE_INDEX) {
                    AppEventLogger.getInstance(getApplicationContext()).logCurrentScreenClass(MainActivity.this, "search", SearchFragment.class.getSimpleName());
                } else if(posIdx == WISHLIST_PAGE_INDEX) {
                    AppEventLogger.getInstance(getApplicationContext()).logCurrentScreenClass(MainActivity.this, "wishlist", WishlistFragment.class.getSimpleName());
                }
            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });


        Typeface regularFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_medium));
        Typeface boldFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_bold));
        TextView selectShopTextView = findViewById(R.id.select_shop_text_view);

        RadioGroup genderRadioGroup = findViewById(R.id.start_gender_radio_group);
        RadioButton shopWomenRadioButton = findViewById(R.id.start_shop_women_radio_button);
        RadioButton shopMenRadioButton = findViewById(R.id.start_shop_men_radio_button);
        genderRadioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup radioGroup, int id) {
                if (PreferencesHelper.getInstance(getApplicationContext()).isFirstSession()) {
                    RadioButton btn = radioGroup.findViewById(id);
                    if (btn.isChecked()) {
                        getStartedButton.setTextColor(Color.BLACK);
                        getStartedButton.setEnabled(true);
                        PreferencesHelper.getInstance(getApplicationContext()).setGender(btn.getTag().toString());
                    }
                }
            }
        });


        getStartedButton = findViewById(R.id.get_started_button);

        TextView helloTextView = findViewById(R.id.hello_text_view);

        helloTextView.setTypeface(boldFont);
        selectShopTextView.setTypeface(regularFont);
        shopWomenRadioButton.setTypeface(regularFont);
        shopMenRadioButton.setTypeface(regularFont);
        getStartedButton.setTypeface(boldFont);

        getStartedButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                boolean askedAboutNewsletter = PreferencesHelper.getInstance(getApplicationContext()).isAskedAboutNewsletter();
                if (!askedAboutNewsletter) {
                    Intent emailIntent = new Intent(getApplicationContext(), EmailActivity.class);
                    startActivityForResult(emailIntent, RESULT_EMAIL_ACTIVITY);
                    PreferencesHelper.getInstance(getApplicationContext()).setIsAskedAboutNewsletter(true);
                }

                PreferencesHelper.getInstance(getApplicationContext()).setIsFirstSession(false);
                onboardingRelativeLayout.setVisibility(View.GONE);
                defaultRelativeLayout.setVisibility(View.VISIBLE);
            }
        });

        RateThisApp.Config config = new RateThisApp.Config(4, 5, 2);
        RateThisApp.init(config);

        RateThisApp.onCreate(getApplicationContext());
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (leftActivity) {
            recreate();
            leftActivity = false;
        }

        if (mFromProductNotification) {
            mPager.setCurrentItem(INITIAL_POSITION + 2);
        }
    }

    /**
     * Sets the dots at the bottom of the screen.
     */
    private void setupPagerIndicatorDots() {
        ivArrayDotsPager = new ImageView[NUM_PAGES];
        for (int i = 0; i < ivArrayDotsPager.length; i++) {
            ivArrayDotsPager[i] = new ImageView(this);
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);

            int marginBetweenPaginationDots = 12;
            params.setMargins(marginBetweenPaginationDots, 0, marginBetweenPaginationDots, 0);
            ivArrayDotsPager[i].setLayoutParams(params);
            ivArrayDotsPager[i].setImageResource(R.drawable.unselected);
            llPagerDots.addView(ivArrayDotsPager[i]);
            llPagerDots.bringToFront();
        }
    }

    private void doTextSearch(String query) {
        if(!isNetworkAvailable()) {
            Toast.makeText(getApplicationContext(), "No Internet connection", Toast.LENGTH_LONG).show();
            return;
        }

        //Analytics
        AppEventLogger.getInstance(getApplicationContext()).logSearch(query, "text");

        Intent queryIntent = new Intent(this, QueryResultActivity.class);
        MainActivity.leftActivity = true;
        queryIntent.putExtra(SEARCH_QUERY, query);

        startActivity(queryIntent);
    }

    @Override
    public void onTextSearch(String query) {
        doTextSearch(query);
    }

    @Override
    public void onImageSearch() {

    }

    @Override
    public void onVoiceSearch(String query) {
        doTextSearch(query);
    }

    private boolean isNetworkAvailable() {
        ConnectivityManager connectivityManager
                = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    @Override
    public void onPointerCaptureChanged(boolean hasCapture) {

    }

    /**
     * Sets the order of the fragments in the view pager
     */
    private class ScreenSlidePagerAdapter extends FragmentStatePagerAdapter {
        ScreenSlidePagerAdapter(FragmentManager fm) {
            super(fm);
        }

        @Override
        public Fragment getItem(int position) {
            if (position % NUM_PAGES == FRESH_LOOKS_PAGE_INDEX) {
                return new FreshLooksFragment();

            } else if (position % NUM_PAGES == SEARCH_PAGE_INDEX) {
                return new SearchFragment();
            }

            return new WishlistFragment();
        }

        @Override
        public int getCount() {
            return PAGES;
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if(requestCode == RESULT_EMAIL_ACTIVITY) {
            if(data != null && data.hasExtra("email")) {
                String email = data.getStringExtra("email");
                AppEventLogger.getInstance(this).logSubscribeNewsletter(email);
            }
        }
    }
}


