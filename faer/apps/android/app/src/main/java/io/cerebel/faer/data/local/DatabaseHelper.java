package io.cerebel.faer.data.local;


import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.PatternSyntaxException;

import io.cerebel.faer.data.model.Product;
import io.cerebel.faer.data.model.Store;
import io.cerebel.faer.data.model.WishlistProduct;

public class DatabaseHelper extends SQLiteOpenHelper {
    private static DatabaseHelper mInstance = null;

    private static final String DATABASE_NAME = "Faer3645.db";

    private static final String ITEM_TABLE_NAME = "item_table";
    private static final String ITEM_TABLE_COL_1 = "ID";
    private static final String ITEM_TABLE_COL_2 = "NAME";
    private static final String ITEM_TABLE_COL_3 = "DESCRIPTION";
    private static final String ITEM_TABLE_COL_4 = "URL";
    private static final String ITEM_TABLE_COL_5 = "BRAND";
    private static final String ITEM_TABLE_COL_6 = "DATE";
    private static final String ITEM_TABLE_COL_7 = "PRICE_USD";
    private static final String ITEM_TABLE_COL_8 = "PRICE_EUR";
    private static final String ITEM_TABLE_COL_9 = "PRICE_DKK";
    private static final String ITEM_TABLE_COL_10 = "PRICE_GBP";
    private static final String ITEM_TABLE_COL_11 = "ORIGINAL_PRICE_USD";
    private static final String ITEM_TABLE_COL_12 = "ORIGINAL_PRICE_EUR";
    private static final String ITEM_TABLE_COL_13 = "ORIGINAL_PRICE_DKK";
    private static final String ITEM_TABLE_COL_14 = "ORIGINAL_PRICE_GBP";
    private static final String ITEM_TABLE_COL_15 = "SHARE_URL";
    private static final String ITEM_TABLE_COL_16 = "BRAND_ID";

    private static final String IMAGE_TABLE_NAME = "image_table";
    private static final String IMAGE_TABLE_COL_1 = "ID";
    private static final String IMAGE_TABLE_COL_2 = "ITEM_ID";
    private static final String IMAGE_TABLE_COL_3 = "URL";

    private static final String CATEGORY_TABLE_NAME = "category_table";
    private static final String CATEGORY_TABLE_COL_1 = "ID";
    private static final String CATEGORY_TABLE_COL_2 = "ITEM_ID";
    private static final String CATEGORY_TABLE_COL_3 = "CATEGORY";

    private static final String STORE_TABLE_NAME = "store_table";
    private static final String STORE_TABLE_COL_1 = "ID";
    private static final String STORE_TABLE_COL_2 = "ITEM_ID";
    private static final String STORE_TABLE_COL_3 = "COUNTRY";
    private static final String STORE_TABLE_COL_4 = "ADDRESS";
    private static final String STORE_TABLE_COL_5 = "CITY";
    private static final String STORE_TABLE_COL_6 = "NAME";
    private static final String STORE_TABLE_COL_7 = "LON";
    private static final String STORE_TABLE_COL_8 = "LAT";
    private static final String STORE_TABLE_COL_9 = "POSTAL_CODE";

    private static final String CREATE_ITEM_TABLE =

            "create table " + ITEM_TABLE_NAME +
                    " (" + ITEM_TABLE_COL_1 + " TEXT PRIMARY KEY," +
                    " " + ITEM_TABLE_COL_2 + " TEXT," +
                    " " + ITEM_TABLE_COL_3 + " TEXT," +
                    " " + ITEM_TABLE_COL_4 + " TEXT," +
                    " " + ITEM_TABLE_COL_5 + " TEXT," +
                    " " + ITEM_TABLE_COL_6 + " DATE," +
                    " " + ITEM_TABLE_COL_7 + " FLOAT," +
                    " " + ITEM_TABLE_COL_8 + " FLOAT," +
                    " " + ITEM_TABLE_COL_9 + " FLOAT," +
                    " " + ITEM_TABLE_COL_10 + " FLOAT," +
                    " " + ITEM_TABLE_COL_11 + " FLOAT," +
                    " " + ITEM_TABLE_COL_12 + " FLOAT," +
                    " " + ITEM_TABLE_COL_13 + " FLOAT," +
                    " " + ITEM_TABLE_COL_14 + " FLOAT," +
                    " " + ITEM_TABLE_COL_15 + " TEXT," +
                    " " + ITEM_TABLE_COL_16 + " TEXT ) ";

