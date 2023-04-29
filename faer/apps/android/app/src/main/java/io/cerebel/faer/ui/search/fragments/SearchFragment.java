package io.cerebel.faer.ui.search.fragments;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Typeface;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.speech.RecognizerIntent;
import androidx.annotation.NonNull;
import androidx.fragment.app.DialogFragment;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.core.content.ContextCompat;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import android.util.DisplayMetrics;
import android.util.Size;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;

import java.util.ArrayList;
import java.util.Comparator;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.SearchTeasers;
import io.cerebel.faer.data.service.SearchTeasersService;
import io.cerebel.faer.ui.brand.BrandSpotlightView;
import io.cerebel.faer.ui.search.OnSearchListener;
import io.cerebel.faer.ui.search.SearchCategoriesView;
import io.cerebel.faer.ui.search.ShopsNearbyActivity;
import io.cerebel.faer.ui.search.ShopsNearbyView;
import io.cerebel.faer.ui.settings.SettingsActivity;
import io.cerebel.faer.util.Convert;
import io.nlopez.smartlocation.OnLocationUpdatedListener;
import io.nlopez.smartlocation.SmartLocation;
import io.nlopez.smartlocation.location.providers.LocationGooglePlayServicesProvider;

import static android.content.Context.WINDOW_SERVICE;
import static io.cerebel.faer.ui.settings.SettingsActivity.REQUEST_SETTINGS_UPDATE;
import static io.cerebel.faer.ui.settings.SettingsActivity.RESULT_GENDER_UPDATED;


public class SearchFragment extends Fragment implements OnLocationUpdatedListener {
    public static final String SEARCH_QUERY = "io.cerebel.faer.SEARCH_QUERY";
    public static final String SORT_BY = "io.cerebel.faer.SORT_BY";
    public static final String PRICE_FROM = "io.cerebel.faer.PRICE_FROM";
    public static final String PRICE_TO = "io.cerebel.faer.PRICE_TO";
    public static final String LOCATION = "io.cerebel.faer.LOCATION";
    public static final String WITH_FILTERS = "io.cerebel.faer.WITH_FILTERS";
    public static final String ON_SALE = "io.cerebel.faer.ON_SALE";
    private static final int REQUEST_CAMERA_PERMISSION = 1;
    private static final int REQUEST_MICROPHONE_PERMISSION = 2;

    private String mCurrentGender;

    private OnSearchListener mListener;

    private SearchCategoriesView mSearchCategoriesView1, mSearchCategoriesView2;
    private BrandSpotlightView mBrandSpotlightView1, mBrandSpotlightView2;
    private ShopsNearbyView mShopsNearbyView;

    private LinearLayout mLoadingLayout;
    private SwipeRefreshLayout mSwipeRefreshLayout;

    private SupportMapFragment mSupportMapFragment;

    private Location mCurrentLocation;
    private LocationGooglePlayServicesProvider mLocationProvider;

    public SearchFragment() {
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        loadTeasers();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_search, container, false);

        Typeface mExtraBoldFont = Typeface.createFromAsset(getContext().getApplicationContext().getAssets(), getString(R.string.font_extra_bold));
        Typeface mMediumFont = Typeface.createFromAsset(getContext().getApplicationContext().getAssets(), "fonts/Montserrat-Medium.ttf");

