from .generic import ShopifySpider
from urllib.parse import quote_plus


class ElvisAndKresseSpider(ShopifySpider):
    name = "Elvis & Kresse"
    utm_source = 'WeAreFaer'
    allowed_domains = ["www.elvisandkresse.com"]
    currency = 'GBP'
    max_pages = 5
    collection_urls = [
        {'value': 'https://www.elvisandkresse.com/collections/womens-bags/products.json', 'gender': ['women']},
        {'value': 'https://www.elvisandkresse.com/collections/mens-bags/products.json', 'gender': ['men']},
        {'value': 'https://www.elvisandkresse.com/collections/wallets/products.json', 'gender': ['men']},
        {'value': 'https://www.elvisandkresse.com/collections/belts-1/products.json', 'gender': ['women', 'men']},
        {'value': 'https://www.elvisandkresse.com/collections/travel/products.json', 'gender': ['men', 'women']},
        {'value': 'https://www.elvisandkresse.com/collections/purses/products.json', 'gender': ['women']},
    ]

    def update_product(self, p):
        p['url'] = 'https://click.linksynergy.com/deeplink?id=VTA2/22Mkg4&mid=43256&murl=%s' % quote_plus(p['url'])
