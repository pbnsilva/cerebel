from .generic import ShopifySpider


class DaniellefosterSpider(ShopifySpider):
    name = 'Danielle Foster'
    collection_urls = [{"value": "https://shop.daniellefoster.co.uk/collections/shop-collection/products.json", "gender": ["women"]}]
    currency = 'GBP'
    max_pages = 5
