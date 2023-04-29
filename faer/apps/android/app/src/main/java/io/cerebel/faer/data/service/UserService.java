package io.cerebel.faer.data.service;

import android.content.Context;
import androidx.annotation.NonNull;
import android.util.Log;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.analytics.FirebaseAnalytics;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;

class UserService {
    private static UserService mInstance;
    private final Context mContext;
    private RequestQueue mRequestQueue;

    private UserService(Context context) {
        mContext = context;
        mRequestQueue = getRequestQueue();
    }

    private static synchronized UserService getInstance(Context context) {
        if (mInstance == null) {
            mInstance = new UserService(context);
        }
        return mInstance;
    }

    public static void setFCMToken(final Context context, final String token, final Response.Listener<JSONObject>
            listener, final Response.ErrorListener errorListener) {
        FirebaseAnalytics.getInstance(context).getAppInstanceId().addOnCompleteListener(new OnCompleteListener<String>() {
            @Override
            public void onComplete(@NonNull Task<String> task) {
                if(!task.isSuccessful()) {
                    Log.w("Get app instance id", "error getting app instance ID");
                    return;
                }

                PreferencesHelper.getInstance(context).setAppInstanceID(task.getResult());

                String url = String.format("%s/%s", context.getString(R.string.user_api_base_url), task.getResult());

                try {
                    JSONObject body = new JSONObject();
                    body.put("fcm_token", token);
                    body.put("os", "android");

                    JsonObjectRequest request = new JsonObjectRequest(Request.Method.PUT, url, body, listener, errorListener) {
                        @Override
                        public Map<String, String> getHeaders() {
                            Map<String, String> header = new HashMap<>();
                            header.put("Content-Type", "application/json");
                            header.put("X-Cerebel-Token", context.getString(R.string.cerebel_api_token));
                            return header;
                        }
                    };

                    getInstance(context).addToRequestQueue(request);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });
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
