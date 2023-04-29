from .generic import ShopifySpider


class BandaBagsSpider(ShopifySpider):
    name = "Banda Bags"
    allowed_domains = ["bandabags.com"]
    currency = 'USD'
    max_pages = 5
    collection_urls = [
        {'value': 'https://bandabags.com/collections/all/products.json', 'gender': ['men', 'women']},
    ]

    def filter_product(self, product):
        if product['name'] == 'Gift Card':
            return False
        return True
