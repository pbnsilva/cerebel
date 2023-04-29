import re
from .generic import ShopifySpider
from urllib.parse import quote_plus


class OrganicBasicsSpider(ShopifySpider):
    name = "Organic Basics"
    allowed_domains = ["organicbasics.com"]
    max_pages = 5
    currency = 'DKK'
    collection_urls = [
        {'value': 'https://organicbasics.com/collections/organic-cotton-mens/products.json', 'gender': ['men']},
        {'value': 'https://organicbasics.com/collections/silvertech-mens/products.json', 'gender': ['men']},
        {'value': 'https://organicbasics.com/collections/silvertech-active-mens/products.json', 'gender': ['men']},
        {'value': 'https://organicbasics.com/collections/silvertech-active-womens/products.json', 'gender': ['women']},
        {'value': 'https://organicbasics.com/collections/organic-cotton-womens/products.json', 'gender': ['women']},
        {'value': 'https://organicbasics.com/collections/silvertech-womens/products.json', 'gender': ['women']},
        {'value': 'https://organicbasics.com/collections/invisible/products.json', 'gender': ['women']},
    ]

    def update_product(self, p):
        p['url'] = 'https://click.linksynergy.com/deeplink?id=VTA2/22Mkg4&mid=43646&murl=%s' % quote_plus(p['url'])
        p['description'] = 'Get 15% off with the coupon code RTXOBCO15 .\n\n' + p['description']

    def extract_description(self, body_html):
        text = re.search(r'Product(.*?)Fabric', body_html, re.DOTALL).group(1)
        return self._remove_html_tags(text).replace('\\n', '\n').strip()

    def _remove_html_tags(self, data):
        p = re.compile(r'<.*?>')
        return p.sub('', data)