    private static final String CREATE_IMAGE_TABLE =
            "create table " + IMAGE_TABLE_NAME +
                    " (" + IMAGE_TABLE_COL_1 + " INTEGER PRIMARY KEY AUTOINCREMENT," +
                    " " + IMAGE_TABLE_COL_2 + " TEXT," +
                    " " + IMAGE_TABLE_COL_3 + " TEXT ) ";

    private static final String CREATE_CATEGORY_TABLE =
            "create table " + CATEGORY_TABLE_NAME +
                    " (" + CATEGORY_TABLE_COL_1 + " INTEGER PRIMARY KEY AUTOINCREMENT," +
                    " " + CATEGORY_TABLE_COL_2 + " TEXT," +
                    " " + CATEGORY_TABLE_COL_3 + " TEXT ) ";

    private static final String CREATE_STORE_TABLE =
            "create table " + STORE_TABLE_NAME +
                    " (" + STORE_TABLE_COL_1 + " INTEGER PRIMARY KEY AUTOINCREMENT," +
                    " " + STORE_TABLE_COL_2 + " TEXT," +
                    " " + STORE_TABLE_COL_3 + " TEXT," +
                    " " + STORE_TABLE_COL_4 + " TEXT," +
                    " " + STORE_TABLE_COL_5 + " TEXT," +
                    " " + STORE_TABLE_COL_6 + " TEXT," +
                    " " + STORE_TABLE_COL_7 + " FLOAT," +
                    " " + STORE_TABLE_COL_8 + " FLOAT," +
                    " " + STORE_TABLE_COL_9 + " TEXT ) ";

    public static DatabaseHelper getInstance(Context ctx) {
        if(mInstance == null) {
            mInstance = new DatabaseHelper(ctx.getApplicationContext());
        }
        return mInstance;
    }

    private DatabaseHelper(Context context) {
        super(context, DATABASE_NAME, null, 4);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL(CREATE_ITEM_TABLE);
        db.execSQL(CREATE_IMAGE_TABLE);
        db.execSQL(CREATE_CATEGORY_TABLE);
        db.execSQL(CREATE_STORE_TABLE);

    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        if(newVersion > oldVersion && newVersion == 3) {
            db.execSQL("ALTER TABLE " + ITEM_TABLE_NAME + " ADD COLUMN " + ITEM_TABLE_COL_15 + " TEXT");
        } else  if(newVersion > oldVersion && oldVersion == 3 && newVersion == 4) {
                db.execSQL("ALTER TABLE " + ITEM_TABLE_NAME + " ADD COLUMN " + ITEM_TABLE_COL_16 + " TEXT");
        } else {
            db.execSQL("DROP TABLE IF EXISTS " + ITEM_TABLE_NAME);
            db.execSQL("DROP TABLE IF EXISTS " + STORE_TABLE_NAME);
            db.execSQL("DROP TABLE IF EXISTS " + IMAGE_TABLE_NAME);
            db.execSQL("DROP TABLE IF EXISTS " + CATEGORY_TABLE_NAME);
            onCreate(db);
        }
    }

