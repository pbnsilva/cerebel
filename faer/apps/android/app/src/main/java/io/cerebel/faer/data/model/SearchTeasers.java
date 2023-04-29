package io.cerebel.faer.data.model;

import java.util.List;

public class SearchTeasers {
    private final List<Teaser<CategoryTeaser>> mCategoriesTeaser;
    private final List<Teaser<BrandSpotlight>> mBrandSpotlightTeaser;
    private final Teaser<ShopNearby> mShopsNearbyTeaser;

    public SearchTeasers(List<Teaser<CategoryTeaser>> categoriesTeaser, List<Teaser<BrandSpotlight>> brandsTeaser, Teaser<ShopNearby> shopsTeaser) {
        mCategoriesTeaser = categoriesTeaser;
        mBrandSpotlightTeaser = brandsTeaser;
        mShopsNearbyTeaser = shopsTeaser;
    }

    public List<Teaser<CategoryTeaser>> getCategoriesTeasers() {
        return mCategoriesTeaser;
    }

    public List<Teaser<BrandSpotlight>> getBrandsTeasers() {
        return mBrandSpotlightTeaser;
    }

    public Teaser<ShopNearby> getShopsTeaser() {
        return mShopsNearbyTeaser;
    }
}
