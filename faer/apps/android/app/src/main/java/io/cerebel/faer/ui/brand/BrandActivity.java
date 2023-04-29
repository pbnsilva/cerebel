package io.cerebel.faer.ui.brand;

import android.content.Context;
import android.graphics.Typeface;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.tooltip.Tooltip;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.Brand;
import io.cerebel.faer.data.model.CategoryProducts;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.service.BrandService;
import io.cerebel.faer.ui.brand.adapters.TagsAdapter;
import io.cerebel.faer.ui.category.CategorySpotlightView;
import io.cerebel.faer.ui.common.adapters.HorizontalProductsAdapter;
import io.cerebel.faer.util.Convert;

public class BrandActivity extends AppCompatActivity {
    private Typeface mOpenSansFont;

    private LinearLayout mContentLayout, mEthicsTitleLayout;
    private ProgressBar mProgressBar;
    private TextView mBrandName;
    private TextView mBrandLocation;
    private TextView mBrandPrices;
    private TextView mBrandPopular;
    private TextView mBrandDescription;
    private ImageButton mEthicsInfo;
    private ListView mTagsList;
    private RecyclerView mPopularList;
    private CategorySpotlightView mCategorySpotlightView;
    private Tooltip mTooltip;
    private TagsAdapter mTagsAdapter;
    private HorizontalProductsAdapter mPopularProductsAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_brand);

        Typeface mExtraBoldFont = Typeface.createFromAsset(getAssets(), getString(R.string.font_extra_bold));
        Typeface mMediumFont = Typeface.createFromAsset(getAssets(), getString(R.string.font_medium));
        mOpenSansFont = Typeface.createFromAsset(getAssets(), getString(R.string.font_open_sans));

        mContentLayout = findViewById(R.id.content_layout);
        mProgressBar = findViewById(R.id.progress_bar);

        mBrandName = findViewById(R.id.brand_name);
        mBrandName.setTypeface(mExtraBoldFont);

        mBrandLocation = findViewById(R.id.brand_location);
        mBrandLocation.setTypeface(mMediumFont);

        mBrandPrices = findViewById(R.id.brand_prices);
        mBrandPrices.setTypeface(mExtraBoldFont);

        mBrandDescription = findViewById(R.id.brand_description);
        mBrandDescription.setTypeface(mOpenSansFont);

        mEthicsTitleLayout = findViewById(R.id.ethics_title_layout);

        TextView mBrandEthics = findViewById(R.id.brand_ethics_text);
        mBrandEthics.setTypeface(mExtraBoldFont);

        mEthicsInfo = findViewById(R.id.brand_ethics_info);
        mEthicsInfo.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(mTooltip.isShowing()) {
                    mTooltip.dismiss();
                } else {
                    mTooltip.show();
                }
            }
        });

        mTagsList = findViewById(R.id.brand_tags_list);

        mBrandPopular = findViewById(R.id.brand_popular_title_text);
        mBrandPopular.setTypeface(mExtraBoldFont);

        mPopularList = findViewById(R.id.brand_popular_list);

        mCategorySpotlightView = findViewById(R.id.category_spotlight);

        TextView aboutText = findViewById(R.id.about_text_view);
        aboutText.setTypeface(mExtraBoldFont);

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
    }

    @Override
    protected void onStart() {
        super.onStart();
        final Context ctx = this;
        if(getIntent().getExtras() != null) {
            String gender = PreferencesHelper.getInstance(getApplicationContext()).getGender();
            String brandID = getIntent().getStringExtra("brandID");
            BrandService.getBrand(this, brandID, gender, new Response.Listener<Brand>() {
                @Override
                public void onResponse(Brand brand) {
                    mTooltip = new Tooltip.Builder(mEthicsInfo)
                            .setText(String.format("Our ethics and sustainability details are based on publicly available information provided by %s on their website and social media.", brand.getName()))
                            .setBackgroundColor(getResources().getColor(R.color.colorPrimaryDark))
                            .setTextColor(getResources().getColor(R.color.colorPrimary))
                            .setTypeface(mOpenSansFont)
                            .setCornerRadius(30f)
                            .setPadding(35)
                            .setCancelable(true)
                            .setDismissOnClick(true).build();

                    mBrandName.setText(brand.getName());
                    mBrandLocation.setText(brand.getLocation());
                    mBrandPrices.setText(String.format("Prices: %s", brand.getPriceRange()));

                    if(!brand.getDescription().isEmpty()) {
                        mBrandDescription.setText(brand.getDescription());
                    } else {
                        mBrandDescription.setVisibility(View.GONE);
                    }

                    if(brand.getTags().size() > 0) {
                        mTagsAdapter = new TagsAdapter(ctx, brand.getTags());
                        mTagsList.setAdapter(mTagsAdapter);

                        mTagsList.getLayoutParams().height = brand.getTags().size() * (int) Convert.DpToPixel(50, ctx);
                    } else {
                        mEthicsTitleLayout.setVisibility(View.GONE);
                        mTagsList.setVisibility(View.GONE);
                    }

                    List<Product> popularProducts = brand.getPopularProducts();
                    if(popularProducts.size() > 0) {
                        mPopularProductsAdapter = new HorizontalProductsAdapter(ctx, brand.getPopularProducts());
                        mPopularList.setAdapter(mPopularProductsAdapter);
                        LinearLayoutManager horizontalLayoutManagaer = new LinearLayoutManager(ctx, LinearLayoutManager.HORIZONTAL, false);
                        mPopularList.setLayoutManager(horizontalLayoutManagaer);
                    } else {
                        mBrandPopular.setVisibility(View.GONE);
                        mPopularList.setVisibility(View.GONE);
                    }

                    List<CategoryProducts> categoryProducts = brand.getCategoryProducts();
                    if(categoryProducts.size() > 0) {
                        DisplayMetrics dm = new DisplayMetrics();
                        WindowManager windowManager = (WindowManager) ctx.getSystemService(WINDOW_SERVICE);
                        windowManager.getDefaultDisplay().getMetrics(dm);
                        int width = (int) (dm.widthPixels * 0.7);
                        int height = (dm.heightPixels / dm.widthPixels) * width;
                        mCategorySpotlightView.getLayoutParams().height = categoryProducts.size() * height + (int) Convert.DpToPixel(categoryProducts.size() * 105, ctx);
                        mCategorySpotlightView.setCategoryProducts(categoryProducts);
                    } else {
                        mCategorySpotlightView.setVisibility(View.GONE);
                    }

                    mProgressBar.setVisibility(View.GONE);
                    mContentLayout.setVisibility(View.VISIBLE);
                }
            }, new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {

                }
            });
        }
    }

    @Override
    protected void onStop() {
        super.onStop();

        if(mTagsAdapter != null) {
            mTagsAdapter.clear();
        }

        if(mPopularProductsAdapter != null) {
            mPopularProductsAdapter.clear();
        }

        mCategorySpotlightView.clearCategoryProducts();
    }
}
