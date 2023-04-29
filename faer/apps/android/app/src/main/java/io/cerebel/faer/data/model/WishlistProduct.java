package io.cerebel.faer.data.model;

import java.util.Date;

public class WishlistProduct {
    private final Date creationDate;
    private Product product;

    public WishlistProduct(Product item, Date creationDate) {
        this.product = item;
        this.creationDate = creationDate;
    }

    public Date getCreationDate() {
        return creationDate;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
    }
}
