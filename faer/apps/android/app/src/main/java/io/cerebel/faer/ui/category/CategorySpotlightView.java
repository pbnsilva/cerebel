package io.cerebel.faer.ui.category;

import android.content.Context;
import androidx.constraintlayout.widget.ConstraintLayout;
import android.util.AttributeSet;
import android.widget.ListView;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.CategoryProducts;
import io.cerebel.faer.ui.category.adapters.CategorySpotlightAdapter;

public class CategorySpotlightView extends ConstraintLayout {
    private CategorySpotlightAdapter mAdapter;

    public CategorySpotlightView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        inflate(getContext(), R.layout.view_category_spotlight, this);

        mAdapter = new CategorySpotlightAdapter(getContext());
        ListView mListView = findViewById(R.id.categories_list_view);
        mListView.setAdapter(mAdapter);
    }

    public void setCategoryProducts(List<CategoryProducts> content) {
        mAdapter.setItems(content);
        mAdapter.notifyDataSetChanged();
    }

    public void clearCategoryProducts() {
        mAdapter.clear();
        mAdapter.notifyDataSetChanged();
    }
}
