from .generic import ShopifySpider


class RakhaSpider(ShopifySpider):
    name = "Rakha"
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {'value': 'https://rakha.co.uk/collections/tops/products.json', 'gender': ['women']},
        {'value': 'https://rakha.co.uk/collections/dresses/products.json', 'gender': ['women']},
        {'value': 'https://rakha.co.uk/collections/skirt-pants/products.json', 'gender': ['women']},
        {'value': 'https://rakha.co.uk/collections/jackets-coats/products.json', 'gender': ['women']},
    ]
