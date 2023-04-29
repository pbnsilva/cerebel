package io.cerebel.faer.data.model;

import java.util.List;

public class CategoryProducts {
    private final String mCategoryName;
    private final List<Product> mProducts;

    public CategoryProducts(String name, List<Product> products) {
        mCategoryName = name;
        mProducts = products;
    }

    public String getCategoryName() {
        return mCategoryName;
    }

    public List<Product> getProducts() {
        return mProducts;
    }
}