    public void addToFavorites(WishlistProduct wishlistProduct) {
        Product item = wishlistProduct.getProduct();
        String id = item.getId();
        String name = item.getName();
        String description = item.getDescription();
        String url = item.getURL();
        String shareURL = item.getShareURL();
        String brand = item.getBrand();
        String brandID = item.getBrandID();
        Double priceUsd = item.getPriceInCurrency("usd");
        Double priceEur = item.getPriceInCurrency("eur");
        Double priceDkk = item.getPriceInCurrency("dkk");
        Double priceGbp = item.getPriceInCurrency("gbp");

        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues contentItemValues = new ContentValues();
        contentItemValues.put(ITEM_TABLE_COL_1, id);
        contentItemValues.put(ITEM_TABLE_COL_2, name);
        contentItemValues.put(ITEM_TABLE_COL_3, description);
        contentItemValues.put(ITEM_TABLE_COL_4, url);
        contentItemValues.put(ITEM_TABLE_COL_5, brand);
        contentItemValues.put(ITEM_TABLE_COL_6, wishlistProduct.getCreationDate().toString());
        contentItemValues.put(ITEM_TABLE_COL_7, priceUsd);
        contentItemValues.put(ITEM_TABLE_COL_8, priceEur);
        contentItemValues.put(ITEM_TABLE_COL_9, priceDkk);
        contentItemValues.put(ITEM_TABLE_COL_10, priceGbp);
        contentItemValues.put(ITEM_TABLE_COL_15, shareURL);
        contentItemValues.put(ITEM_TABLE_COL_16, brandID);


        if(item.getOriginalPrice() != null) {
            Double originalPriceUsd = item.getOriginalPriceInCurrency("usd");
            Double originalPriceEur = item.getOriginalPriceInCurrency("eur");
            Double originalPriceDkk = item.getOriginalPriceInCurrency("dkk");
            Double originalPriceGbp = item.getOriginalPriceInCurrency("gbp");

            contentItemValues.put(ITEM_TABLE_COL_11, originalPriceUsd);
            contentItemValues.put(ITEM_TABLE_COL_12, originalPriceEur);
            contentItemValues.put(ITEM_TABLE_COL_13, originalPriceDkk);
            contentItemValues.put(ITEM_TABLE_COL_14, originalPriceGbp);
        }

        long resultItem = db.insert(ITEM_TABLE_NAME, null, contentItemValues);
        if (resultItem < 0) {
            return;
        }

        List<Store> stores = item.getStores();
        List<String> imageURLs = item.getImageURLs();
        List<String> categories = item.getCategories();

        if (stores != null) {
            for (int storeIndex = 0; storeIndex < stores.size(); storeIndex++) {
                Store currentStore = stores.get(storeIndex);

                String country = currentStore.getCountry();
                String address = currentStore.getAddress();
                String city = currentStore.getCity();
                String store_name = currentStore.getName();
                Double lon = currentStore.getLon();
                Double lat = currentStore.getLat();
                String postal_code = currentStore.getPostal_code();

                ContentValues contentStoreValues = new ContentValues();
                contentStoreValues.put(STORE_TABLE_COL_2, id);
                contentStoreValues.put(STORE_TABLE_COL_3, country);
                contentStoreValues.put(STORE_TABLE_COL_4, address);
                contentStoreValues.put(STORE_TABLE_COL_5, city);
                contentStoreValues.put(STORE_TABLE_COL_6, store_name);
                contentStoreValues.put(STORE_TABLE_COL_7, lon);
                contentStoreValues.put(STORE_TABLE_COL_8, lat);
                contentStoreValues.put(STORE_TABLE_COL_9, postal_code);
                long resultStore = db.insert(STORE_TABLE_NAME, null, contentStoreValues);
                if (resultStore < 0) {
                    return;
                }

            }
        }

        if (imageURLs != null) {
            for (int imageIndex = 0; imageIndex < imageURLs.size(); imageIndex++) {
                String currentImageUrl = imageURLs.get(imageIndex);
                ContentValues contentImageValues = new ContentValues();
                contentImageValues.put(IMAGE_TABLE_COL_2, id);
                contentImageValues.put(IMAGE_TABLE_COL_3, currentImageUrl);
                long resultImage = db.insert(IMAGE_TABLE_NAME, null, contentImageValues);
                if (resultImage < 0) {
                    return;
                }
            }
        }

        if (categories != null) {
            for (int categoryIndex = 0; categoryIndex < categories.size(); categoryIndex++) {
                String currentCategory = categories.get(categoryIndex);
                ContentValues contentCategoryValues = new ContentValues();
                contentCategoryValues.put(CATEGORY_TABLE_COL_2, id);
                contentCategoryValues.put(CATEGORY_TABLE_COL_3, currentCategory);
                long resultImage = db.insert(CATEGORY_TABLE_NAME, null, contentCategoryValues);
                if (resultImage < 0) {
                    return;
                }
            }
        }

        db.close();
    }

