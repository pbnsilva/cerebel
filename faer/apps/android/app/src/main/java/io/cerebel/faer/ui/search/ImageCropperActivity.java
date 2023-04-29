package io.cerebel.faer.ui.search;

import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;

import com.theartofdev.edmodo.cropper.CropImageView;

import io.cerebel.faer.R;
import io.cerebel.faer.data.remote.AppEventLogger;

public class ImageCropperActivity extends AppCompatActivity {

    public static Bitmap bitmap;
    private CropImageView mCropImageView;

    private static final int IMAGE_REQUEST = 1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_image_cropper);

        mCropImageView = findViewById(R.id.crop_image_view);
        mCropImageView.setScaleType(CropImageView.ScaleType.CENTER_CROP);

        double height = 512.0;

        int nh = (int) (bitmap.getHeight() * (height / bitmap.getWidth()));
        Bitmap scaled = Bitmap.createScaledBitmap(bitmap, (int) height, nh, true);

        mCropImageView.setImageBitmap(scaled);

        Button cancelButton = findViewById(R.id.cancel_button);
        cancelButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        Button doneButton = findViewById(R.id.done_button);
        doneButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                AppEventLogger.getInstance(getApplicationContext()).logSearch("<ImageSearch>", "image");

                QueryResultActivity.mBitmap = mCropImageView.getCroppedImage();
                Intent queryIntent = new Intent(ImageCropperActivity.this, QueryResultActivity.class);
                startActivityForResult(queryIntent, IMAGE_REQUEST);
            }
        });

    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        switch (requestCode) {
            case IMAGE_REQUEST: {
                finish();
            }
        }
    }


}
