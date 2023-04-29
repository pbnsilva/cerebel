package io.cerebel.faer.util;

import android.content.Context;
import android.util.DisplayMetrics;

public class Convert {
    public static float DpToPixel(float dp, Context context){
        return dp * ((float) context.getResources().getDisplayMetrics().densityDpi / DisplayMetrics.DENSITY_DEFAULT);
    }
}
