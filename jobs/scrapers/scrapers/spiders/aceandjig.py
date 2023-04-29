from .generic import ShopifySpider


class AceAndJig(ShopifySpider):
    name = 'ace & jig'
    max_pages = 5
    currency = 'USD'
    collection_urls = [
        {'value': 'https://shop.aceandjig.com/collections/womens/products.json', 'gender': ['women']},
        {'value': 'https://shop.aceandjig.com/collections/accessories/products.json', 'gender': ['women']},
    ]
