from .generic import ShopifySpider


class MarinEtMarineSpider(ShopifySpider):
    name = "Marin et Marine"
    allowed_domains = ["marinetmarine.com"]
    currency = 'EUR'
    max_pages = 10
    translate_to = 'en'
    collection_urls = [
        {'value': 'https://marinetmarine.com/collections/all/products.json', 'gender': ['women', 'men']},
    ]

    def extract_description(self, body_html):
        body = self._extract_description(body_html)
        return body.replace('Click for Size Guidelines', '')

    def filter_product(self, product):
        name = set(product['name'].lower().split())
        if 'poster' in name or 'gift' in name or 'postcard' in name:
            return False
        return True
