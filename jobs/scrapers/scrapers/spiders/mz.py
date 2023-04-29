from .generic import ShopifySpider


class MZSpider(ShopifySpider):
    name = "MZ"
    allowed_domains = ["mzfairtrade.com"]
    max_pages = 5
    currency = 'USD'
    collection_urls = [
        {'value': 'https://mzfairtrade.com/collections/tote-bags/products.json', 'gender': ['women']},
        {'value': 'https://mzfairtrade.com/collections/fringe-bags/products.json', 'gender': ['women']},
        {'value': 'https://mzfairtrade.com/collections/clutches/products.json', 'gender': ['women']},
        {'value': 'https://mzfairtrade.com/collections/cross-body-purses/products.json', 'gender': ['women']},
        {'value': 'https://mzfairtrade.com/collections/purses/products.json', 'gender': ['women']},
        {'value': 'https://mzfairtrade.com/collections/luggage/products.json', 'gender': ['women', 'men']},
        {'value': 'https://mzfairtrade.com/collections/backpacks/products.json', 'gender': ['women', 'men']},
    ]
