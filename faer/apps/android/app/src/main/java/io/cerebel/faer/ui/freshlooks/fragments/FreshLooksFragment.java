package io.cerebel.faer.ui.freshlooks.fragments;

import android.content.Context;
import android.graphics.Typeface;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import androidx.fragment.app.Fragment;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsListView;
import android.widget.GridView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.android.volley.Response;
import com.android.volley.VolleyError;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.FreshLooksItem;
import io.cerebel.faer.data.service.FreshLooksService;
import io.cerebel.faer.ui.freshlooks.adapters.FreshLooksGridViewAdapter;


public class FreshLooksFragment extends Fragment {

    private FreshLooksGridViewAdapter adapter;
    private boolean isLoadingMore = false;
    private String mCurrentGender;
    private RelativeLayout onBoardingRelativeLayout;
    private LinearLayout loadingLinearLayout;
    private SwipeRefreshLayout mSwipeRefreshLayout;
    private GridView mGridView;
    private int nbLoadedPages = 1;
    private Typeface mExtraBoldFont;
    private Typeface mRegularFont;
    private boolean mUserScrolled;

    public FreshLooksFragment() { }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        mRegularFont = Typeface.createFromAsset(getContext().getApplicationContext().getAssets(), "fonts/Montserrat-Medium.ttf");
        mExtraBoldFont = Typeface.createFromAsset(getContext().getApplicationContext().getAssets(), getString(R.string.font_extra_bold));

        adapter = new FreshLooksGridViewAdapter(getActivity());
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        final View v = inflater.inflate(R.layout.fragment_freshlooks, container, false);
        loadingLinearLayout = v.findViewById(R.id.loading_linear_layout);

        onBoardingRelativeLayout = v.findViewById(R.id.onboarding_relative_layout);
        mSwipeRefreshLayout = v.findViewById(R.id.swiperefresh);

        //Check if this is the user's first session
        onBoard();

        setFont(v);

        mGridView = v.findViewById(R.id.feed_grid);
        mGridView.setAdapter(adapter);
        mGridView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                if(view == mGridView && motionEvent.getAction() == MotionEvent.ACTION_MOVE) {
                    mUserScrolled = true;
                }
                return false;
            }
        });

        mGridView.setOnScrollListener(new AbsListView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(AbsListView absListView, int scrollState) {
            }

            @Override
            public void onScroll(AbsListView absListView, int firstVisibleItem, int visibleItemCount, int totalItemCount) {
                if (!isLoadingMore && mUserScrolled) {
                    if (firstVisibleItem + visibleItemCount > totalItemCount - 5 && totalItemCount != 0) {
                        queueFeedRequest(nbLoadedPages++);
                    }
                }
            }
        });

        final LinearLayout noInternetLayout = v.findViewById(R.id.no_internet_layout);
        mSwipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                if (isNetworkAvailable()) {
                    mGridView.setEnabled(true);
                    noInternetLayout.setVisibility(View.GONE);
                    adapter.clear();
                    nbLoadedPages = 1;
                    queueFeedRequest(nbLoadedPages++);
                } else {
                    Toast.makeText(getContext().getApplicationContext(), "No Internet connection", Toast.LENGTH_LONG).show();
                }

                mSwipeRefreshLayout.setRefreshing(false);
            }
        });

        if (isNetworkAvailable()) {
            if(!isLoadingMore) {
                loadingLinearLayout.setVisibility(View.VISIBLE);
                adapter.clear();
                queueFeedRequest(nbLoadedPages++);
            }
        } else {
            TextView noInternetText1 = v.findViewById(R.id.no_internet_textview1);
            noInternetText1.setTypeface(mExtraBoldFont);

            TextView noInternetText2 = v.findViewById(R.id.no_internet_textview2);
            noInternetText2.setTypeface(mRegularFont);

            mGridView.setEnabled(false);
            noInternetLayout.setVisibility(View.VISIBLE);
            loadingLinearLayout.setVisibility(View.GONE);
        }

        return v;
    }

    @Override
    public void setUserVisibleHint(boolean isVisible) {
        super.setUserVisibleHint(isVisible);
        if(onBoardingRelativeLayout != null && onBoardingRelativeLayout.getVisibility() == View.VISIBLE) {
            onBoardingRelativeLayout.setVisibility(View.GONE);
            PreferencesHelper.getInstance(getContext().getApplicationContext()).setIsFirstSession(false);
        }

        if(isVisible && getContext() != null) {
            String gender = PreferencesHelper.getInstance(getContext().getApplicationContext()).getGender();
            if(!gender.equals(mCurrentGender)) {
               mCurrentGender = gender;
               adapter.clear();
               nbLoadedPages = 1;
               queueFeedRequest(nbLoadedPages++);
            }
        }
    }

    private void onBoard() {
        boolean firstSession = PreferencesHelper.getInstance(getContext().getApplicationContext()).isFirstSession();
        if (firstSession) {
            onBoardingRelativeLayout.setVisibility(View.VISIBLE);
        } else {
            onBoardingRelativeLayout.setVisibility(View.INVISIBLE);
        }
        onBoardingRelativeLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                PreferencesHelper.getInstance(getContext().getApplicationContext()).setIsFirstSession(false);
                onBoardingRelativeLayout.setVisibility(View.INVISIBLE);
                adapter.clear();
                nbLoadedPages = 1;
                queueFeedRequest(nbLoadedPages++);
            }
        });

    }

    private void setFont(View v) {
        TextView onboardingTitleTextView = v.findViewById(R.id.onboarding_title_text_view);
        TextView onboardingDescriptionTextView = v.findViewById(R.id.onboarding_description_text_view);
        TextView swipeInstructionTextView = v.findViewById(R.id.swipe_instruction_text_view);
        onboardingTitleTextView.setTypeface(mExtraBoldFont);
        onboardingDescriptionTextView.setTypeface(mRegularFont);
        swipeInstructionTextView.setTypeface(mExtraBoldFont);
    }

    private void queueFeedRequest(int page) {
        isLoadingMore = true;
        mCurrentGender = PreferencesHelper.getInstance(getContext().getApplicationContext()).getGender();
        String userID = PreferencesHelper.getInstance(getContext().getApplicationContext()).getAppInstanceID();
        FreshLooksService.getFeed(getContext().getApplicationContext(), mCurrentGender, page, userID, new Response.Listener<List<FreshLooksItem>>() {
            @Override
            public void onResponse(List<FreshLooksItem> response) {
                if (response.size() != 0) {
                    loadingLinearLayout.setVisibility(View.INVISIBLE);
                    adapter.addItems(response);
                }
                isLoadingMore = false;
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {

            }
        });
    }

    private boolean isNetworkAvailable() {
        ConnectivityManager connectivityManager
                = (ConnectivityManager) getContext().getApplicationContext().getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }
}