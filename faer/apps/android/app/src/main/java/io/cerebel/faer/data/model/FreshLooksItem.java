package io.cerebel.faer.data.model;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.Serializable;


public class FreshLooksItem implements Serializable {
    private Product product;
    private final String imageURL;
    private final String source;

    private FreshLooksItem(Product item, String imageURL, String source) {
        this.product = item;
        this.imageURL = imageURL;
        this.source = source;
    }

    public static FreshLooksItem fromJSONObject(JSONObject obj) throws JSONException {
        String imageURL = obj.getString("image_url");
        String source = obj.getJSONObject("source").getString("name");

        JSONArray items = obj.getJSONArray("items");
        Product product = Product.fromJSONObject(items.getJSONObject(0));

        return new FreshLooksItem(product, imageURL, source);
    }

    public String getImageURL() {
        return imageURL;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
    }

    public String getSource() {
        return this.source;
    }
}
