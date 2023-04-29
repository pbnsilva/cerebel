package io.cerebel.faer.ui.product;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import androidx.core.app.ActivityCompat;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.MarkerOptions;

import java.util.ArrayList;
import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.Store;

public class MapActivity extends AppCompatActivity implements OnMapReadyCallback {
    private List<Store> nearStores = new ArrayList<>();
    private double centerLat;
    private double centerLon;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_map);
        SupportMapFragment mapFragment = (SupportMapFragment) getSupportFragmentManager().findFragmentById(R.id.map);
        mapFragment.getMapAsync(this);
        Intent intentThatStartedThisActivity = getIntent();
        nearStores = (List<Store>) intentThatStartedThisActivity.getSerializableExtra(getString(R.string.nearStoresKey));
        centerLat = intentThatStartedThisActivity.getDoubleExtra(getString(R.string.centerLat), 0);
        centerLon = intentThatStartedThisActivity.getDoubleExtra(getString(R.string.centerLon), 0);

    }

    @Override
    public void onMapReady(GoogleMap googleMap) {

        //Checking if user permitted access to location
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            androidx.legacy.app.ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, 0);
            return;
        }
        googleMap.setMyLocationEnabled(true);

        //Center the camera at the center of the stores
        float defaultCameraZoon = 11.5f;
        googleMap.animateCamera(CameraUpdateFactory.newLatLngZoom(new LatLng(centerLat, centerLon), defaultCameraZoon));

        if (nearStores != null) { //should always be true
            for (int storeIndex = 0; storeIndex < nearStores.size(); storeIndex++) {
                Store currentStore = nearStores.get(storeIndex);
                addStoreToMap(currentStore, googleMap);
            }
        }

    }

    /**
     * Adds the store to the map using a marker
     *
     * @param store current store to be added to the map
     * @param map   google map being displayed to user
     */
    private void addStoreToMap(Store store, GoogleMap map) {
        double lat = store.getLat();
        double lon = store.getLon();
        String name = store.getName();
        map.addMarker(new MarkerOptions().position(new LatLng(lat, lon)).title(name));
    }

}


