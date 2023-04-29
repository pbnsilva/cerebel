package io.cerebel.faer.ui.common;

import android.content.Context;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.TextView;

import io.cerebel.faer.R;

public class EmailActivity extends AppCompatActivity {
    public static final int RESULT_EMAIL_ACTIVITY = 123;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_email);

        Typeface mExtraBoldFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_extra_bold));
        Typeface mMediumFont = Typeface.createFromAsset(this.getAssets(), getString(R.string.font_medium));

        TextView titleText = findViewById(R.id.stay_in_the_loop_text);
        titleText.setTypeface(mExtraBoldFont);

        TextView emailText = findViewById(R.id.enter_email_text);
        emailText.setTypeface(mExtraBoldFont);

        final TextView submitButton = findViewById(R.id.submit_button);
        submitButton.setTypeface(mExtraBoldFont);

        final EditText emailEdit = findViewById((R.id.email_edit_text));
        emailEdit.setTypeface(mMediumFont);
        emailEdit.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView textView, int actionId, KeyEvent keyEvent) {
                if (actionId == EditorInfo.IME_ACTION_DONE) {
                    String text = emailEdit.getText().toString();
                    TextView emailError = findViewById(R.id.email_error_text);
                    if(isValidEmail(text)) {
                        emailError.setVisibility(View.VISIBLE);
                        submitButton.setText("Skip");
                    } else {
                        emailError.setVisibility(View.GONE);
                        submitButton.setText("Subscribe to newsletter");
                        InputMethodManager imm = (InputMethodManager) emailEdit.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
                        imm.hideSoftInputFromWindow(emailEdit.getWindowToken(), 0);
                    }
                    return true;
                }
                return false;
            }
        });

        submitButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                CharSequence text = submitButton.getText();
                if(text.equals("Subscribe")) {
                    Intent data = new Intent();
                    data.putExtra("email", emailEdit.getText().toString());
                    setResult(RESULT_EMAIL_ACTIVITY, data);
                }
                finish();
            }
        });

        TextView descText = findViewById(R.id.description_text);
        descText.setTypeface(mMediumFont);

        TextView emailError = findViewById(R.id.email_error_text);
        emailError.setTypeface(mMediumFont);

        emailEdit.requestFocus();
    }

    private static boolean isValidEmail(CharSequence target) {
        if (target == null)
            return true;

        return !android.util.Patterns.EMAIL_ADDRESS.matcher(target).matches();
    }
}
