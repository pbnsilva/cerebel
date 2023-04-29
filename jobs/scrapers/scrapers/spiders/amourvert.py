from .generic import ShopifySpider


class AmourVertSpider(ShopifySpider):
    name = "Amour Vert"
    allowed_domains = ["amourvert.com"]
    currency = 'USD'
    max_pages = 35
    collection_urls = [
        {'value': 'https://amourvert.com/collections/all/products.json', 'gender': ['women']},
    ]

    def filter_product(self, product):
        if 'veja' in product['name'].lower().split():
            return False
        return True
