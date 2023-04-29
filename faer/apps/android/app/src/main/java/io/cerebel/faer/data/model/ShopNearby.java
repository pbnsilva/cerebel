package io.cerebel.faer.data.model;

import com.google.android.gms.maps.model.LatLng;

public class ShopNearby {
    private final String mBrand;
    private final String mName;
    private final String mCountry;
    private final String mCity;
    private final LatLng mLocation;

    public ShopNearby(String brand, String name, String country, String city, LatLng location) {
        mBrand = brand;
        mName = name;
        mCountry = country;
        mCity = city;
        mLocation = location;
    }

    public String getBrand() {
        return mBrand;
    }

    public String getName() {
        return mName;
    }

    public String getCountry() {
        return mCountry;
    }

    public String getCity() {
        return mCity;
    }

    public LatLng getLocation() {
        return mLocation;
    }
}
