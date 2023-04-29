package io.cerebel.faer.data.service;

import android.content.Context;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONObject;

import java.util.Locale;

import io.cerebel.faer.data.model.Brand;

public class BrandService {
    private static BrandService mInstance;
    private final Context mContext;
    private RequestQueue mRequestQueue;

    private BrandService(Context context) {
        mContext = context;
        mRequestQueue = getRequestQueue();
    }

    private static synchronized BrandService getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new BrandService(context);
        }
        return mInstance;
    }

    public static void getBrand(Context context, String id, String gender, final Response.Listener<Brand>
            listener, Response.ErrorListener errorListener) {
        String url = String.format(Locale.ENGLISH, "https://api.cerebel.io/v3/store/faer/brand/%s?token=AonNLZaEXMtLiHdqJqqGQjKrVRGMhq&gender=%s", id, gender);
        JsonObjectRequest stringRequest = new JsonObjectRequest(Request.Method.GET, url, null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject response) {
                        try {
                            JSONObject brandObj = response.getJSONObject("brand");
                            Brand brand = Brand.fromJSONObject(brandObj);
                            listener.onResponse(brand);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }

                    }
                }, errorListener);
        BrandService.getInstance(context).addToRequestQueue(stringRequest);
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