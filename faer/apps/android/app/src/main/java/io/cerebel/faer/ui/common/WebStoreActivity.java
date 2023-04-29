package io.cerebel.faer.ui.common;

import android.annotation.SuppressLint;
import android.graphics.Typeface;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import io.cerebel.faer.R;
import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.remote.AppEventLogger;


public class WebStoreActivity extends AppCompatActivity {
    private boolean firstCheckOutApp = true;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_web_store);

        final Product item = (Product)getIntent().getSerializableExtra("item");

        Typeface boldFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_extra_bold));

        Toolbar toolbar = findViewById(R.id.web_store_toolbar);
        setSupportActionBar(toolbar);

        TextView productTextView = findViewById(R.id.web_product_text_view);
        productTextView.setTypeface(boldFont);
        productTextView.setText(item.getName());

        LinearLayout backLayout = findViewById(R.id.back_layout);
        backLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onBackPressed();
            }
        });

        ImageButton backButton = findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onBackPressed();
            }
        });

        WebView webView = findViewById(R.id.product_web_view);
        webView.setWebViewClient(new WebViewClient());
        webView.getSettings().setJavaScriptEnabled(true);

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);

                ProgressBar loadingBar = findViewById(R.id.web_loading_progress_bar);
                loadingBar.setVisibility(View.GONE);

                url = url.toLowerCase();

                //Checks if user started the checkout in the website
                if (url.contains("checkout") && firstCheckOutApp) {
                    firstCheckOutApp = false;

                    AppEventLogger.getInstance(getApplicationContext()).logBeginCheckout(
                            item.getId(),
                            item.getName(),
                            item.getBrand(),
                            item.getPriceInCurrency("eur"),
                            "eur"
                    );
                }
            }
        });

        webView.loadUrl(item.getURL());
    }

}
