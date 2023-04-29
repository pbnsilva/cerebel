import re
from .generic import ShopifySpider


class BibicoSpider(ShopifySpider):
    name = "Bibico"
    allowed_domains = ["www.bibico.co.uk"]
    currency = 'GBP'
    max_pages = 5
    collection_urls = [
        {'value': 'https://www.bibico.co.uk/collections/dresses/products.json', 'gender': ['women']},
        {'value': 'https://www.bibico.co.uk/collections/tops/products.json', 'gender': ['women']},
        {'value':  'https://www.bibico.co.uk/collections/skirts/products.json', 'gender': ['women']},
        {'value': 'https://www.bibico.co.uk/collections/knitwear/products.json', 'gender': ['women']},
        {'value': 'https://www.bibico.co.uk/collections/shoes/products.json', 'gender': ['women']},
    ]

    def extract_description(self, body):
        text = re.search(r'Description(.*?)</p>', body, re.DOTALL).group(1)
        return self._remove_html_tags(text)

    def extract_description_html(self, body_html):
        text = re.search(r'Description(.*?)</p>', body_html, re.DOTALL).group(1)
        return self._remove_html_tags(text)

    def _remove_html_tags(self, data):
        p = re.compile(r'<.*?>')
        return p.sub('', data)
