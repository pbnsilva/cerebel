from .generic import ShopifySpider


class SiizuSpider(ShopifySpider):
    name = "SiiZU"
    allowed_domains = ["siizu.com"]
    max_pages = 10
    currency = 'GBP'
    collection_urls = [
        {'value': 'https://siizu.com/collections/all/products.json', 'gender': ['women']},
    ]