        TextView mSearchTextView = v.findViewById(R.id.search_text_view);
        mSearchTextView.setTypeface(mExtraBoldFont);
        mSearchTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                openAutoCompleteFragment();
            }
        });

        ImageView mSearchImage = v.findViewById(R.id.search_image);
        mSearchImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                openAutoCompleteFragment();
            }
        });

        TextView mSettingsTextView = v.findViewById(R.id.settings_textview);
        mSettingsTextView.setTypeface(mExtraBoldFont);
        mSettingsTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent settingIntent = new Intent(getActivity(), SettingsActivity.class);
                startActivityForResult(settingIntent, REQUEST_SETTINGS_UPDATE);
            }
        });

        mLoadingLayout = v.findViewById(R.id.loading_linear_layout);

        mSwipeRefreshLayout = v.findViewById(R.id.swipe_refresh_layout);
        mSwipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                loadTeasers();
            }
        });

        LinearLayout mNoInternetLayout = v.findViewById(R.id.no_internet_layout);
        TextView noInternetText = v.findViewById(R.id.no_internet_textview1);
        noInternetText.setTypeface(mMediumFont);

        DisplayMetrics dm = new DisplayMetrics();
        WindowManager windowManager = (WindowManager) getContext().getApplicationContext().getSystemService(WINDOW_SERVICE);
        windowManager.getDefaultDisplay().getMetrics(dm);

        Context ctx = getContext().getApplicationContext();

        mSearchCategoriesView1 = v.findViewById(R.id.search_categories_view1);
        mSearchCategoriesView1.getLayoutParams().height = (int) Convert.DpToPixel(80, ctx) + 3 * dm.widthPixels / 2;

        mSearchCategoriesView2 = v.findViewById(R.id.search_categories_view2);
        mSearchCategoriesView2.getLayoutParams().height = (int) Convert.DpToPixel(80, ctx) + 3 * dm.widthPixels / 2;

        int width = (int) (dm.widthPixels * 0.7);
        int height = (dm.heightPixels / dm.widthPixels) * width;
        mBrandSpotlightView1 = v.findViewById(R.id.brand_spotlight_view1);
        mBrandSpotlightView1.getLayoutParams().height = 4 * height + (int) Convert.DpToPixel(4 * 105, ctx);

        mBrandSpotlightView2 = v.findViewById(R.id.brand_spotlight_view2);
        mBrandSpotlightView2.getLayoutParams().height = 4 * height + (int) Convert.DpToPixel(4 * 105, ctx);

        mShopsNearbyView = v.findViewById(R.id.shops_nearby_view);

        RelativeLayout shopsNearbyLayout = v.findViewById(R.id.shops_nearby_map_overlay);
        shopsNearbyLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (mCurrentLocation == null) {
                    if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                        requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1001);
                        return;
                    }
                    startLocation();
                } else {
                    Intent shopsNearbyIntent = new Intent(getContext(), ShopsNearbyActivity.class);
                    shopsNearbyIntent.putExtra("lat", mCurrentLocation.getLatitude());
                    shopsNearbyIntent.putExtra("lng", mCurrentLocation.getLongitude());
                    startActivity(shopsNearbyIntent);
                }
            }
        });

        TextView mapOverlayText = v.findViewById(R.id.shops_nearby_map_overlay_text);
        mapOverlayText.setTypeface(mExtraBoldFont);

        ImageView mMicImageButton = v.findViewById(R.id.voice_search_image);
        mMicImageButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
                i.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, "en-US");
                i.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 15);
                i.putExtra(RecognizerIntent.EXTRA_PROMPT, "Howdy");
                startActivityForResult(i, REQUEST_MICROPHONE_PERMISSION);
            }
        });

        if (isNetworkAvailable()) {
            mNoInternetLayout.setVisibility(View.GONE);
            mSearchCategoriesView1.setVisibility(View.VISIBLE);
            mSearchCategoriesView2.setVisibility(View.VISIBLE);
            mShopsNearbyView.setVisibility(View.VISIBLE);
            mBrandSpotlightView1.setVisibility(View.VISIBLE);
            mBrandSpotlightView2.setVisibility(View.VISIBLE);
        } else {
            mSearchCategoriesView1.setVisibility(View.GONE);
            mSearchCategoriesView2.setVisibility(View.GONE);
            mShopsNearbyView.setVisibility(View.GONE);
            mBrandSpotlightView1.setVisibility(View.GONE);
            mBrandSpotlightView2.setVisibility(View.GONE);
            mLoadingLayout.setVisibility(View.GONE);
            mNoInternetLayout.setVisibility(View.VISIBLE);
            mSwipeRefreshLayout.setRefreshing(false);
        }

        return v;
    }

    @Override
    public void setUserVisibleHint(boolean isVisible) {
        if(isVisible && getContext() != null) {
            String gender = PreferencesHelper.getInstance(getContext().getApplicationContext()).getGender();
            if(!gender.equals(mCurrentGender)) {
                mCurrentGender = gender;
                loadTeasers();
            }
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (mLocationProvider != null) {
            mLocationProvider.onActivityResult(requestCode, resultCode, data);
        }

        if (requestCode == REQUEST_MICROPHONE_PERMISSION && data != null) {
            ArrayList<String> result = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
            mListener.onVoiceSearch(result.get(0));
        }

        if (requestCode == REQUEST_SETTINGS_UPDATE && resultCode == RESULT_GENDER_UPDATED) {
            loadTeasers();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    private void startLocation() {
        mLocationProvider = new LocationGooglePlayServicesProvider();
        mLocationProvider.setCheckLocationSettings(true);

        SmartLocation smartLocation = new SmartLocation.Builder(getActivity()).logging(true).build();

        smartLocation.location(mLocationProvider).start(this);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == 1001 && grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startLocation();
        }
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof OnSearchListener) {
            mListener = (OnSearchListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement OnSearchListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    private void openAutoCompleteFragment() {
        AutoCompleteFragment frag = new AutoCompleteFragment();
        FragmentManager fragmentManager = getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        fragmentTransaction.add(R.id.main_relative_layout, frag);
        fragmentTransaction.addToBackStack(null);
        fragmentTransaction.commit();
    }

    private void loadTeasers() {
        Location lastLocation = SmartLocation.with(getActivity()).location().getLastLocation();
        if (lastLocation != null) {
            loadTeasersWithContextAndLocation(getContext().getApplicationContext(), new LatLng(lastLocation.getLatitude(), lastLocation.getLongitude()));
        } else {
            loadTeasersWithContextAndLocation(getContext().getApplicationContext(), null);
        }
    }

    private void loadTeasersWithContextAndLocation(Context ctx, final LatLng location) {
        mCurrentGender = PreferencesHelper.getInstance(ctx).getGender();
        SearchTeasersService.getTeasers(ctx, mCurrentGender, location, new Response.Listener<SearchTeasers>() {
            @Override
            public void onResponse(SearchTeasers response) {
                mSearchCategoriesView1.setTeaser(response.getCategoriesTeasers().get(0));
                mBrandSpotlightView1.setTeaser(response.getBrandsTeasers().get(0));

                if(response.getCategoriesTeasers().size() > 1) {
                    mSearchCategoriesView2.setTeaser(response.getCategoriesTeasers().get(1));
                } else {
                    mSearchCategoriesView2.setVisibility(View.GONE);
                }

                if(response.getBrandsTeasers().size() > 1) {
                    mBrandSpotlightView2.setTeaser(response.getBrandsTeasers().get(1));
                } else {
                    mBrandSpotlightView2.setVisibility(View.GONE);
                }

                if (mSupportMapFragment == null) {
                    mSupportMapFragment = SupportMapFragment.newInstance();
                }

                mShopsNearbyView.setTeaser(response.getShopsTeaser(), mSupportMapFragment, location);

                getChildFragmentManager().beginTransaction().replace(R.id.map_layout, mSupportMapFragment).commitAllowingStateLoss();

                mLoadingLayout.setVisibility(View.INVISIBLE);
                mSwipeRefreshLayout.setRefreshing(false);
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
            }
        });
    }

    private boolean isNetworkAvailable() {
        ConnectivityManager connectivityManager
                = (ConnectivityManager) getContext().getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    @Override
    public void onLocationUpdated(Location location) {
        mCurrentLocation = location;
        loadTeasersWithContextAndLocation(getActivity().getApplicationContext(), new LatLng(location.getLatitude(), location.getLongitude()));
    }

    static class CompareSizesByArea implements Comparator<Size> {

        @Override
        public int compare(Size lhs, Size rhs) {
            // We cast here to ensure the multiplications won't overflow
            return Long.signum((long) lhs.getWidth() * lhs.getHeight() -
                    (long) rhs.getWidth() * rhs.getHeight());
        }

    }

    /**
     * Shows OK/Cancel confirmation dialog about camera permission.
     */
    public static class ConfirmationDialog extends DialogFragment {

        @NonNull
        @Override
        public Dialog onCreateDialog(Bundle savedInstanceState) {
            final Fragment parent = getParentFragment();
            return new AlertDialog.Builder(getActivity())
                    .setMessage(R.string.request_permission)
                    .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            parent.requestPermissions(new String[]{Manifest.permission.CAMERA},
                                    REQUEST_CAMERA_PERMISSION);
                        }
                    })
                    .setNegativeButton(android.R.string.cancel,
                            new DialogInterface.OnClickListener() {
                                @Override
                                public void onClick(DialogInterface dialog, int which) {
                                    Activity activity = parent.getActivity();
                                    if (activity != null) {
                                        activity.finish();
                                    }
                                }
                            })
                    .create();
        }
    }

}
