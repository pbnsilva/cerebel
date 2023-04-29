package io.cerebel.faer.data.service;

import android.content.Context;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class SuggesterService {
    private static SuggesterService mInstance;
    private final Context mContext;
    private RequestQueue mRequestQueue;

    private SuggesterService(Context context) {
        mContext = context;
        mRequestQueue = getRequestQueue();
    }

    private static synchronized SuggesterService getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new SuggesterService(context);
        }
        return mInstance;
    }

    public static void getSuggestions(Context context, String query, String gender, int size, final Response.Listener<List<String>>
            listener, Response.ErrorListener errorListener) {
        String url = String.format(Locale.ENGLISH, "https://api.cerebel.io/store/faer/suggest?token=AonNLZaEXMtLiHdqJqqGQjKrVRGMhq&size=%d&gender=%s&q=%s", size, gender, query);
        JsonObjectRequest stringRequest = new JsonObjectRequest(Request.Method.GET, url, null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject response) {
                        List<String> stringList = new ArrayList<>();
                        try {
                            JSONArray array = response.getJSONArray("suggestions");
                            for (int i = 0; i < array.length(); i++) {
                                JSONObject row = array.getJSONObject(i);
                                stringList.add(row.getString("value"));
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                        listener.onResponse(stringList);

                    }
                }, errorListener);
        SuggesterService.getInstance(context).addToRequestQueue(stringRequest);
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