from .generic import ShopifySpider


class BonSpider(ShopifySpider):
    name = 'Bon'
    currency = 'USD'
    max_pages = 5
    collection_urls = [
        {"value": "https://bonlabel.com.au/collections/all/products.json", "gender": ["women"]},
    ]
