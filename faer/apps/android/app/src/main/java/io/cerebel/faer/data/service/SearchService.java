package io.cerebel.faer.data.service;

import android.content.Context;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Locale;

import io.cerebel.faer.data.model.Product;

public class SearchService {
    private static SearchService mInstance;
    private final Context mContext;
    private RequestQueue mRequestQueue;

    private SearchService(Context context) {
        mContext = context;
        mRequestQueue = getRequestQueue();
    }

    private static synchronized SearchService getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new SearchService(context);
        }
        return mInstance;
    }

    public static void getProduct(Context context, String productID, final Response.Listener<Product>
            listener, Response.ErrorListener errorListener) {
        String url = String.format(Locale.ENGLISH, "https://api.cerebel.io/v3/store/faer/item/%s?token=AonNLZaEXMtLiHdqJqqGQjKrVRGMhq", productID);
        JsonObjectRequest request = new JsonObjectRequest(Request.Method.GET, url, null, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject response) {
                try {
                    JSONObject matches = response.getJSONObject("matches");
                    JSONArray items = matches.getJSONArray("items");
                    if(items.length() > 0) {
                        listener.onResponse(Product.fromJSONObject(items.getJSONObject(0)));
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }, errorListener);
        SearchService.getInstance(context).addToRequestQueue(request);
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
