package io.cerebel.faer.data.remote;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;

import com.google.firebase.analytics.FirebaseAnalytics;

public class AppEventLogger {
    private static AppEventLogger mInstance;
    private final FirebaseAnalytics mFirebaseAnalytics;

    private AppEventLogger(FirebaseAnalytics firebaseAnalytics) {
        this.mFirebaseAnalytics = firebaseAnalytics;
    }

    public static AppEventLogger getInstance(Context ctx) {
        if(mInstance == null) {
            mInstance = new AppEventLogger(FirebaseAnalytics.getInstance(ctx));
        }
        return mInstance;
    }

    public void logSearch(String searchTerm, String searchType) {
        Bundle params = new Bundle();
        params.putString("search_term", searchTerm);
        params.putString("search_type", searchType);
        mFirebaseAnalytics.logEvent(FirebaseAnalytics.Event.SEARCH, params);
    }

    public void logViewSearchResults(String searchTerm, int resultCount) {
        Bundle params = new Bundle();
        params.putString("search_term", searchTerm);
        params.putInt("result_count", resultCount);
        mFirebaseAnalytics.logEvent(FirebaseAnalytics.Event.VIEW_SEARCH_RESULTS, params);
    }

    public void logVisitShop(String productID, String productName, String productBrand, double productPrice, String productCurrency) {
        Bundle params = new Bundle();
        params.putString("item_id", productID);
        params.putString("item_name", productName);
        params.putString("item_brand", productBrand);
        params.putDouble("price", productPrice);
        params.putString("currency", productCurrency);
        mFirebaseAnalytics.logEvent(FirebaseAnalytics.Event.PRESENT_OFFER, params);
    }

    public void logCurrentScreenClass(Activity activity, String screenName, String screenClass) {
        mFirebaseAnalytics.setCurrentScreen(activity, screenName, screenClass);
    }

    public void logShare(String productID, String productName, String productBrand, double productPrice, String productCurrency) {
        Bundle params = new Bundle();
        params.putString("item_id", productID);
        params.putString("item_name", productName);
        params.putString("item_brand", productBrand);
        params.putDouble("price", productPrice);
        params.putString("currency", productCurrency);
        mFirebaseAnalytics.logEvent(FirebaseAnalytics.Event.SHARE, params);
    }

    public void logAddToWishlist(String productID, String productName, String productBrand, double productPrice, String productCurrency) {
        Bundle params = new Bundle();
        params.putString("item_id", productID);
        params.putString("item_name", productName);
        params.putString("item_brand", productBrand);
        params.putDouble("price", productPrice);
        params.putString("currency", productCurrency);
        mFirebaseAnalytics.logEvent(FirebaseAnalytics.Event.ADD_TO_WISHLIST, params);
    }

    public void logRemoveFromWishlist(String productID) {
        Bundle params = new Bundle();
        params.putString("item_id", productID);
        mFirebaseAnalytics.logEvent("remove_from_wishlist", params);
    }

    public void logViewProduct(String productID, String productName, String productBrand, double productPrice, String productCurrency, String screenOrigin) {
        Bundle params = new Bundle();
        params.putString("item_id", productID);
        params.putString("item_name", productName);
        params.putString("item_brand", productBrand);
        params.putDouble("price", productPrice);
        params.putString("currency", productCurrency);
        params.putString("screen_origin", screenOrigin);
        mFirebaseAnalytics.logEvent(FirebaseAnalytics.Event.VIEW_ITEM, params);
    }

    public void logBeginCheckout(String productID, String productName, String productBrand, double productPrice, String productCurrency) {
        Bundle params = new Bundle();
        params.putString("item_id", productID);
        params.putString("item_name", productName);
        params.putString("item_brand", productBrand);
        params.putDouble("price", productPrice);
        params.putString("currency", productCurrency);
        mFirebaseAnalytics.logEvent(FirebaseAnalytics.Event.BEGIN_CHECKOUT, params);
    }

    public void logSurveyBegan() {
        mFirebaseAnalytics.logEvent("inapp_survey_began", null);
    }

    public void logSurveyCancelled() {
        mFirebaseAnalytics.logEvent("inapp_survey_cancelled", null);
    }

    public void logSurveyCompleted(int score, String email, String feedbackText) {
        Bundle params = new Bundle();
        params.putInt("score", score);
        params.putString("email", email);
        params.putString("feedback_text", feedbackText);
        mFirebaseAnalytics.logEvent("inapp_survey_completed", params);
    }

    public void logSubscribeNewsletter(String emailAddress) {
        Bundle params = new Bundle();
        params.putString("email", emailAddress);
        mFirebaseAnalytics.logEvent("newsletter_subscribed", params);
    }

}
