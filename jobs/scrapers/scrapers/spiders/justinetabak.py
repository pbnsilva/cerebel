from .generic import ShopifySpider


class JustineTabakSpider(ShopifySpider):
    name = "Justine Tabak"
    allowed_domains = ["www.justinetabak.co.uk"]
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {'value': 'https://www.justinetabak.co.uk/collections/all/products.json', 'gender': ['women']},
    ]

    def filter_tags(self, tags):
        return [t for t in tags if t != 'Vintage']
