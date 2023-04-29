from .generic import ShopifySpider


class SymbologySpider(ShopifySpider):
    name = "Symbology"
    allowed_domains = ["symbologyclothing.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://symbologyclothing.com/collections/all/products.json', 'gender': ['women']},
    ]

    def filter_product(self, product):
        if 'gift card' in product['name'].lower():
            return False
        return True
