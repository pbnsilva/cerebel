import re
from .generic import ShopifySpider


class AngelaRoiSpider(ShopifySpider):
    name = "Angela Roi"
    allowed_domains = ["angelaroi.com"]
    currency = 'USD'
    max_pages = 5
    collection_urls = [
        {'value': 'https://www.angelaroi.com/collections/all/products.json', 'gender': ['women']},
    ]

    def extract_description(self, body_html):
        text = re.search(r'Manufacturing(.*?)</p>', body_html, re.DOTALL).group(1)
        return self._remove_html_tags(text).replace('\\n', '\n').strip()

    def _remove_html_tags(self, data):
        p = re.compile(r'<.*?>')
        return p.sub('', data)
