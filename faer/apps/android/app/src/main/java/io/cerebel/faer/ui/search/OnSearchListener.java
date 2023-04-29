package io.cerebel.faer.ui.search;

public interface OnSearchListener {
       void onTextSearch(String query);
       void onImageSearch();
       void onVoiceSearch(String query);
}
