package io.cerebel.faer.data.model;

import java.io.Serializable;

public class Store implements Serializable {

    private String country;
    private String address;
    private String city;
    private String name;
    private Double lon;
    private Double lat;
    private String postal_code;
    public Store(String country, String address, String city, String name, Double lon, Double lat, String postal_code) {
        this.country = country;
        this.address = address;
        this.city = city;
        this.name = name;
        this.lon = lon;
        this.lat = lat;
        this.postal_code = postal_code;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Double getLon() {
        return lon;
    }

    public void setLon(Double lon) {
        this.lon = lon;
    }

    public Double getLat() {
        return lat;
    }

    public void setLat(Double lat) {
        this.lat = lat;
    }

    public String getPostal_code() {
        return postal_code;
    }

    public void setPostal_code(String postal_code) {
        this.postal_code = postal_code;
    }
}
