package io.cerebel.faer.ui.product.adapters;

import android.content.Context;
import androidx.swiperefreshlayout.widget.CircularProgressDrawable;
import androidx.recyclerview.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;

import java.util.List;

import io.cerebel.faer.R;

public class ProductGalleryAdapter extends RecyclerView.Adapter<ProductGalleryAdapter.ProductImageViewHolder> {
    private List<String> mImageURLs;
    private final Context mContext;

    public static class ProductImageViewHolder extends RecyclerView.ViewHolder {
        final ImageView mImageView;

        ProductImageViewHolder(ImageView v) {
            super(v);
            mImageView = v;
        }
    }

    public ProductGalleryAdapter(Context ctx) {
        mContext = ctx;
    }

    public void setImages(List<String> imageURLs) {
        mImageURLs = imageURLs;
    }

    public void clear() {
        mImageURLs.clear();
    }

    @Override
    public ProductGalleryAdapter.ProductImageViewHolder onCreateViewHolder(ViewGroup parent,
                                                                           int viewType) {
        ImageView v = (ImageView) LayoutInflater.from(parent.getContext())
                .inflate(R.layout.view_gallery_image, parent, false);

        return new ProductImageViewHolder(v);
    }

    @Override
    public void onBindViewHolder(ProductImageViewHolder holder, int position) {
        String imageURL = mImageURLs.get(position);

        CircularProgressDrawable circularProgressDrawable = new CircularProgressDrawable(mContext);
        circularProgressDrawable.setStrokeWidth(10 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setCenterRadius(60 / mContext.getResources().getDisplayMetrics().density);
        circularProgressDrawable.setColorSchemeColors(mContext.getResources().getColor(R.color.progressBar));
        circularProgressDrawable.start();

        Glide.with(mContext)
                .load(imageURL)
                .thumbnail(0.1f)
                .apply(new RequestOptions().placeholder(circularProgressDrawable))
                .into(holder.mImageView);
    }

    @Override
    public int getItemCount() {
        return mImageURLs.size();
    }
}
