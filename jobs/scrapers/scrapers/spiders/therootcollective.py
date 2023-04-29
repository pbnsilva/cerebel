from .generic import ShopifySpider


class TheRootCollectiveSpider(ShopifySpider):
    name = "The Root Collective"
    allowed_domains = ["therootcollective.com"]
    currency = 'USD'
    max_pages = 5
    collection_urls = [
        {"value": "https://therootcollective.com/collections/accessories/products.json", "gender": ["women", "men"]},
        {"value": "https://therootcollective.com/collections/boots/products.json", "gender": ["women"]},
        {"value": "https://therootcollective.com/collections/flats/products.json", "gender": ["women"]},
        {"value": "https://therootcollective.com/collections/wedges/products.json", "gender": ["women"]},
    ]

    def extract_description(self, body_html):
        return self._extract_description(body_html).split('Sizing')[0].strip()
