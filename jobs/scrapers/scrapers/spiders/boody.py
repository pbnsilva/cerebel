from .generic import ShopifySpider


class Boody(ShopifySpider):
    name = 'Boody'
    max_pages = 5
    currency = 'AUD'
    collection_urls = [
        {'value': 'https://www.boody.com.au/collections/women/products.json', 'gender': ['women']},
        {'value': 'https://www.boody.com.au/collections/men/products.json', 'gender': ['men']},
    ]

    def filter_tags(self, tags):
        return []
