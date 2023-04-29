package io.cerebel.faer.data.model;

public class CategoryTeaser {
    private final String mImageURL;
    private final String mTitle;

    public CategoryTeaser(String imageURL, String title) {
       mImageURL = imageURL;
       mTitle = title;
    }

    public String getImageURL() {
        return mImageURL;
    }

    public String getTitle() {
        return mTitle;
    }
}
