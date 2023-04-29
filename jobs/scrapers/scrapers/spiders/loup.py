from .generic import ShopifySpider


class LoupSpider(ShopifySpider):
    name = "Loup"
    allowed_domains = ["louponline.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://louponline.com/collections/all/products.json', 'gender': ['women']},
    ]
