package io.cerebel.faer.data.model;

import java.util.List;

public class Teaser<T> {
    private final String mTitle;
    private final List<T> mItems;

    public Teaser(String title, List<T> items) {
        mTitle = title;
        mItems = items;
    }

    public String getTitle() {
        return mTitle;
    }

    public List<T> getItems() {
        return mItems;
    }
}
