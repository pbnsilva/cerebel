package io.cerebel.faer.ui.search;

import android.content.Context;
import android.graphics.Typeface;
import androidx.constraintlayout.widget.ConstraintLayout;
import android.util.AttributeSet;
import android.util.Log;
import android.widget.GridView;
import android.widget.TextView;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.CategoryTeaser;
import io.cerebel.faer.data.model.Teaser;
import io.cerebel.faer.ui.search.adapters.SearchCategoriesAdapter;

public class SearchCategoriesView extends ConstraintLayout {
    private TextView mTitleTextView;
    private SearchCategoriesAdapter mAdapter;

    public SearchCategoriesView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        inflate(getContext(), R.layout.view_search_categories, this);

        Typeface mMediumFont = Typeface.createFromAsset(getContext().getAssets(), getContext().getString(R.string.font_medium));

        mTitleTextView = findViewById(R.id.search_categories_title);
        mTitleTextView.setTypeface(mMediumFont);

        mAdapter = new SearchCategoriesAdapter(getContext());
        GridView grid = findViewById(R.id.search_categories_grid);
        grid.setAdapter(mAdapter);
    }

    public void setTeaser(Teaser<CategoryTeaser> teaser) {
        mTitleTextView.setText(teaser.getTitle());
        mAdapter.setItems(teaser.getItems());
        mAdapter.notifyDataSetChanged();
    }
}
