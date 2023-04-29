package io.cerebel.faer.ui.settings;

import android.content.Intent;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.ImageButton;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Switch;
import android.widget.TextView;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;

public class SettingsActivity extends AppCompatActivity {
    public static final int REQUEST_SETTINGS_UPDATE = 111;
    public static final int RESULT_GENDER_UPDATED = 333;

    private RadioButton shopMenRadioButton;
    private RadioButton shopWomenRadioButton;
    private RadioButton eurRadioButton;
    private RadioButton usdRadioButton;
    private RadioButton gbpRadioButton;
    private RadioButton dkkRadioButton;

    private TextView settingsTitleTextView;
    private TextView genderTitleTextView;
    private TextView currencyTitleTextView;
    private TextView currencyExplanationTextView;
    private TextView aboutTitleTextView;
    private TextView visitFaerTextView;
    private TextView feedbackTextView;
    private TextView notificationsTitleTextView;
    private Switch notificationsSwitch;

    private boolean mIsGenderUpdated = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        ImageButton finishButton = findViewById(R.id.finish_button);
        finishButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if(mIsGenderUpdated) {
                    setResult(RESULT_GENDER_UPDATED);
                }
                finish();
            }
        });


        loadGenderRadioGroup();
        loadCurrencyRadioGroup();

        settingsTitleTextView = findViewById(R.id.settings_title_text_view);
        genderTitleTextView = findViewById(R.id.gender_title_text_view);
        currencyTitleTextView = findViewById(R.id.currency_title_text_view);
        currencyExplanationTextView = findViewById(R.id.currency_explanation_text_view);
        aboutTitleTextView = findViewById(R.id.about_title_text_view);
        visitFaerTextView = findViewById(R.id.visit_faer_text_view);
        feedbackTextView = findViewById(R.id.feedback_text_view);
        notificationsTitleTextView = findViewById(R.id.notifications_title_textview);
        notificationsSwitch = findViewById(R.id.notifications_switch);

        settingUpTextFont();

        feedbackTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent emailIntent = new Intent(Intent.ACTION_SENDTO, Uri.fromParts(
                        "mailto", getString(R.string.faer_email), null));
                String[] addresses = {getString(R.string.faer_email)};
                emailIntent.putExtra(Intent.EXTRA_EMAIL, addresses); // String[] addresses
                startActivity(Intent.createChooser(emailIntent, "Send email..."));
            }
        });

        RadioGroup genderRadioGroup = findViewById(R.id.gender_radio_group);
        genderRadioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup radioGroup, int id) {
                RadioButton btn = radioGroup.findViewById(id);
                if (btn.isChecked()) {
                    PreferencesHelper.getInstance(getApplicationContext()).setGender(btn.getTag().toString());
                    mIsGenderUpdated = true;
                }
            }
        });

        RadioGroup currencyRadioGroup = findViewById(R.id.currency_radio_group);
        currencyRadioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup radioGroup, int id) {
                RadioButton btn = radioGroup.findViewById(id);
                if (btn.isChecked()) {
                    PreferencesHelper.getInstance(getApplicationContext()).setCurrency(btn.getTag().toString());
                }
            }
        });

        final Switch notificationsSwitch = findViewById(R.id.notifications_switch);
        notificationsSwitch.setChecked(PreferencesHelper.getInstance(getApplicationContext()).isPushNotificationsEnabled());
        notificationsSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, final boolean checked) {
                PreferencesHelper.getInstance(getApplicationContext()).setIsPushNotificationsEnabled(checked);
            }
        });
    }

    private void settingUpTextFont() {
        Typeface boldFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_extra_bold));
        Typeface regularFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_medium));
        settingsTitleTextView.setTypeface(boldFont);
        genderTitleTextView.setTypeface(regularFont);
        currencyTitleTextView.setTypeface(regularFont);
        currencyExplanationTextView.setTypeface(regularFont);
        aboutTitleTextView.setTypeface(boldFont);
        visitFaerTextView.setTypeface(regularFont);
        feedbackTextView.setTypeface(boldFont);

        shopMenRadioButton.setTypeface(regularFont);
        shopWomenRadioButton.setTypeface(regularFont);
        eurRadioButton.setTypeface(regularFont);
        usdRadioButton.setTypeface(regularFont);
        gbpRadioButton.setTypeface(regularFont);
        dkkRadioButton.setTypeface(regularFont);

        notificationsTitleTextView.setTypeface(regularFont);
        notificationsSwitch.setTypeface(regularFont);
    }


    /**
     * Loads from the preferences which value is the current value for the gender.
     * E.g. gender is men, set men button to checked.
     */
    private void loadGenderRadioGroup() {
        shopMenRadioButton = findViewById(R.id.shop_men_radio_button);
        shopWomenRadioButton = findViewById(R.id.shop_women_radio_button);

        String gender = PreferencesHelper.getInstance(getApplicationContext()).getGender();
        if (gender.equals(getString(R.string.shoppingWomen))) {
            shopWomenRadioButton.setChecked(true);
        } else {
            shopMenRadioButton.setChecked(true);
        }
    }

    /**
     * Loads from the preferences which value is the current value for the currency.
     * E.g. currency is eur, set eur button to checked.
     */
    private void loadCurrencyRadioGroup() {
        eurRadioButton = findViewById(R.id.eur_radio_button);
        usdRadioButton = findViewById(R.id.usd_radio_button);
        gbpRadioButton = findViewById(R.id.gbp_radio_button);
        dkkRadioButton = findViewById(R.id.dkk_radio_button);

        String currency = PreferencesHelper.getInstance(getApplicationContext()).getCurrency();
        if (currency.equals(getString(R.string.shoppingInEur))) {
            eurRadioButton.setChecked(true);
        } else if (currency.equals(getString(R.string.shoppingInUsd))) {
            usdRadioButton.setChecked(true);
        } else if (currency.equals(getString(R.string.shoppingInGbp))) {
            gbpRadioButton.setChecked(true);
        } else if (currency.equals(getString(R.string.shoppingInDkk))) {
            dkkRadioButton.setChecked(true);
        }
    }

}
