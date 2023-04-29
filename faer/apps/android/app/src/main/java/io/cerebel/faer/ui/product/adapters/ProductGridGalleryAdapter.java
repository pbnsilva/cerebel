package io.cerebel.faer.ui.product.adapters;

import android.content.Context;
import android.content.Intent;
import androidx.swiperefreshlayout.widget.CircularProgressDrawable;
import androidx.recyclerview.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.ui.product.ProductDetailActivity;
import io.cerebel.faer.ui.product.SquareImageView;

public class ProductGridGalleryAdapter extends RecyclerView.Adapter<ProductGridGalleryAdapter.ProductImageViewHolder> {
    private final List<Product> mItems;
    private final Context mContext;

    public static class ProductImageViewHolder extends RecyclerView.ViewHolder {
        final SquareImageView mImageView;

        ProductImageViewHolder(SquareImageView v) {
            super(v);
            mImageView = v;
        }
    }

    public ProductGridGalleryAdapter(List<Product> items, Context ctx) {
        mItems = items;
        mContext = ctx;
    }

    public void clear() {
        mItems.clear();
    }

    @Override
    public ProductGridGalleryAdapter.ProductImageViewHolder onCreateViewHolder(ViewGroup parent,
                                                                               int viewType) {
        SquareImageView v = (SquareImageView) LayoutInflater.from(parent.getContext())
                .inflate(R.layout.view_grid_gallery_image, parent, false);

        return new ProductImageViewHolder(v);
    }

    @Override
    public void onBindViewHolder(ProductImageViewHolder holder, final int position) {
        final Product item = mItems.get(position);
        String imageURL = item.getImageURLs().get(0);

        CircularProgressDrawable circularProgressDrawable = new CircularProgressDrawable(mContext);
        circularProgressDrawable.setStrokeWidth(10 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setCenterRadius(60 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setColorSchemeColors(mContext.getResources().getColor(R.color.progressBar));
        circularProgressDrawable.start();

        holder.mImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent startProductActivityIntent = new Intent(mContext, ProductDetailActivity.class);
                startProductActivityIntent.putExtra("screen_origin", mContext.getClass().getSimpleName());
                startProductActivityIntent.putExtra("item", item);
                mContext.startActivity(startProductActivityIntent);
            }
        });

        Glide.with(mContext)
                .load(imageURL)
                .thumbnail(0.1f)
                .apply(new RequestOptions().placeholder(circularProgressDrawable))
                .into(holder.mImageView);
    }

    @Override
    public int getItemCount()
    {
        return mItems.size();
    }
}

