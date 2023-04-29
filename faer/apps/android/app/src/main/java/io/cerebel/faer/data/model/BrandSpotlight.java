package io.cerebel.faer.data.model;

import java.util.List;

public class BrandSpotlight {
    private final String mBrandID;
    private final String mBrandName;
    private final List<Product> mProducts;

    public BrandSpotlight(String id, String title, List<Product> products) {
        mBrandID = id;
        mBrandName = title;
        mProducts = products;
    }

    public String getBrandID() {
        return mBrandID;
    }

    public String getBrandName() {
        return mBrandName;
    }

    public List<Product> getProducts() {
        return mProducts;
    }
}
