package io.cerebel.faer.ui.wishlist.fragments;

import android.graphics.Typeface;
import android.os.Bundle;
import androidx.fragment.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.GridView;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.concurrent.TimeUnit;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.DatabaseHelper;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.model.WishlistProduct;
import io.cerebel.faer.ui.wishlist.adapters.WishlistGridViewAdapter;

public class WishlistFragment extends Fragment {
    private Typeface boldFont, regularFont;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        boldFont = Typeface.createFromAsset(getContext().getApplicationContext().getAssets(), getString(R.string.font_extra_bold));
        regularFont = Typeface.createFromAsset(getContext().getApplicationContext().getAssets(), "fonts/Montserrat-Medium.ttf");
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View v = inflater.inflate(R.layout.fragment_wishlist, container, false);
        List<WishlistProduct> items = DatabaseHelper.getInstance(getContext().getApplicationContext()).getAllItems();
        if (items.size() > 0) {
            LinearLayout wishlist_linear_layout = v.findViewById(R.id.wishlist_linear_layout);
            wishlist_linear_layout.setVisibility(View.INVISIBLE);
        } else {
            if (!PreferencesHelper.getInstance(getContext().getApplicationContext()).isPushNotificationsEnabled()) {
                final TextView notificationsTextView = v.findViewById(R.id.turn_on_sale_notifications_text_view);
                notificationsTextView.setVisibility(View.VISIBLE);
                notificationsTextView.setTypeface(boldFont);
                notificationsTextView.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        PreferencesHelper.getInstance(getContext().getApplicationContext()).setIsPushNotificationsEnabled(true);
                        notificationsTextView.setVisibility(View.GONE);
                    }
                });
            }
        }

        TextView titleTextView = v.findViewById(R.id.wishlist_title_text_view);
        TextView descTextView = v.findViewById(R.id.wishlist_description_text_view);
        titleTextView.setTypeface(boldFont);
        descTextView.setTypeface(regularFont);

        List<Integer> dateCounts = getFavoritedCount(items);
        int today = dateCounts.get(0);
        int thisWeek = dateCounts.get(1);
        int lastWeek = dateCounts.get(2);
        int someTimeAgo = dateCounts.get(3);
        WishlistGridViewAdapter mAdapter = new WishlistGridViewAdapter(getActivity(), items, today, thisWeek, lastWeek, someTimeAgo);
        GridView gridView = v.findViewById(R.id.feed_grid);
        gridView.setAdapter(mAdapter);
        return v;
    }

    /**
     * Used to find the number of rows in the grid view needed for each subsection of favorited fragment
     *
     * @param items list of favorited items
     * @return integer list with the number of items for today, this week, last week,
     * and some time ago respectively.
     */
    private List<Integer> getFavoritedCount(List<WishlistProduct> items) {

        List<Integer> results = new ArrayList<>(); // {today, thisWeek, lastWeek, sometimeAgo}

        int today = 0;
        int thisWeek = 0;
        int lastWeek = 0;
        Date dateToday = new Date();

        for (int itemIndex = 0; itemIndex < items.size(); itemIndex++) {

            WishlistProduct wishlistProduct = items.get(itemIndex);
            Product item = wishlistProduct.getProduct();
            Date itemDate = wishlistProduct.getCreationDate();
            long diffInMillies = Math.abs(dateToday.getTime() - itemDate.getTime());
            //difference in days between today and the day the product was liked
            long diff = TimeUnit.DAYS.convert(diffInMillies, TimeUnit.MILLISECONDS);
            if (diff == 0) {
                today += 1;
            } else if (diff < 7) {
                thisWeek += 1;
            } else if (diff < 14) {
                lastWeek += 1;
            } else {
                int someTimeAgo = items.size() - today - thisWeek - lastWeek;
                results.add(today);
                results.add(thisWeek);
                results.add(lastWeek);
                results.add(someTimeAgo);
                return results;
            }

        }
        int someTimeAgo = items.size() - today - thisWeek - lastWeek;
        results.add(today);
        results.add(thisWeek);
        results.add(lastWeek);
        results.add(someTimeAgo);
        return results;
    }


}


