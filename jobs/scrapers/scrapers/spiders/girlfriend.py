from .generic import ShopifySpider


class GirlfriendSpider(ShopifySpider):
    name = "Girlfriend"
    allowed_domains = ["girlfriend.com"]
    currency = 'USD'
    max_pages = 5
    collection_urls = [
        {'value': 'https://www.girlfriend.com/collections/leggings/products.json', 'gender': ['women']},
        {'value': 'https://www.girlfriend.com/collections/bras/products.json', 'gender': ['women']},
        {'value': 'https://www.girlfriend.com/collections/tops/products.json', 'gender': ['women']},
    ]
