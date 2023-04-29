from .generic import ShopifySpider


class NaadamSpider(ShopifySpider):
    name = 'Naadam'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {'value': 'https://naadam.co/collections/womens/products.json', 'gender': ['women']},
        {'value': 'https://naadam.co/collections/mens/products.json', 'gender': ['men']},
    ]
