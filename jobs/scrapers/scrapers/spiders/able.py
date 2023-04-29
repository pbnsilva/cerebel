from .generic import ShopifySpider


class AbleSpider(ShopifySpider):
    name = 'Able'
    max_pages = 15
    currency = 'EUR'
    collection_urls = [
        {'value': 'https://www.livefashionable.com/collections/all/products.json', 'gender': ['women']},
    ]

    def filter_tags(self, tags):
        return list(filter(lambda t: not t.startswith('pairs with'), tags))
