from .generic import ShopifySpider


class SolosocksSpider(ShopifySpider):
    name = "Solosocks"
    allowed_domains = ["solosocks.info"]
    currency = 'EUR'
    max_pages = 5
    collection_urls = [
        {'value': 'https://solosocks.co/collections/all/products.json', 'gender': ['men', 'women']},
    ]

    def filter_tags(self, tags):
        return list(filter(lambda t: t not in {'loafer', 'dress'}, tags))
