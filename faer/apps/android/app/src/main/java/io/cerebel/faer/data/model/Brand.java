package io.cerebel.faer.data.model;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class Brand implements Serializable {
    private final String id;
    private final String name;
    private final String url;
    private final String description;
    private final List<String> tags;
    private final String location;
    private final String priceRange;
    private final List<Product> popularProducts;
    private final List<CategoryProducts> categoryProducts;

    private Brand(String id, String name, String url, String description, List<String> tags, String location, String priceRange, List<Product> popularProducts, List<CategoryProducts> categoryProducts) {
        this.id = id;
        this.name = name;
        this.url = url;
        this.description = description;
        this.tags = tags;
        this.location = location;
        this.priceRange = priceRange;
        this.popularProducts = popularProducts;
        this.categoryProducts = categoryProducts;
    }

    public static Brand fromJSONObject(JSONObject obj) throws JSONException {
        String id = obj.getString("id");
        String name = obj.getString("name");
        String url = obj.getString("url");
        String location = obj.getString("location");
        String priceRange = obj.getString("price_range");

        String description = "";
        if(obj.has("description")) {
            description = obj.getString("description");
        }

        List<String> tags = new ArrayList<>();
        if(obj.has("tags")) {
            JSONArray tagsObj = obj.getJSONArray("tags");
            for (int i = 0; i < tagsObj.length(); i++) {
                tags.add(tagsObj.getString(i));
            }
        }

        List<Product> popularProducts = new ArrayList<>();
        if(obj.has("popular_products")) {
            JSONArray productsObj = obj.getJSONArray("popular_products");
            for (int i = 0; i < productsObj.length(); i++) {
                popularProducts.add(Product.fromJSONObject(productsObj.getJSONObject(i)));
            }
        }

        List<CategoryProducts> categoryProducts = new ArrayList<>();
        if(obj.has("categories")) {
            JSONArray catsObj = obj.getJSONArray("categories");
            for (int i = 0; i < catsObj.length(); i++) {
                JSONObject cat = catsObj.getJSONObject(i);
                String catName = cat.getString("name");
                JSONArray prodsObj = cat.getJSONArray("products");
                List<Product> prods = new ArrayList<>();
                for (int j = 0; j < prodsObj.length(); j++) {
                    prods.add(Product.fromJSONObject(prodsObj.getJSONObject(j)));
                }
                categoryProducts.add(new CategoryProducts(catName, prods));
            }
        }

        return new Brand(id, name, url, description, tags, location, priceRange, popularProducts, categoryProducts);
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getUrl() {
        return url;
    }

    public String getDescription() {
        return description;
    }

    public List<String> getTags() {
        return tags;
    }

    public String getLocation() {
        return location;
    }

    public String getPriceRange() {
        return priceRange;
    }

    public List<Product> getPopularProducts() {
        return popularProducts;
    }

    public List<CategoryProducts> getCategoryProducts() {
        return categoryProducts;
    }
}
