from .generic import ShopifySpider


class LangerChenSpider(ShopifySpider):
    name = "LangerChen"
    allowed_domains = ["langerchen.com"]
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {'value': 'https://langerchen.com/collections/women-fa18/products.json', 'gender': ['women']},
        {'value': 'https://langerchen.com/collections/men-fa18/products.json', 'gender': ['men']},
    ]
