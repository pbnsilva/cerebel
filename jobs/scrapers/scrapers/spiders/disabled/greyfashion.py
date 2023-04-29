from .generic import ShopifySpider


class GreyFashionSpider(ShopifySpider):
    name = "Grey Fashion"
    allowed_domains = ["greyfashion.com"]
    currency = 'EUR'
    max_pages = 2
    translate_to = 'en'
    collection_urls = [
        {'value': 'https://greyfashion.com/collections/all/products.json', 'gender': ['women']},
    ]

    def filter_product(self, product):
        if product['name'].lower() in {'gift card', 'geschenkkarte'}:
            return False
        return True
