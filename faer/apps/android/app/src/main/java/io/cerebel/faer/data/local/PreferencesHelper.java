package io.cerebel.faer.data.local;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import io.cerebel.faer.R;

public class PreferencesHelper {
    private static PreferencesHelper mInstance = null;
    private final Context mContext;
    private final SharedPreferences mSharedPreferences;

    public static PreferencesHelper getInstance(Context ctx) {
        if(mInstance == null) {
            mInstance = new PreferencesHelper(ctx.getApplicationContext());
        }
        return mInstance;
    }

    private PreferencesHelper(Context context) {
        this.mContext = context;
        this.mSharedPreferences = PreferenceManager.getDefaultSharedPreferences(context);
    }

    public void setGender(String gender) {
        mSharedPreferences.edit().putString(mContext.getString(R.string.genderSettings), gender).apply();
    }

    public String getGender() {
        return mSharedPreferences.getString(mContext.getString(R.string.genderSettings), "women");
    }

    public void setCurrency(String currency) {
        mSharedPreferences.edit().putString(mContext.getString(R.string.currencySettings), currency).apply();
    }

    public String getCurrency() {
        return mSharedPreferences.getString(mContext.getString(R.string.currencySettings), "eur");
    }

    public void setIsPushNotificationsEnabled(boolean value) {
        mSharedPreferences.edit().putBoolean(mContext.getString(R.string.pushNotificationsEnabled), value).apply();
    }

    public boolean isPushNotificationsEnabled() {
        return mSharedPreferences.getBoolean(mContext.getString(R.string.pushNotificationsEnabled), true);
    }

    public void setIsFirstSession(boolean value) {
        mSharedPreferences.edit().putBoolean(mContext.getString(R.string.first_session), value).apply();
    }

    public boolean isFirstSession() {
        return mSharedPreferences.getBoolean(mContext.getString(R.string.first_session), true);
    }

    public void setIsAskedAboutNewsletter(boolean value) {
        mSharedPreferences.edit().putBoolean("newsletterAsked", value).apply();
    }

    public boolean isAskedAboutNewsletter() {
        return mSharedPreferences.getBoolean("newsletterAsked", false);
    }

    public void setAppInstanceID(String value) {
        mSharedPreferences.edit().putString(mContext.getString(R.string.appInstanceID), value).apply();
    }

    public String getAppInstanceID() {
        return mSharedPreferences.getString(mContext.getString(R.string.appInstanceID), "");
    }

    public void setIsFirstMicSession(boolean value) {
        mSharedPreferences.edit().putBoolean(mContext.getString(R.string.firstMicrophoneSessionFragment), value).apply();
    }

    public boolean isFirstMicSession() {
        return mSharedPreferences.getBoolean(mContext.getString(R.string.firstMicrophoneSessionFragment), true);
    }

    public void setIsFirstCameraSession(boolean value) {
        mSharedPreferences.edit().putBoolean(mContext.getString(R.string.firstCameraSessionFragment), value).apply();
    }

    public boolean isFirstCameraSession() {
        return mSharedPreferences.getBoolean(mContext.getString(R.string.firstCameraSessionFragment), true);
    }

}
