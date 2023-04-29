package io.cerebel.faer.ui.search.fragments;

import android.content.Context;
import android.graphics.Typeface;
import android.os.Bundle;
import androidx.fragment.app.Fragment;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;

import com.android.volley.Response;
import com.android.volley.VolleyError;

import java.util.List;

import io.cerebel.faer.R;
import io.cerebel.faer.data.local.PreferencesHelper;
import io.cerebel.faer.data.service.SuggesterService;
import io.cerebel.faer.ui.search.OnSearchListener;
import io.cerebel.faer.ui.search.adapters.AutoCompleteAdapter;

class AutoCompleteFragment extends Fragment {
    private OnSearchListener mListener;

    private EditText mSearchEdit;
    private ListView mSuggestionsListView;

    private Typeface mExtraBoldFont;
    private Typeface mMediumFont;

    private AutoCompleteAdapter mAutoCompleteAdapter;

    public AutoCompleteFragment() {
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mExtraBoldFont = Typeface.createFromAsset(getActivity().getAssets(), getString(R.string.font_extra_bold));
        mMediumFont = Typeface.createFromAsset(getActivity().getAssets(), getString(R.string.font_medium));
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_auto_complete, container, false);

        InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, InputMethodManager.HIDE_IMPLICIT_ONLY);

        mAutoCompleteAdapter = new AutoCompleteAdapter(getContext());
        mSuggestionsListView = view.findViewById(R.id.suggestions_listview);
        mSuggestionsListView.setAdapter(mAutoCompleteAdapter);
        mSuggestionsListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
                onSearch(mSuggestionsListView.getItemAtPosition(i).toString());
            }
        });
        fillSuggestions("");

        mSearchEdit = view.findViewById(R.id.search_edittext);
        mSearchEdit.setTypeface(mExtraBoldFont);
        mSearchEdit.requestFocus();
        mSearchEdit.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView textView, int actionID, KeyEvent keyEvent) {
                if(actionID == EditorInfo.IME_ACTION_SEARCH) {
                    InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                    imm.hideSoftInputFromWindow(textView.getWindowToken(), 0);
                    onSearch(mSearchEdit.getText().toString());
                    return true;
                }
                return false;
            }
        });
        mSearchEdit.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

            }

            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                if (mSearchEdit.getText().length() == 0 || mSearchEdit.getText().length() > 1) {
                    fillSuggestions(mSearchEdit.getText().toString());
                }
            }

            @Override
            public void afterTextChanged(Editable editable) {

            }
        });

        TextView mCancelText = view.findViewById(R.id.cancel_textview);
        mCancelText.setTypeface(mMediumFont);
        mCancelText.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
                getActivity().getSupportFragmentManager().popBackStack();
            }
        });

        return view;
    }

    private void fillSuggestions(String query) {
        String gender = PreferencesHelper.getInstance(getActivity().getApplicationContext()).getGender();
        SuggesterService.getSuggestions(getContext(), query, gender, 10, new Response.Listener<List<String>>() {
            @Override
            public void onResponse(List<String> response) {
                mAutoCompleteAdapter.setData(response);
                mAutoCompleteAdapter.notifyDataSetChanged();
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {

            }
        });
    }

    private void onSearch(String query) {
        if (mListener != null) {
            mListener.onTextSearch(query);
        }
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof OnSearchListener) {
            mListener = (OnSearchListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement OnSearchListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }
}
