package io.cerebel.faer.ui.common.adapters;

import android.content.Context;
import android.content.Intent;
import android.graphics.Paint;
import android.graphics.Typeface;
import androidx.swiperefreshlayout.widget.CircularProgressDrawable;
import androidx.recyclerview.widget.RecyclerView;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.ui.product.ProductDetailActivity;
import io.cerebel.faer.util.Convert;

import static android.content.Context.WINDOW_SERVICE;

public class HorizontalProductsAdapter extends RecyclerView.Adapter<HorizontalProductsAdapter.MyViewHolder> {
    private final Context mContext;
    private final List<Product> mProducts;
    private final Typeface mExtraBoldFont;

    public class MyViewHolder extends RecyclerView.ViewHolder {
        private final View productView;

        MyViewHolder(View view) {
            super(view);
            productView = view.findViewById(R.id.brand_product_layout);
        }
    }


    public HorizontalProductsAdapter(Context context, List<Product> products) {
        this.mContext = context;
        this.mProducts = products;
        this.mExtraBoldFont = Typeface.createFromAsset(context.getAssets(), context.getString(R.string.font_extra_bold));
    }

    @Override
    public MyViewHolder onCreateViewHolder(final ViewGroup parent, int viewType) {
        View itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.brand_product_item, parent, false);

        return new MyViewHolder(itemView);
    }

    @Override
    public void onBindViewHolder(final MyViewHolder holder, final int position) {
        final Product product = mProducts.get(position);

        if(position != 0) {
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            lp.setMargins((int)Convert.DpToPixel(16, mContext), 0, 0, 0);
            holder.productView.setLayoutParams(lp);
        }

        holder.productView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent startProductActivityIntent = new Intent(mContext, ProductDetailActivity.class);
                startProductActivityIntent.putExtra("screen_origin", mContext.getClass().getSimpleName());
                startProductActivityIntent.putExtra("item", product);
                mContext.startActivity(startProductActivityIntent);
            }
        });

        DisplayMetrics dm = new DisplayMetrics();
        WindowManager windowManager = (WindowManager) mContext.getSystemService(WINDOW_SERVICE);
        windowManager.getDefaultDisplay().getMetrics(dm);
        int width = (int)(dm.widthPixels*0.7);

        holder.productView.getLayoutParams().width = width;

        String currency = PreferencesHelper.getInstance(mContext).getCurrency();

        TextView productPrice = holder.productView.findViewById(R.id.product_price);
        productPrice.setTypeface(mExtraBoldFont);
        productPrice.setText(getPriceString(product.getPriceInCurrency(currency), currency));

        if(product.getOriginalPrice() != null && product.getOriginalPrice().size() > 0 && product.getOriginalPriceInCurrency("eur") > 0) {
            TextView productOriginalPrice = holder.productView.findViewById(R.id.product_original_price);
            productOriginalPrice.setVisibility(View.VISIBLE);
            productOriginalPrice.setTypeface(mExtraBoldFont);
            productOriginalPrice.setText(getPriceString(product.getOriginalPriceInCurrency(currency), currency));
            productOriginalPrice.setPaintFlags(productOriginalPrice.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
        }

        TextView productName = holder.productView.findViewById(R.id.product_name);
        productName.setTypeface(mExtraBoldFont);
        productName.setText(product.getName());

        CircularProgressDrawable circularProgressDrawable = new CircularProgressDrawable(mContext);
        circularProgressDrawable.setStrokeWidth(10 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setCenterRadius(60 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setColorSchemeColors(mContext.getResources().getColor(R.color.progressBar));
        circularProgressDrawable.start();

        ImageView productImage = holder.productView.findViewById(R.id.product_image);
        productImage.getLayoutParams().width = width;
        productImage.getLayoutParams().height = (dm.heightPixels/dm.widthPixels) * width;
        Glide.with(mContext)
                .load(product.getImageURLs().get(0))
                .thumbnail(0.1f)
                .apply(new RequestOptions().placeholder(circularProgressDrawable))
                .into(productImage);
    }

    private String getPriceString(double value, String currency) {
        String productPrice = "";
        if (currency.equals(mContext.getString(R.string.shoppingInUsd))) {
            currency = "$ ";
            productPrice = String.valueOf(value);
        } else if (currency.equals(mContext.getString(R.string.shoppingInGbp))) {
            currency = "£ ";
            productPrice = String.valueOf(value);
        } else if (currency.equals(mContext.getString(R.string.shoppingInDkk))) {
            currency = "Kr. ";
            productPrice = String.valueOf(value);
        } else if (currency.equals(mContext.getString(R.string.shoppingInEur))) {
            productPrice = String.valueOf(value);
            currency = "€ ";
        }
        return currency + productPrice;
    }

    public void clear() {
        mProducts.clear();
        notifyDataSetChanged();
    }

    @Override
    public int getItemCount() {
        return mProducts.size();
    }
}