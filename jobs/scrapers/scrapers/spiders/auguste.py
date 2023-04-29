from .generic import ShopifySpider


class August(ShopifySpider):
    name = 'Auguste'
    max_pages = 5
    currency = 'AUD'
    collection_urls = [
        {'value': 'https://augustethelabel.com/collections/clothing-all/products.json', 'gender': ['women']},
    ]

    def filter_product(self, product):
        if 'gift card' in product['name'].lower():
            return False
        return True

    def filter_tags(self, tags):
        return []
