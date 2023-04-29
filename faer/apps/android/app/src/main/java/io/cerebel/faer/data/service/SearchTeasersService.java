package io.cerebel.faer.data.service;

import android.content.Context;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;
import com.google.android.gms.maps.model.LatLng;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import io.cerebel.faer.data.model.BrandSpotlight;
import io.cerebel.faer.data.model.CategoryTeaser;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.model.SearchTeasers;
import io.cerebel.faer.data.model.ShopNearby;
import io.cerebel.faer.data.model.Teaser;

public class SearchTeasersService {
    private static SearchTeasersService mInstance;
    private final Context mContext;
    private RequestQueue mRequestQueue;

    private SearchTeasersService(Context context) {
        mContext = context;
        mRequestQueue = getRequestQueue();
    }

    private static synchronized SearchTeasersService getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new SearchTeasersService(context);
        }
        return mInstance;
    }

    public static void getTeasers(Context context, String gender, LatLng location, final Response.Listener<SearchTeasers>
            listener, Response.ErrorListener errorListener) {
        String url = String.format(Locale.ENGLISH, "https://api.cerebel.io/v3/store/faer/search/teasers?token=AonNLZaEXMtLiHdqJqqGQjKrVRGMhq&gender=%s", gender);
        if(location != null) {
            url += String.format("&lat=%f&lon=%f", location.latitude, location.longitude);
        }
        JsonObjectRequest stringRequest = new JsonObjectRequest(Request.Method.GET, url, null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject response) {
                        List<Teaser<CategoryTeaser>> categoriesTeasers = new ArrayList<>();
                        List<Teaser<BrandSpotlight>> brandsTeasers = new ArrayList<>();
                        Teaser<ShopNearby> shopsTeaser = null;
                        try {

                            JSONArray items = response.getJSONArray("items");
                            for (int i = 0; i < items.length(); i++) {
                                JSONObject item = items.getJSONObject(i);
                                String type = item.getString("type");

                                if (type.equals("categories")) {
                                    // categories teaser
                                    String title = item.getString("name");
                                    List<CategoryTeaser> categories = new ArrayList<>();
                                    JSONArray catArray = item.getJSONArray("items");
                                    for (int j = 0; j < catArray.length(); j++) {
                                        JSONObject catItem = catArray.getJSONObject(j);
                                        categories.add(new CategoryTeaser(catItem.getString("image_url"),
                                                catItem.getString("title")));
                                    }
                                    categoriesTeasers.add(new Teaser<>(title, categories));
                                } else if(type.equals("brands")) {
                                    // brands teaser
                                    String title = item.getString("name");
                                    List<BrandSpotlight> brands = new ArrayList<>();
                                    JSONArray brandsArray = item.getJSONArray("items");
                                    for(int j=0; j<brandsArray.length(); j++) {
                                        JSONObject brandItem = brandsArray.getJSONObject(j);
                                        List<Product> products = new ArrayList<>();
                                        JSONArray prodsArray = brandItem.getJSONArray("products");
                                        for(int k=0; k<prodsArray.length(); k++) {
                                            products.add(Product.fromJSONObject(prodsArray.getJSONObject(k)));
                                        }
                                        brands.add(new BrandSpotlight(brandItem.getString("id"), brandItem.getString("title"), products));
                                    }
                                    brandsTeasers.add(new Teaser<>(title, brands));
                                } else if(type.equals("map")) {
                                    // maps teaser
                                    String title = item.getString("name");
                                    List<ShopNearby> shops = new ArrayList<>();
                                    if(item.has("items")) {
                                        JSONArray shopArray = item.getJSONArray("items");
                                        for (int j = 0; j < shopArray.length(); j++) {
                                            JSONObject shopItem = shopArray.getJSONObject(j);
                                            JSONObject loc = shopItem.getJSONObject("location");
                                            shops.add(new ShopNearby(shopItem.getString("brand"),
                                                    shopItem.getString("name"),
                                                    shopItem.getString("country"),
                                                    shopItem.getString("city"),
                                                    new LatLng(loc.getDouble("lat"), loc.getDouble("lon"))));
                                        }
                                    }
                                    shopsTeaser = new Teaser<>(title, shops);
                                }
                            }

                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                        listener.onResponse(new SearchTeasers(categoriesTeasers, brandsTeasers, shopsTeaser));

                    }
                }, errorListener);
        SearchTeasersService.getInstance(context).addToRequestQueue(stringRequest);
    }

    private RequestQueue getRequestQueue() {
        if (mRequestQueue == null) {
            mRequestQueue = Volley.newRequestQueue(mContext.getApplicationContext());
        }
        return mRequestQueue;
    }

    private <T> void addToRequestQueue(Request<T> req) {
        getRequestQueue().add(req);
    }
}