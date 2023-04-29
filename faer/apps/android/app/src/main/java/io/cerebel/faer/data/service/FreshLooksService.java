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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.cerebel.faer.data.model.FreshLooksItem;

public class FreshLooksService {
    private static FreshLooksService mInstance;
    private final Context mContext;
    private RequestQueue mRequestQueue;

    private FreshLooksService(Context context) {
        mContext = context;
        mRequestQueue = getRequestQueue();
    }

    private static synchronized FreshLooksService getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new FreshLooksService(context);
        }
        return mInstance;
    }

    public static void getFeed(final Context context, String gender, int page, final String userID, final Response.Listener<List<FreshLooksItem>>
            listener, Response.ErrorListener errorListener) {
        String url = String.format(Locale.ENGLISH, "https://api.cerebel.io/v3/store/faer/feed?token=AonNLZaEXMtLiHdqJqqGQjKrVRGMhq&gender=%s&page=%d", gender, page);
        JsonObjectRequest request = new JsonObjectRequest(Request.Method.GET, url, null, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject response) {
                try {
                    JSONArray records  = response.getJSONArray("records");
                    List<FreshLooksItem> result = new ArrayList<>(records.length());
                    for(int i=0; i<records.length(); i++) {
                        FreshLooksItem item = FreshLooksItem.fromJSONObject(records.getJSONObject(i));

                        if(!item.getSource().equals("catalog")) {
                            item.getProduct().getImageURLs().add(0, item.getImageURL());
                        }

                        result.add(item);
                    }
                    listener.onResponse(result);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }, errorListener) {
            @Override
            public Map<String, String> getHeaders() {
                Map<String, String> headers = new HashMap<>();
                if(!userID.equals("")) {
                    headers.put("X-User-Id", userID);
                }
                return headers;
            }
        };
        FreshLooksService.getInstance(context).addToRequestQueue(request);
    }

    private RequestQueue getRequestQueue() {
        if (mRequestQueue == null) {
            mRequestQueue = Volley.newRequestQueue(mContext);
        }
        return mRequestQueue;
    }

    private <T> void addToRequestQueue(Request<T> req) {
        getRequestQueue().add(req);
    }
}
