package io.cerebel.faer.ui.brand;

import android.content.Context;
import android.graphics.Typeface;
import androidx.constraintlayout.widget.ConstraintLayout;
import android.util.AttributeSet;
import android.widget.ListView;
import android.widget.TextView;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.BrandSpotlight;
import io.cerebel.faer.data.model.Teaser;
import io.cerebel.faer.ui.brand.adapters.BrandSpotlightAdapter;

public class BrandSpotlightView extends ConstraintLayout {
    private TextView mTitleTextView;
    private BrandSpotlightAdapter mAdapter;

    public BrandSpotlightView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        inflate(getContext(), R.layout.view_brand_spotlight, this);

        Typeface mMediumFont = Typeface.createFromAsset(getContext().getAssets(), getContext().getString(R.string.font_medium));

        mTitleTextView = findViewById(R.id.brand_spotlight_title);
        mTitleTextView.setTypeface(mMediumFont);

        mAdapter = new BrandSpotlightAdapter(getContext());
        ListView mListView = findViewById(R.id.brands_list_view);
        mListView.setAdapter(mAdapter);
    }

    public void setTeaser(Teaser<BrandSpotlight> teaser) {
        mTitleTextView.setText(teaser.getTitle());
        mAdapter.setItems(teaser.getItems());
        mAdapter.notifyDataSetChanged();
    }
}