    public void updateFavorite(WishlistProduct wishlistProduct) {
        Product item = wishlistProduct.getProduct();
        String id = item.getId();
        String name = item.getName();
        String description = item.getDescription();
        String url = item.getURL();
        String shareURL = item.getShareURL();
        String brand = item.getBrand();
        String brandID = item.getBrandID();
        Double priceUsd = item.getPriceInCurrency("usd");
        Double priceEur = item.getPriceInCurrency("eur");
        Double priceDkk = item.getPriceInCurrency("dkk");
        Double priceGbp = item.getPriceInCurrency("gbp");

        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues contentItemValues = new ContentValues();
        contentItemValues.put(ITEM_TABLE_COL_1, id);
        contentItemValues.put(ITEM_TABLE_COL_2, name);
        contentItemValues.put(ITEM_TABLE_COL_3, description);
        contentItemValues.put(ITEM_TABLE_COL_4, url);
        contentItemValues.put(ITEM_TABLE_COL_5, brand);
        contentItemValues.put(ITEM_TABLE_COL_6, wishlistProduct.getCreationDate().toString());
        contentItemValues.put(ITEM_TABLE_COL_7, priceUsd);
        contentItemValues.put(ITEM_TABLE_COL_8, priceEur);
        contentItemValues.put(ITEM_TABLE_COL_9, priceDkk);
        contentItemValues.put(ITEM_TABLE_COL_10, priceGbp);
        contentItemValues.put(ITEM_TABLE_COL_15, shareURL);
        contentItemValues.put(ITEM_TABLE_COL_16, brandID);


        if(item.getOriginalPrice() != null) {
            Double originalPriceUsd = item.getOriginalPriceInCurrency("usd");
            Double originalPriceEur = item.getOriginalPriceInCurrency("eur");
            Double originalPriceDkk = item.getOriginalPriceInCurrency("dkk");
            Double originalPriceGbp = item.getOriginalPriceInCurrency("gbp");

            contentItemValues.put(ITEM_TABLE_COL_11, originalPriceUsd);
            contentItemValues.put(ITEM_TABLE_COL_12, originalPriceEur);
            contentItemValues.put(ITEM_TABLE_COL_13, originalPriceDkk);
            contentItemValues.put(ITEM_TABLE_COL_14, originalPriceGbp);
        }

        long resultItem = db.update(ITEM_TABLE_NAME, contentItemValues, "ID='" + id + "'", null);
        if (resultItem < 0) {
            return;
        }

        db.close();
    }

    private List<String> getItemImages(String id) {
        SQLiteDatabase db = this.getWritableDatabase();
        String sql = "select * from " + IMAGE_TABLE_NAME + " where item_id = '" + id + "'";
        Cursor res = db.rawQuery(sql, null);

        List<String> image_urls = new ArrayList<>();
        while (res.moveToNext()) {
            String image_url = res.getString(2);
            image_urls.add(image_url);
        }
        db.close();
        res.close();

        return image_urls;
    }

    private List<String> getItemCategories(String id) {
        SQLiteDatabase db = this.getWritableDatabase();
        String sql = "select * from " + CATEGORY_TABLE_NAME + " where item_id = '" + id + "'";
        Cursor res = db.rawQuery(sql, null);

        List<String> categories = new ArrayList<>();
        while (res.moveToNext()) {
            String category = res.getString(2);
            categories.add(category);
        }
        db.close();
        res.close();

        return categories;
    }

    private List<Store> getItemStores(String id) {
        SQLiteDatabase db = this.getWritableDatabase();
        String sql = "select * from " + STORE_TABLE_NAME + " where item_id = '" + id + "'";
        Cursor res = db.rawQuery(sql, null);
        List<Store> stores = new ArrayList<>();
        while (res.moveToNext()) {
            String country = res.getString(2);
            String address = res.getString(3);
            String city = res.getString(4);
            String store_name = res.getString(5);
            double lon = Double.valueOf(res.getString(6));
            double lat = Double.valueOf(res.getString(7));
            String postal_code = res.getString(8);
            Store store = new Store(country, address, city, store_name, lon, lat, postal_code);
            stores.add(store);
        }
        res.close();
        db.close();
        return stores;
    }

