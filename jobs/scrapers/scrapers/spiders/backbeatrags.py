from urllib.parse import quote
from .generic import ShopifySpider


class BackBeatRags(ShopifySpider):
    name = 'Back Beat Rags'
    max_pages = 5
    currency = 'USD'
    collection_urls = [
        {'value': 'https://backbeatrags.com/collections/all/products.json', 'gender': ['women']},
    ]

    def update_product(self, p):
        p['url'] = 'http://www.pjtra.com/t/TUJGRk5LSEJGTUxFSEhCRkxHRUpJ?url='+quote(p['url'])
