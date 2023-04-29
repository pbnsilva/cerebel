package io.cerebel.faer.ui.survey.fragments;

import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.os.Bundle;
import androidx.fragment.app.DialogFragment;
import androidx.appcompat.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.Toast;

import io.cerebel.faer.R;
import io.cerebel.faer.data.remote.AppEventLogger;


class NPSFragment extends DialogFragment {
    private int page = 1;
    private AlertDialog dialog;
    private EditText commentsText;
    private EditText emailText;

    private static boolean isValidEmail(CharSequence target) {
        return target == null || !android.util.Patterns.EMAIL_ADDRESS.matcher(target).matches();
    }

    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        AppEventLogger.getInstance(getActivity().getApplicationContext()).logSurveyBegan();

        LayoutInflater inflater = getActivity().getLayoutInflater();
        View surveyView = inflater.inflate(R.layout.fragment_nps_survey, null);
        final LinearLayout screen1 = surveyView.findViewById(R.id.nps_screen_1);
        final LinearLayout screen2 = surveyView.findViewById(R.id.nps_screen_2);
        final LinearLayout screen3 = surveyView.findViewById(R.id.nps_screen_3);
        final LinearLayout screen4 = surveyView.findViewById(R.id.nps_screen_4);

        dialog = new AlertDialog.Builder(getActivity())
                .setView(surveyView)
                .setPositiveButton("Start survey", null)
                .setNegativeButton("Skip", null)
                .create();

        commentsText = surveyView.findViewById(R.id.comments_text);
        emailText = surveyView.findViewById(R.id.email_text);

        final Spinner spinner = surveyView.findViewById(R.id.nps_spinner);
        ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(surveyView.getContext(),
                R.array.nps_options, R.layout.view_nps_spinner_item);
        adapter.setDropDownViewResource(R.layout.view_nps_spinner_item);
        spinner.setAdapter(adapter);
        spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int i, long l) {
                Button okButton = dialog.getButton(DialogInterface.BUTTON_POSITIVE);

                if (i == 0) {
                    okButton.setEnabled(false);
                } else {
                    okButton.setEnabled(true);
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {

            }
        });

        dialog.setOnShowListener(new DialogInterface.OnShowListener() {
            @Override
            public void onShow(DialogInterface dialogInterface) {
                final Button okButton = dialog.getButton(DialogInterface.BUTTON_POSITIVE);
                final Button cancelButton = dialog.getButton(DialogInterface.BUTTON_NEGATIVE);

                okButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        if (page == 1) {
                            screen1.setVisibility(View.GONE);
                            screen2.setVisibility(View.VISIBLE);
                            cancelButton.setText("Cancel survey");
                            okButton.setText("Continue");
                            okButton.setEnabled(false);
                        } else if (page == 2) {
                            screen2.setVisibility(View.GONE);
                            screen3.setVisibility(View.VISIBLE);
                            okButton.setText("Continue to last page");
                            commentsText.requestFocus();
                        } else if (page == 3) {
                            screen3.setVisibility(View.GONE);
                            screen4.setVisibility(View.VISIBLE);
                            okButton.setVisibility(View.GONE);
                            cancelButton.setText("Close");
                            emailText.requestFocus();
                        }
                        page += 1;
                    }
                });

                cancelButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        if (page == 4) {
                            String email = emailText.getText().toString();
                            if (email.trim().length() != 0) {
                                if (isValidEmail(email)) {
                                    Toast.makeText(getActivity().getApplicationContext(), "That doesn't look like an email address!", Toast.LENGTH_SHORT).show();
                                } else {
                                    NPSFragment.this.getDialog().cancel();
                                    return;
                                }
                            }

                            int score = spinner.getSelectedItemPosition() - 1;
                            String comments = commentsText.getText().toString();
                            AppEventLogger.getInstance(getActivity().getApplicationContext()).logSurveyCompleted(
                                    score,
                                    email,
                                    comments
                            );
                        }
                        AppEventLogger.getInstance(getActivity().getApplicationContext()).logSurveyCancelled();
                        NPSFragment.this.getDialog().cancel();
                    }
                });
            }
        });

        return dialog;
    }

    @Override
    public void onActivityCreated(Bundle b) {
        super.onActivityCreated(b);

        commentsText.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View view, boolean b) {
                if (b) {
                    getDialog().getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
                    InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                    imm.showSoftInput(commentsText, InputMethodManager.SHOW_IMPLICIT);
                }
            }
        });

        emailText.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View view, boolean b) {
                if (b) {
                    getDialog().getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
                    InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                    imm.showSoftInput(emailText, InputMethodManager.SHOW_IMPLICIT);
                }
            }
        });
    }
}
