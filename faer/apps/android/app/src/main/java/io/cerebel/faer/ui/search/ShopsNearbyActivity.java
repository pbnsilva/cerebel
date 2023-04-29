package io.cerebel.faer.ui.search;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import android.util.DisplayMetrics;
import android.view.WindowManager;

import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.MarkerOptions;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.model.SearchTeasers;
import io.cerebel.faer.data.model.ShopNearby;
import io.cerebel.faer.data.model.Teaser;
import io.cerebel.faer.data.service.SearchTeasersService;

public class ShopsNearbyActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shops_nearby);
        Toolbar toolbar = findViewById(R.id.toolbar);
        toolbar.setTitle("Shops Near You");
        setSupportActionBar(toolbar);

        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);

        final SupportMapFragment mapFragment = (SupportMapFragment)getSupportFragmentManager().findFragmentById(R.id.map);

        final DisplayMetrics dm = new DisplayMetrics();
        WindowManager windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        windowManager.getDefaultDisplay().getMetrics(dm);

        Intent intent = getIntent();
        if(intent != null) {
            double lat = intent.getDoubleExtra("lat", -1);
            double lng = intent.getDoubleExtra("lng", -1);
            final LatLng loc = new LatLng(lat, lng);

            SearchTeasersService.getTeasers(this, PreferencesHelper.getInstance(this).getGender(), loc, new Response.Listener<SearchTeasers>() {
                @Override
                public void onResponse(final SearchTeasers response) {
                    mapFragment.getMapAsync(new OnMapReadyCallback() {
                        @SuppressLint("MissingPermission")
                        @Override
                        public void onMapReady(GoogleMap googleMap) {
                            googleMap.setMyLocationEnabled(true);

                            LatLngBounds.Builder builder = new LatLngBounds.Builder();
                            builder.include(loc);

                            Teaser<ShopNearby> shops = response.getShopsTeaser();
                            for(ShopNearby shop: shops.getItems()) {
                                googleMap.addMarker(new MarkerOptions()
                                        .position(shop.getLocation())
                                        .title(shop.getName()));
                                builder.include(shop.getLocation());
                            }

                            LatLngBounds bounds = builder.build();
                            CameraUpdate cu = CameraUpdateFactory.newLatLngBounds(bounds, dm.widthPixels / 3);
                            googleMap.moveCamera(cu);
                        }
                    });
                }
            }, new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                }
            });
        }
    }

}
