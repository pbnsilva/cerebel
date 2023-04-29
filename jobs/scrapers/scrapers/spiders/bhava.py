from .generic import ShopifySpider


class BhavaSpider(ShopifySpider):
    name = "Bhava"
    allowed_domains = ["bhavastudio.com"]
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {'value': 'https://bhavastudio.com/collections/all/products.json', 'gender': ['women']},
    ]
