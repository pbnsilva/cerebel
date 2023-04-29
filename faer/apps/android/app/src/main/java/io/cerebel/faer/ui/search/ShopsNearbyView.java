package io.cerebel.faer.ui.search;

import android.content.Context;
import android.graphics.Typeface;
import androidx.constraintlayout.widget.ConstraintLayout;
import android.util.AttributeSet;
import android.widget.TextView;

import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.ShopNearby;
import io.cerebel.faer.data.model.Teaser;

public class ShopsNearbyView extends ConstraintLayout {
    private TextView mTitleText;

    public ShopsNearbyView(Context context) {
        super(context);
        init();
    }

    public ShopsNearbyView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init(){
        inflate(getContext(), R.layout.view_shops_nearby, this);

        Typeface mMediumFont = Typeface.createFromAsset(getContext().getAssets(), getContext().getString(R.string.font_medium));
        mTitleText = findViewById(R.id.shops_nearby_title);
        mTitleText.setTypeface(mMediumFont);
    }

    public void setTeaser(final Teaser<ShopNearby> teaser, SupportMapFragment mapFragment, final LatLng location) {
        mTitleText.setText(teaser.getTitle());

        mapFragment.getMapAsync(new OnMapReadyCallback() {
            @Override
            public void onMapReady(GoogleMap googleMap) {
                TextView text = findViewById(R.id.shops_nearby_map_overlay_text);
                if(location == null) {
                    googleMap.getUiSettings().setAllGesturesEnabled(false);
                    text.setText("Tap to find shops near you");
                } else {
                    CameraUpdate center =
                            CameraUpdateFactory.newLatLng(location);
                    CameraUpdate zoom = CameraUpdateFactory.zoomTo(10);
                    googleMap.moveCamera(center);
                    googleMap.animateCamera(zoom);

                    List<ShopNearby> items = teaser.getItems();
                    if(items.size() == 0) {
                        text.setText("There are no shops near you");
                    } else  if(items.size() > 1) {
                        googleMap.getUiSettings().setAllGesturesEnabled(true);
                        text.setText(String.format("Discover %d shops near you", items.size()));
                    } else {
                        googleMap.getUiSettings().setAllGesturesEnabled(true);
                        text.setText(String.format("Discover %d shop near you", items.size()));
                    }
                }
            }
        });
    }
}
