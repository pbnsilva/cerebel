from .generic import ShopifySpider


class AgaatiSpider(ShopifySpider):
    name = "Agaati"
    allowed_domains = ["agaati.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://agaati.com/collections/all/products.json', 'gender': ['women']},
    ]

    def extract_description(self, body_html):
        return self._extract_description(body_html).replace('Click for Size Guidelines', '')
