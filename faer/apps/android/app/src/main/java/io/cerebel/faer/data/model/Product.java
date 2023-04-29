package io.cerebel.faer.data.model;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class Product implements Serializable {

    private String description;
    private String name;
    private final String url;
    private final String shareURL;
    private final String brand;
    private final String brandID;
    private String id;
    private final Map<String, Double> price;
    private final Map<String, Double> originalPrice;
    private final List<String> image_urls;
    private final List<Store> stores;
    private final List<String> categories;
    private String promotion;

    public Product(String id, String description, String name, String url, String shareURL,
                   Map<String, Double> price, Map<String, Double> originalPrice, List<String> image_urls,
                   List<Store> stores, String brandName, String brandID, List<String> categories, String promotion) {

        this.id = id;
        this.description = description;
        this.name = name;
        this.url = url;
        this.shareURL = shareURL;
        this.price = price;
        this.originalPrice = originalPrice;
        this.image_urls = image_urls;
        this.stores = stores;
        this.brand = brandName;
        this.brandID = brandID;
        this.categories = categories;
        this.promotion = promotion;
    }

    public static Product fromJSONObject(JSONObject obj) throws JSONException {
        String id = obj.getString("id");
        String name = obj.getString("name");
        String description = obj.getString("description");
        String brand = obj.getString("brand");
        String brandID = obj.getString("brand_id");
        String url = obj.getString("url");
        String shareURL = obj.optString("share_url", url);

        String promotion = "";
        if(obj.has("promotion")) {
            promotion = obj.getString("promotion");
        }

        JSONArray imageURLsObj = obj.getJSONArray("image_url");
        List<String> imageURLs = new ArrayList<>(imageURLsObj.length());
        for (int i = 0; i < imageURLsObj.length(); i++) {
            imageURLs.add(imageURLsObj.getString(i));
        }

        JSONObject priceObj = obj.getJSONObject("price");
        Iterator<String> priceKeys = priceObj.keys();
        Map<String, Double> price = new HashMap<>();
        while (priceKeys.hasNext()) {
            String key = priceKeys.next();
            price.put(key, priceObj.getDouble(key));
        }

        Map<String, Double> originalPrice = null;
        if (obj.has("original_price")) {
            JSONObject originalPriceObj = obj.getJSONObject("original_price");
            Iterator<String> originalPriceKeys = originalPriceObj.keys();
            originalPrice = new HashMap<>();
            while (originalPriceKeys.hasNext()) {
                String key = originalPriceKeys.next();
                originalPrice.put(key, originalPriceObj.getDouble(key));
            }
        }

        List<Store> stores = null;
        if (obj.has("stores")) {
            JSONArray storesArray = obj.getJSONArray("stores");
            stores = new ArrayList<>(storesArray.length());
            for (int storeIndex = 0; storeIndex < storesArray.length(); storeIndex++) {
                JSONObject currentStore = storesArray.getJSONObject(storeIndex);
                JSONObject location = currentStore.getJSONObject("location");

                String country = currentStore.getString("country");
                String address = currentStore.getString("address");
                String city = currentStore.getString("city");
                String storeName = currentStore.getString("name");
                double lon = location.getDouble("lon");
                double lat = location.getDouble("lat");
                String postal_code = currentStore.getString("postal_code");
                Store store = new Store(country, address, city, storeName, lon, lat, postal_code);
                stores.add(store);
            }
        }

        List<String> categories = null;
        if (obj.has("annotations")) {
            JSONObject annotation = obj.getJSONObject("annotations");
            if (annotation.has("category")) {
                categories = new ArrayList<>();
                JSONArray category = annotation.getJSONArray("category");
                for (int categoryIndex = 0; categoryIndex < category.length(); categoryIndex++) {
                    String currentCategory = category.getString(categoryIndex);
                    categories.add(currentCategory);
                }
            }
        }

        return new Product(id, description, name, url, shareURL, price, originalPrice, imageURLs, stores, brand, brandID, categories, promotion);
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getURL() {
        return url;
    }

    public String getShareURL() {
        return shareURL;
    }

    public String getBrand() {
        return brand;
    }

    public String getBrandID() {
        return brandID;
    }

    public List<String> getImageURLs() {
        return image_urls;
    }

    public List<Store> getStores() {
        return stores;
    }

    public Map<String, Double> getPrice() {
        return price;
    }

    public Map<String, Double> getOriginalPrice() {
        return originalPrice;
    }

    public double getPriceInCurrency(String currency) {
        return price.get(currency);
    }

    public double getOriginalPriceInCurrency(String currency) {
        return originalPrice.get(currency);
    }

    public List<String> getCategories() {
        return categories;
    }

    public String getPromotion() {
        return promotion;
    }

    public void setPromotion(String value) {
        this.promotion = value;
    }
}