    public void deleteFromFavorites(String id) {
        SQLiteDatabase db = this.getWritableDatabase();
        db.delete(ITEM_TABLE_NAME, "ID = '" + id + "'", null);
        db.delete(STORE_TABLE_NAME, "ITEM_ID = '" + id + "'", null);
        db.delete(IMAGE_TABLE_NAME, "ITEM_ID = '" + id + "'", null);
        db.close();
    }

    public WishlistProduct getItem(String id) {
        SQLiteDatabase db = this.getWritableDatabase();
        String sql = "select * from " + ITEM_TABLE_NAME + " where id = '" + id + "'";
        Cursor res = db.rawQuery(sql, null);
        WishlistProduct wishlistProduct = null;
        while (res.moveToNext()) {
            String name = res.getString(1);
            String description = res.getString(2);
            String url = res.getString(3);
            String brand = res.getString(4);
            Date creationDate = getDate(res.getString(5));
            List<String> imageURLs = this.getItemImages(id);
            List<Store> stores = this.getItemStores(id);

            Map<String, Double> price = new HashMap<>();
            price.put("usd", res.getDouble(6));
            price.put("eur", res.getDouble(7));
            price.put("dkk", res.getDouble(8));
            price.put("gbp", res.getDouble(9));

            Map<String, Double> originalPrice = new HashMap<>();
            originalPrice.put("usd", res.getDouble(10));
            originalPrice.put("eur", res.getDouble(11));
            originalPrice.put("dkk", res.getDouble(12));
            originalPrice.put("gbp", res.getDouble(13));

            String shareURL = res.getString(14);

            String brandID = res.getString(15);

            List<String> categories = this.getItemCategories(id);

            Product item = new Product(id, description, name, url, shareURL, price, originalPrice, imageURLs, stores, brand, brandID, categories, "");
            wishlistProduct = new WishlistProduct(item, creationDate);
        }
        res.close();
        db.close();
        return wishlistProduct;
    }

    public List<WishlistProduct> getAllItems() {
        SQLiteDatabase db = this.getWritableDatabase();
        String sql = "select * from " + ITEM_TABLE_NAME;
        Cursor res = db.rawQuery(sql, null);
        List<WishlistProduct> items = new ArrayList<>();
        while (res.moveToNext()) {
            String id = res.getString(0);
            String name = res.getString(1);
            String description = res.getString(2);
            String url = res.getString(3);
            String brand = res.getString(4);
            Date creationDate = getDate(res.getString(5));
            List<String> imageURLs = this.getItemImages(id);
            List<Store> stores = this.getItemStores(id);

            Map<String, Double> price = new HashMap<>();
            price.put("usd", res.getDouble(6));
            price.put("eur", res.getDouble(7));
            price.put("dkk", res.getDouble(8));
            price.put("gbp", res.getDouble(9));

            Map<String, Double> originalPrice = new HashMap<>();
            originalPrice.put("usd", res.getDouble(10));
            originalPrice.put("eur", res.getDouble(11));
            originalPrice.put("dkk", res.getDouble(12));
            originalPrice.put("gbp", res.getDouble(13));

            String shareURL = res.getString(14);

            String brandID = res.getString(15);

            List<String> categories = this.getItemCategories(id);

            Product item = new Product(id, description, name, url, shareURL, price, originalPrice, imageURLs, stores, brand, brandID, categories, "");
            items.add(new WishlistProduct(item, creationDate));
        }
        res.close();
        db.close();
        return items;
    }

    private Date getDate(String stringDate) {
        try {
            String[] values = stringDate.split("\\s+");
            String month = values[1];
            String day = values[2];
            String year = values[5];
            String dateValue = month + " " + day + ", " + year;
            DateFormat format = new SimpleDateFormat("MMMM d, yyyy", Locale.ENGLISH);
            return format.parse(dateValue);
        } catch (PatternSyntaxException | ParseException e) {
            e.printStackTrace();
        }
        return null;
    }
}
